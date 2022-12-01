import DisposableInterface
import Foundation

// MARK: - Emitter

@MainActor
public protocol Emitter<Output> {
    associatedtype Output: Sendable
    func subscribe<S: Subscriber>(
        _ subscriber: S
    ) -> AnyDisposable
        where S.Value == Output
}
