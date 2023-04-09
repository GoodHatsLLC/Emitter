import Disposable

// MARK: - AnyEmitter

public struct AnyEmitter<Value, Failure: Error>: Emitter {

  fileprivate init(_ emitter: some Emitter<Value, Failure>) {
    self.subscribeFunc = { emitter.subscribe($0) }
  }

  private let subscribeFunc: @Sendable (any Subscriber<Value, Failure>)
    -> AutoDisposable

  public func subscribe<S: Subscriber>(
    _ subscriber: S
  )
    -> AutoDisposable where S.Value == Value, S.Failure == Failure
  {
    subscribeFunc(subscriber)
  }
}

extension AnyEmitter {
  public func erase() -> AnyEmitter<Value, Failure> { self }
}

extension Emitter {
  public func erase() -> AnyEmitter<Value, Failure> {
    AnyEmitter(self)
  }

  public func any() -> any Emitter<Value, Failure> { self }
}
