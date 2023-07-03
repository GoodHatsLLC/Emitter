# Emitter 🔴-🟢-🔵

`Emitter` is a simple implementation of [Reactive Streams](http://www.reactive-streams.org/) like [RxSwift](https://github.com/ReactiveX/RxSwift) or Combine.  
It is used internally in [StateTree](https://github.com/GoodHatsLLC/StateTree), a state management framework.

## Features:
* `Emitter` is platform independent and non-proprietary.
* It is thread-safe.
* It has a smaller footprint than [OpenCombine](https://github.com/OpenCombine/OpenCombine) and [RxSwift](https://github.com/ReactiveX/RxSwift) and might be a useful learning resource.

## Limitations

`Emitter` is primarily developed as an internal library for StateTree.
* Like `RxSwift` but unlike `Combine` it has no support for back pressure management.
* It has a limited number of [implemented operators](https://github.com/GoodHatsLLC/Emitter/tree/main/Sources/Emitter/Operators).
