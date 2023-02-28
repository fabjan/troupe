# troupe

A Gleam project kicking the OTP tires.

[troupe.gleam](src/troupe.gleam) is just a command line running the code in:
* [example_tasks.gleam](src/troupe/example_tasks.gleam)
* [example_actor.gleam](src/troupe/example_actor.gleam)

## Background

I know OTP and Erlang, but translating that knowledge to the typed world of
Gleam took some grokking.

This repository can be viewed as a complement to this blog post I read and
also recommend you read for explanations that are more fleshed out:
https://code-change.nl/gleam-blog/20230225-gleam-otp.html

I also perused the [gleam_otp docs] and followed its list under "How to
understand the Gleam OTP library".

`troupe` is my distillation of the above, to verify my understanding.

[gleam_otp docs]: https://hexdocs.pm/gleam_otp/

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
