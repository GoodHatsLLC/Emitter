# Emitter 🔴-🟢-🔵

`Emitter` is a simple implementation of [Reactive Streams](http://www.reactive-streams.org/) like [RxSwift](https://github.com/ReactiveX/RxSwift) or Combine.  
It is used internally in the [StateTree architecture](https://github.com/GoodHatsLLC/StateTree) framework.

## Features:
* `Emitter` is platform independent and non-proprietary.
* It is thread-safe.
* It is annotated for use in codebases using Swift Concurrency.
* It has a smaller footprint than [OpenCombine](https://github.com/OpenCombine/OpenCombine) and [RxSwift](https://github.com/ReactiveX/RxSwift) and might be a useful learning resource.

## Limitations

`Emitter` is intended to be simple. It has some limitations:
* It's in beta and neith as well tested or as performant as any of the various alternatives.
* Like `RxSwift` but unlike `Combine` it has no support for back pressure management or typed errors.
* It has a limited number of [implemented operators](https://github.com/GoodHatsLLC/Emitter/tree/main/Sources/Emitter/Operators).

## Operator performance

![Emitter operator performance](https://github.com/GoodHatsLLC/Emitter/blob/main/Benchmarks/chart.png?raw=true)
