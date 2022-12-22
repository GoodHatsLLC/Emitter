import DisposableInterface

// MARK: - Emitter

public protocol Emitter<Output> {
    associatedtype Output: Sendable
    func subscribe<S: Subscriber>(
        _ subscriber: S
    ) -> AnyDisposable where S.Value == Output
}

// MARK: - Emitters

public enum Emitters {}
