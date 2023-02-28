import gleam/erlang
import gleam/erlang/process.{Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/map
import gleam/otp/actor
import gleam/result
import outil.{command, print_usage_and_exit}
import outil/opt
import troupe/example_actor
import troupe/example_tasks

pub fn main() {
  let args = erlang.start_arguments()

  main_cmd(args)
  |> result.map_error(print_usage_and_exit)
}

fn main_cmd(argv: List(String)) {
  use cmd <- command("troupe", "A program using OTP", argv)
  use duration, cmd <- opt.int(cmd, "duration", "Seconds to run each test", 1)
  use skip_task, cmd <- opt.bool(cmd, "no-task", "Skip task tests")
  use skip_actor, cmd <- opt.bool(cmd, "no-actor", "Skip actor tests")

  try duration = duration(cmd)
  try skip_task = skip_task(cmd)
  try skip_actor = skip_actor(cmd)

  case skip_task {
    False -> run_tasks(duration)
    True -> Nil
  }

  case skip_actor {
    False -> run_actors(duration)
    True -> Nil
  }

  Ok(Nil)
}

fn bench(what: String, f: fn() -> a, time_left_us: Int, iterations: Int) -> Int {
  case 0 <= time_left_us {
    True -> {
      let start = erlang.system_time(erlang.Microsecond)
      let _ = f()
      let end = erlang.system_time(erlang.Microsecond)
      let elapsed = end - start
      bench(what, f, time_left_us - elapsed, iterations + 1)
    }
    False -> iterations
  }
}

fn run_tasks(duration_s: Int) -> Nil {
  let filenames = example_files()
  let file_count = list.length(filenames)

  // convert to microseconds for bench helper
  let bench_time = duration_s * 1_000_000

  io.print(
    "Counting words in " <> int.to_string(file_count) <> " files sequentially...",
  )
  let seq_counts =
    example_tasks.count_words_in_files(example_tasks.Sequential, filenames)
  let seq_iters =
    bench(
      "Sequential",
      fn() {
        example_tasks.count_words_in_files(example_tasks.Sequential, filenames)
      },
      bench_time,
      0,
    )
  io.println("Done!")

  io.print(
    "Counting words in " <> int.to_string(file_count) <> " files concurrently...",
  )
  let conc_counts =
    example_tasks.count_words_in_files(example_tasks.Concurrent, filenames)
  let conc_iters =
    bench(
      "Concurrent",
      fn() {
        example_tasks.count_words_in_files(example_tasks.Concurrent, filenames)
      },
      bench_time,
      0,
    )
  io.println("Done!")

  let keys = map.keys(conc_counts)

  let mismatched =
    keys
    |> list.filter_map(fn(key) {
      let seq = result.unwrap(map.get(seq_counts, key), -1)
      let conc = result.unwrap(map.get(conc_counts, key), -1)
      case seq == conc {
        True -> Error(Nil)
        False -> Ok(#(key, seq, conc))
      }
    })

  let total_word_count =
    map.values(conc_counts)
    |> int.sum()

  io.println(
    "Total word count: " <> int.to_string(total_word_count) <> " words",
  )

  case mismatched {
    [] -> io.println("All counts match!")
    _ -> {
      io.println("Mismatched counts:")
      mismatched
      |> list.each(fn(diff) {
        let #(key, seq, conc) = diff
        io.println(
          key <> " differs: " <> int.to_string(seq) <> " =/= " <> int.to_string(
            conc,
          ),
        )
      })
    }
  }

  io.println(
    "Sequential: " <> int.to_string(seq_iters) <> " iterations in " <> int.to_string(
      bench_time / 1_000_000,
    ) <> " seconds",
  )
  io.println(
    "Concurrent: " <> int.to_string(conc_iters) <> " iterations in " <> int.to_string(
      bench_time / 1_000_000,
    ) <> " seconds",
  )
}

pub fn run_actors(duration_s: Int) -> Nil {
  assert Ok(meter) = example_actor.new_meter()

  let bench_time = duration_s * 1_000_000

  io.print("Running actor benchmarks...")
  let actor_iters = bench("Actor", fn() { poke_actor(meter) }, bench_time, 0)
  io.println("Done!")

  let counts =
    actor.call(meter, fn(reply) { example_actor.ReadAll(reply) }, 5000)

  counts
  |> map.values()
  |> list.each(fn(instrument) {
    case instrument {
      example_actor.Counter(name, value) ->
        io.println("counter " <> name <> ": " <> int.to_string(value))
      example_actor.Gauge(name, value) ->
        io.println("gauge " <> name <> ": " <> int.to_string(value))
    }
  })

  io.println(
    "Actor: " <> int.to_string(actor_iters) <> " iterations in " <> int.to_string(
      bench_time / 1_000_000,
    ) <> " seconds",
  )
}

fn poke_actor(meter: Subject(example_actor.MeterRequest)) {
  let instrument = pick_name()
  let number = int.random(1, 100)
  case int.random(0, 10) {
    0 -> actor.send(meter, example_actor.GaugeSet(instrument, number))
    _ -> actor.send(meter, example_actor.CounterAdd(instrument, number))
  }
}

fn pick_name() -> String {
  let alternatives = ["foo", "bar", "baz", "qux"]
  let index = int.random(0, list.length(alternatives))
  assert Ok(name) = list.at(alternatives, index)
  name
}

pub fn example_files() -> List(String) {
  [
    "test/troupe_test.gleam",
    "build/packages/gleeunit/src/gleeunit/should.gleam",
    "build/packages/gleeunit/src/gleeunit.gleam",
    "build/packages/outil/src/outil.gleam",
    "build/packages/outil/src/outil/arg.gleam",
    "build/packages/outil/src/outil/error.gleam",
    "build/packages/outil/src/outil/help.gleam",
    "build/packages/outil/src/outil/opt.gleam",
    "build/packages/gleam_stdlib/src/gleam",
    "build/packages/gleam_stdlib/src/gleam/bit_string.gleam",
    "build/packages/gleam_stdlib/src/gleam/list.gleam",
    "build/packages/gleam_stdlib/src/gleam/io.gleam",
    "build/packages/gleam_stdlib/src/gleam/int.gleam",
    "build/packages/gleam_stdlib/src/gleam/queue.gleam",
    "build/packages/gleam_stdlib/src/gleam/bit_builder.gleam",
    "build/packages/gleam_stdlib/src/gleam/string.gleam",
    "build/packages/gleam_stdlib/src/gleam/base.gleam",
    "build/packages/gleam_stdlib/src/gleam/regex.gleam",
    "build/packages/gleam_stdlib/src/gleam/string_builder.gleam",
    "build/packages/gleam_stdlib/src/gleam/function.gleam",
    "build/packages/gleam_stdlib/src/gleam/bool.gleam",
    "build/packages/gleam_stdlib/src/gleam/map.gleam",
    "build/packages/gleam_stdlib/src/gleam/uri.gleam",
    "build/packages/gleam_stdlib/src/gleam/float.gleam",
    "build/packages/gleam_stdlib/src/gleam/set.gleam",
    "build/packages/gleam_stdlib/src/gleam/iterator.gleam",
    "build/packages/gleam_stdlib/src/gleam/option.gleam",
    "build/packages/gleam_stdlib/src/gleam/pair.gleam",
    "build/packages/gleam_stdlib/src/gleam/result.gleam",
    "build/packages/gleam_stdlib/src/gleam/order.gleam",
    "build/packages/gleam_stdlib/src/gleam/dynamic.gleam",
    "build/packages/gleam_otp/src/gleam",
    "build/packages/gleam_otp/src/gleam/otp/system.gleam",
    "build/packages/gleam_otp/src/gleam/otp/intensity_tracker.gleam",
    "build/packages/gleam_otp/src/gleam/otp/task.gleam",
    "build/packages/gleam_otp/src/gleam/otp/actor.gleam",
    "build/packages/gleam_otp/src/gleam/otp/node.gleam",
    "build/packages/gleam_otp/src/gleam/otp/supervisor.gleam",
    "build/packages/gleam_otp/src/gleam/otp/port.gleam",
    "build/packages/gleam_erlang/src/gleam",
    "build/packages/gleam_erlang/src/gleam/erlang.gleam",
    "build/packages/gleam_erlang/src/gleam/erlang/file.gleam",
    "build/packages/gleam_erlang/src/gleam/erlang/atom.gleam",
    "build/packages/gleam_erlang/src/gleam/erlang/os.gleam",
    "build/packages/gleam_erlang/src/gleam/erlang/process.gleam",
    "build/packages/gleam_erlang/src/gleam/erlang/charlist.gleam",
    "src/troupe.gleam", "src/troupe/example_actor.gleam",
    "src/troupe/example_tasks.gleam",
  ]
}
