import gleam/erlang/file
import gleam/function
import gleam/list
import gleam/map.{Map}
import gleam/otp/task
import gleam/result
import gleam/string

// A `Task` is an asynchronous computation, other languages may call these
// "futures" or "promises". In Gleam OTP, the implementation was inspired by
// Elixir's `Task` module.
//
// You give them a computation to calculate and they will run it in a separate
// process. When you want the result, you can `await` it in the process that
// created the task. In fact, you must await it eventually.

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
