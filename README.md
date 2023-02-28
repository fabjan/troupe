# troupe

A Gleam project kicking the OTP tires.

## Quick start

```sh
gleam run   # Run the project (actually just tests)
gleam test  # Run the tests (nonexistant)
gleam shell # Run an Erlang shell (not much use)
```

## Building

```sh
gleam export erlang-shipment
```

## Running

The program is hard coded to read the files in this repository, so you can't
really move it anywhere...

```
build/erlang-shipment/entrypoint.sh run --help
troupe -- A program using OTP

Usage: troupe

Options:
  --duration  Seconds to run each test (int, default: 1)
  --no-task  Skip task tests (bool, default: false)
  --no-actor  Skip actor tests (bool, default: false)
  -h, --help  Show this help text and exit.
````

```sh
build/erlang-shipment/entrypoint.sh run
Counting words in 45 files sequentially...Done!
Counting words in 45 files concurrently...Done!
Total word count: 14725 words
All counts match!
Sequential: 13 iterations in 1 seconds
Concurrent: 17 iterations in 1 seconds
Running actor benchmarks...Done!
counter bar: 1948
gauge baz: 10
counter foo: 373
counter qux: 501
Actor: 467894 iterations in 1 seconds
```
