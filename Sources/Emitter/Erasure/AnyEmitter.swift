import Disposable

// MARK: - AnyEmitter

public struct AnyEmitter<Output: Sendable>: Emitter {

  fileprivate init(_ emitter: some Emitter<Output>) {
    self.subscribeFunc = { emitter.subscribe($0) }
  }

  private let subscribeFunc: @Sendable (any Subscriber<Output>)
    -> AutoDisposable

  public func subscribe<S: Subscriber>(
    _ subscriber: S
  )
    -> AutoDisposable where S.Value == Output
  {
    subscribeFunc(subscriber)
  }
}

extension AnyEmitter {
  public func erase() -> AnyEmitter<Output> { self }
}

extension Emitter {
  public func erase() -> AnyEmitter<Output> {
    AnyEmitter(self)
  }

  public func any() -> any Emitter<Output> { self }
}
