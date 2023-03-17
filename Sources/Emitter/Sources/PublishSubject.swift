import Disposable
import Foundation

// MARK: - PublishSubject

public final class PublishSubject<Value: Sendable>: Emitting, Subject, @unchecked
Sendable {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public typealias Output = Value

  // MARK: Private

  private let lock = NSLock()
  private var subscriptions: Set<Subscription<Value>> = []
  private var isActive = true
}

// MARK: - Source API
extension PublishSubject {

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
    let subs = subscriptions
    switch emission {
    case .failed,
         .finished:
      isActive = false
      subscriptions.removeAll()
    case _:
      break
    }
    for subscription in subs {
      subscription.receive(emission: emission)
    }
  }
}

// MARK: - Emitter API
extension PublishSubject {
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
