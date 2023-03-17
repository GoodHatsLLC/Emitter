import Disposable
import Foundation

// MARK: - ValueSubject

public final class ValueSubject<Value: Sendable>: Emitting, Subject, @unchecked
Sendable {

  // MARK: Lifecycle

  public init(_ value: Value) {
    self.isActive = true
    self._value = value
  }

  // MARK: Public

  public typealias Output = Value

  public var value: Value {
    get {
      lock.withLock {
        _value
      }
    }
    set {
      emit(.value(newValue))
    }
  }

  // MARK: Private

  private let lock = NSLock()
  private var isActive: Bool
  private var _value: Value
  private var subscriptions: Set<Subscription<Value>> = []
}

// MARK: - Source API
extension ValueSubject {

  // MARK: Public

  public func finish() {
    emit(.finished)
  }

  public func emit(value: Value) {
    emit(.value(value))
  }

  public func fail(_ error: some Error) {
    emit(.failed(error))
  }

  // MARK: Private

  private func emit(_ emission: Emission<Value>) {
    let subs = lock.withLock {
      stateEffects(emission)
    }
    for sub in subs {
      sub.receive(emission: emission)
    }
  }

  private func stateEffects(_ emission: Emission<Value>) -> Set<Subscription<Value>> {
    let subs = subscriptions
    switch emission {
    case .failed,
         .finished:
      isActive = false
      subscriptions.removeAll()
    case .value(let value):
      _value = value
    }
    return subs
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
      subscriber: subscriber
    )

    let didSubscribe = lock
      .withLock {
        if isActive {
          subscriptions.insert(subscription)
        }
        return isActive
      }

    if didSubscribe {
      subscription.receive(emission: .value(value))
      return AnyDisposable {
        let disposable = self.lock.withLock {
          self.subscriptions.remove(subscription)
        }
        disposable?.dispose()
      }
    } else {
      subscription.receive(emission: .finished)
      subscription.dispose()
      return subscription.erase()
    }
  }
}
