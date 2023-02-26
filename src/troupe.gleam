import gleam/erlang
import gleam/int
import gleam/io
import gleam/list
import gleam/map
import gleam/result
import outil.{CommandError, command, print_usage_and_exit}
import outil/opt
import troupe/task

pub fn main() {
  let args = erlang.start_arguments()

  main_cmd(args)
  |> result.map_error(print_usage_and_exit)
}

fn main_cmd(argv: List(String)) {
  use cmd <- command("troupe", "A program using OTP", argv)
  use task, cmd <- opt.bool(cmd, "task", "Run task tests")

  try task = task(cmd)

  case task {
    True -> Ok(run_tasks())
    False -> Error(CommandError("no options given"))
  }
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

fn run_tasks() -> Nil {
  let filenames = example_files()
  let file_count = list.length(filenames)

  let bench_time = 2_000_000

  io.print(
    "Counting words in " <> int.to_string(file_count) <> " files sequentially...",
  )
  let seq_counts = task.count_words_in_files(task.Sequential, filenames)
  let seq_iters =
    bench(
      "Sequential",
      fn() { task.count_words_in_files(task.Sequential, filenames) },
      bench_time,
      0,
    )
  io.println("Done!")

  io.print(
    "Counting words in " <> int.to_string(file_count) <> " files concurrently...",
  )
  let conc_counts = task.count_words_in_files(task.Concurrent, filenames)
  let conc_iters =
    bench(
      "Concurrent",
      fn() { task.count_words_in_files(task.Concurrent, filenames) },
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

pub fn example_files() -> List(String) {
  [
    "test/troupe_test.gleam",
    "build/packages/gleeunit/src/gleeunit/should.gleam",
    "build/packages/gleeunit/src/gleeunit.gleam",
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
    "src/troupe.gleam", "src/troupe/task.gleam", "src/troupe/actor.gleam",
    "src/troupe/supervisor.gleam",
  ]
}
