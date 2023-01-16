import Disposable

// MARK: - Emitter

public protocol Emitter<Output> {
  associatedtype Output: Sendable
  nonisolated func subscribe<S: Subscriber>(
    _ subscriber: S
  ) -> AnyDisposable where S.Value == Output
}

// MARK: - Emitters

public enum Emitters {}
