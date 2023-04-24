import Disposable

extension Emitters {
  public static var never: NeverEmitter {
    .init()
  }
}

// MARK: - NeverEmitter

public struct NeverEmitter: Emitter {
  public func subscribe<S>(_ subscriber: S) -> AutoDisposable where S: Subscriber,
    Failure == S.Failure, () == S.Input
  {
    subscriber.receive(emission: .finished)
    return AutoDisposable { }
  }

  public typealias Output = ()
  public typealias Failure = Error

}
