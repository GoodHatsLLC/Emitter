import Disposable
import EmitterInterface
import Foundation

// MARK: - ValueSubject

@MainActor
public final class ValueSubject<Value: Sendable>: Emitter, Source {

    @inlinable
    public init(_ value: Value) {
        storage = .init(
            isActive: true,
            value: value
        )
    }

    public typealias Output = Value

    public var id: UUID = .init()

    @inlinable
    public var value: Value {
        get { storage.value }
        set {
            storage.value = newValue
            emit(value: newValue)
        }
    }

    @usableFromInline
    @MainActor
    struct Storage {
        @inlinable
        init(isActive: Bool, value: Value, subscriptions: Set<Subscription<Value>> = []) {
            self.isActive = isActive
            self.value = value
            self.subscriptions = subscriptions
        }

        @usableFromInline
        var isActive: Bool
        @usableFromInline
        var value: Value
        @usableFromInline
        var subscriptions: Set<Subscription<Value>> = []
    }

    @usableFromInline
    var storage: Storage
}

// MARK: - Source API
extension ValueSubject {

    @inlinable
    public func emit(_ emission: Emission<Value>) {
        switch emission {
        case .finished,
             .failed:
            storage.isActive = false
            let subs = storage.subscriptions
            storage.subscriptions.removeAll()
            subs.forEach { subscription in
                subscription.receive(emission: emission)
            }
        case .value(let value):
            self.value = value
        }
    }

    @inlinable
    func emit(value: Value) {
        for subscription in storage.subscriptions {
            subscription
                .receive(emission: .value(value))
        }
    }

}

// MARK: - Emitter API
extension ValueSubject {
    @inlinable
    public func subscribe<S: Subscriber>(
        _ subscriber: S
    )
        -> AnyDisposable
        where S.Value == Value {
        let subscription = Subscription<Value>(
            source: self,
            subscriber: subscriber
        )

        if storage.isActive {
            storage.subscriptions.insert(subscription)
            subscription.receive(emission: .value(value))
        } else {
            subscription.receive(emission: .finished)
            subscription.dispose()
        }

        return AnyDisposable {
            self.storage.subscriptions.remove(subscription)?.dispose()
        }
    }
}
