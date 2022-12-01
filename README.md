# Emitter

`Emitter` is a basic implementation of [Reactive Streams](http://www.reactive-streams.org/) in the style of [RxSwift](https://github.com/ReactiveX/RxSwift) or Combine.

It's intended as a learning resource. Its smaller footprint and simplicity might make it easier to follow than [OpenCombine](https://github.com/OpenCombine/OpenCombine) — and definitely make it easier to follow than [RxSwift](https://github.com/ReactiveX/RxSwift).

## Limitations

`Emitter`'s only focus is on simplicity of implementation. It has clear limitations:
* Like `RxSwift` but `unlike` Combine it has no support for back pressure management or typed errors.
* It is fully `@MainThread` bound.
* It has a limited number of [implemented operators](https://github.com/GoodHatsLLC/Emitter/tree/main/Sources/Emitter/Operators).
* The operators' speeds are [not quite competitive with Combine's](https://github.com/GoodHatsLLC/Emitter/blob/main/Tests/EmitterTests/Benchmarks/Benchmarks.swift).

## Operator performance

![Emitter operator performance](https://github.com/GoodHatsLLC/Emitter/blob/main/Benchmarks/chart.png?raw=true)
