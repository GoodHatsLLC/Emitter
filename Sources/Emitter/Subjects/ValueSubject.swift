import Disposable
import EmitterInterface
import Foundation

// MARK: - ValueSubject

@MainActor
public final class ValueSubject<Value: Sendable>: Emitter, Source {

    public init(_ value: Value) {
        isActive = true
        _value = value
    }

    public typealias Output = Value

    public var value: Value {
        get { _value }
        set {
            _value = newValue
            emit(value: newValue)
        }
    }

    private var isActive: Bool
    private var _value: Value
    private var subscriptions: Set<Subscription<Value>> = []
}

// MARK: - Source API
extension ValueSubject {

    public func emit(_ emission: Emission<Value>) {
        switch emission {
        case .finished,
             .failed:
            isActive = false
            let subs = subscriptions
            subscriptions.removeAll()
            for subscription in subs {
                subscription.receive(emission: emission)
            }
        case .value(let value):
            self.value = value
        }
    }

    func emit(value: Value) {
        for subscription in subscriptions {
            subscription
                .receive(emission: .value(value))
        }
    }

}

// MARK: - Emitter API
extension ValueSubject {
    public func subscribe<S: Subscriber>(
        _ subscriber: S
    )
        -> AnyDisposable
        where S.Value == Value
    {
        let subscription = Subscription<Value>(
            source: self,
            subscriber: subscriber
        )

        if isActive {
            subscriptions.insert(subscription)
            subscription.receive(emission: .value(value))
        } else {
            subscription.receive(emission: .finished)
            subscription.dispose()
        }

        return AnyDisposable {
            self.subscriptions.remove(subscription)?.dispose()
        }
    }
}
