import Disposable

// MARK: - AnyEmitter

public struct AnyEmitter<Output, Failure: Error>: Emitter {

  fileprivate init(_ emitter: some Emitter<Output, Failure>) {
    self.subscribeFunc = { emitter.subscribe($0) }
  }

  private let subscribeFunc: @Sendable (any Subscriber<Output, Failure>)
    -> AutoDisposable

  public func subscribe<S: Subscriber>(
    _ subscriber: S
  )
    -> AutoDisposable where S.Input == Output, S.Failure == Failure
  {
    subscribeFunc(subscriber)
  }
}

extension AnyEmitter {
  public func erase() -> AnyEmitter<Output, Failure> { self }
}

extension Emitter {
  public func erase() -> AnyEmitter<Output, Failure> {
    AnyEmitter(self)
  }

  public func any() -> any Emitter<Output, Failure> { self }
  public func some() -> some Emitter<Output, Failure> { self }
}
