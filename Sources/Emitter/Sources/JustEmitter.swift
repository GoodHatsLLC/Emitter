import Disposable

extension Emitters {
  public static func just<T>(_ value: T) -> JustEmitter<T> {
    .init(value)
  }
}

// MARK: - JustEmitter

public struct JustEmitter<T>: Emitter {
  public func subscribe<S>(_ subscriber: S) -> AutoDisposable where S: Subscriber,
    Never == S.Failure, T == S.Input
  {
    subscriber.receive(emission: .value(value))
    subscriber.receive(emission: .finished)
    return AutoDisposable { }
  }

  init(_ value: T) {
    self.value = value
  }

  private let value: T

  public typealias Output = T
  public typealias Failure = Never

}
