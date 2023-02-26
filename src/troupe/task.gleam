import gleam/erlang/file
import gleam/function
import gleam/list
import gleam/map.{Map}
import gleam/otp/task
import gleam/result
import gleam/string

// From gleam_stdlib docs:
//
// A `Task` is an asynchronous computation.
// Other languages may call these "futures" or "promises".
// In Gleam OTP, they were inspired by Elixir's `Task` module.
//
// There are two important things to consider when using async:
//
// * If you are using async tasks, you must await a reply as they are always sent.
//
// * async tasks link the caller and the spawned process. This means that, if the
// caller crashes, the task will crash too and vice-versa. This is on purpose: if
// the process meant to receive the result no longer exists, there is no purpose
// in completing the computation.

/// concurrent_map runs the given function on each element of the list in parallel.
/// This is rather naive, given that it will spawn a task for each element.
pub fn concurrent_map(l: List(a), f: fn(a) -> b) -> List(b) {
  l
  |> list.map(fn(x) { task.async(fn() { f(x) }) })
  |> list.map(task.await(_, 5000))
}

/// count_words returns a map of words to their count in the given text.
pub fn count_words(text: String) -> Map(String, Int) {
  string.split(text, " ")
  |> list.fold(
    map.new(),
    fn(counts, word) {
      map.get(counts, word)
      |> result.unwrap(0)
      |> fn(count) { count + 1 }
      |> map.insert(counts, word, _)
    },
  )
}

/// count_words_in_file returns a map of words to their count in the given file.
pub fn count_words_in_file(
  filename: String,
) -> Result(Map(String, Int), file.Reason) {
  filename
  |> file.read()
  |> result.map(count_words)
}

pub type Strategy {
  Sequential
  Concurrent
}

/// count_words_in_files returns a map of words to their count in the given files.
pub fn count_words_in_files(
  strategy: Strategy,
  filenames: List(String),
) -> Map(String, Int) {
  let mapper = case strategy {
    Sequential -> list.map
    Concurrent -> concurrent_map
  }

  let results =
    filenames
    |> mapper(count_words_in_file)

  results
  |> list.filter_map(function.identity)
  |> list.fold(map.new(), map.merge)
}
