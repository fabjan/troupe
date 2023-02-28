// An `Actor` is a process that provides a message based API. The process sits in
// an "infinite" loop, waiting for messages to arrive. When a message arrives, the
// `loop` handler function is called with the message and the current state. The
// handler function returns a `Stop` value to stop the actor, or a `Continue`
// value with an updated state to continue execution and wait for more messages.
//
// Each actor has a message type describing what can be sent to it. If you want to
// be able to receive responses, the requests will have to contain a response
// `Subject`, see below.

import gleam/erlang/process.{Subject}
import gleam/map.{Map}
import gleam/otp/actor.{Continue, Next, StartError}

pub type Instrument {
  Gauge(String, Int)
  Counter(String, Int)
}

/// You can name the type whatever you want, but here I use "Request" to
/// hint at how actors are used.
pub type MeterRequest {
  CounterAdd(String, Int)
  GaugeSet(String, Int)
  ReadAll(Subject(Map(String, Instrument)))
}

pub fn new_meter() -> Result(Subject(MeterRequest), StartError) {
  actor.start(map.new(), meter_loop)
}

type MeterState =
  Map(String, Instrument)

/// This is the main loop of this example actor.
fn meter_loop(msg: MeterRequest, state: MeterState) -> Next(MeterState) {
  case msg {
    CounterAdd(name, value) -> increment_counter(name, value, state)
    GaugeSet(name, value) -> set_gauge(name, value, state)
    ReadAll(reply) -> {
      actor.send(reply, state)
      Continue(state)
    }
  }
}

fn increment_counter(
  name: String,
  incr: Int,
  state: MeterState,
) -> Next(MeterState) {
  case map.get(state, name) {
    Ok(Counter(_, current)) ->
      Continue(map.insert(state, name, Counter(name, current + incr)))
    // replace any gauge of the same name, for simplicity of this example
    _ -> Continue(map.insert(state, name, Counter(name, incr)))
  }
}

fn set_gauge(name: String, value: Int, state: MeterState) -> Next(MeterState) {
  Continue(map.insert(state, name, Gauge(name, value)))
}
