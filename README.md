# Emitter ♻️

`Emitter` is a basic implementation of [Reactive Streams](http://www.reactive-streams.org/) in the style of [RxSwift](https://github.com/ReactiveX/RxSwift) or Combine.  
It is used internally in the [https://github.com/GoodHatsLLC/StateTree](StateTree) framework.

## Features:
* `Emitter` is platform independent and non-proprietary.
* It is thread-safe.
* It is annotated for use in codebases using Swift Concurrency.
* It has a smaller footprint than [OpenCombine](https://github.com/OpenCombine/OpenCombine) and [RxSwift](https://github.com/ReactiveX/RxSwift) and might be a useful learning resource.

## Limitations

`Emitter` is intended to be simple. It has some limitations:
* It's in beta and not nearly as well tested as any of the various alternatives.
* Like `RxSwift` but `unlike` Combine it has no support for back pressure management or typed errors.
* It has a limited number of [implemented operators](https://github.com/GoodHatsLLC/Emitter/tree/main/Sources/Emitter/Operators).
* It does not perform as well as [Combine](https://github.com/GoodHatsLLC/Emitter/blob/main/Tests/EmitterTests/Benchmarks/Benchmarks.swift).

## Operator performance

![Emitter operator performance](https://github.com/GoodHatsLLC/Emitter/blob/main/Benchmarks/chart.png?raw=true)
