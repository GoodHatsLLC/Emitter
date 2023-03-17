import Disposable

// MARK: - Emitting

public protocol Emitting<Output>: Sendable {
  associatedtype Output: Sendable
  nonisolated func subscribe<S: Subscriber>(
    _ subscriber: S
  ) -> AnyDisposable where S.Value == Output
}
