import Disposable

// MARK: - Emitter

public protocol Emitter<Output, Failure> {
  associatedtype Output
  associatedtype Failure: Error

  nonisolated func subscribe<S: Subscriber>(
    _ subscriber: S
  ) -> AutoDisposable where S.Input == Output, S.Failure == Failure
}
