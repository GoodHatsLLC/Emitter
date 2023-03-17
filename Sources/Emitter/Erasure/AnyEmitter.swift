import Disposable

// MARK: - AnyEmitter

public struct AnyEmitter<Output: Sendable>: Emitting {

  fileprivate init(_ emitter: some Emitting<Output>) {
    self.subscribeFunc = { emitter.subscribe($0) }
  }

  private let subscribeFunc: @Sendable (any Subscriber<Output>)
    -> AnyDisposable

  public func subscribe<S: Subscriber>(
    _ subscriber: S
  )
    -> AnyDisposable where S.Value == Output
  {
    subscribeFunc(subscriber)
  }
}

extension AnyEmitter {
  public func erase() -> AnyEmitter<Output> { self }
}

extension Emitting {
  public func erase() -> AnyEmitter<Output> {
    AnyEmitter(self)
  }

  public func any() -> any Emitting<Output> { self }
}
