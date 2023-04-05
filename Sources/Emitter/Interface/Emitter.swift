import Disposable

// MARK: - Emitter

public protocol Emitter<Output>: Sendable {
  associatedtype Output: Sendable
  nonisolated func subscribe<S: Subscriber>(
    _ subscriber: S
  ) -> AutoDisposable where S.Value == Output
}
