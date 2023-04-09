# Emitter 🔴-🟢-🔵

`Emitter` is a simple implementation of [Reactive Streams](http://www.reactive-streams.org/) like [RxSwift](https://github.com/ReactiveX/RxSwift) or Combine.  
It is used internally in the [StateTree architecture](https://github.com/GoodHatsLLC/StateTree) framework.

## Features:
* `Emitter` is platform independent and non-proprietary.
* It is thread-safe.
* It is annotated for use in codebases using Swift Concurrency.
* It has a smaller footprint than [OpenCombine](https://github.com/OpenCombine/OpenCombine) and [RxSwift](https://github.com/ReactiveX/RxSwift) and might be a useful learning resource.

## Limitations

`Emitter` is primarily dveloped as an internal library for StateTree.
* It is neither as well tested nor as performant as the various alternatives.
* Like `RxSwift` but unlike `Combine` it has no support for back pressure management.
* It has a limited number of [implemented operators](https://github.com/GoodHatsLLC/Emitter/tree/main/Sources/Emitter/Operators).
* It is pre-v1 and its API will continue to change.