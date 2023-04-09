import Disposable

// MARK: - Emitter

public protocol Emitter<Value, Failure> {
  associatedtype Value
  associatedtype Failure: Error
  nonisolated func subscribe<S: Subscriber>(
    _ subscriber: S
  ) -> AutoDisposable where S.Value == Value, S.Failure == Failure
}
