import Disposable

import Foundation

// MARK: - PublishSubject

public final class PublishSubject<Value: Sendable>: Emitter, Source {

  public init() {}

  public typealias Output = Value

  private var subscriptions: Set<Subscription<Value>> = []
  private var isActive = true
}

// MARK: - Source API
extension PublishSubject {
  public func emit(_ emission: Emission<Value>) {
    let subs = subscriptions
    switch emission {
    case .finished,
         .failed:
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
      source: self,
      subscriber: subscriber
    )
    if isActive {
      subscriptions.insert(subscription)
    } else {
      subscription.receive(emission: .finished)
      subscription.dispose()
    }
    return AnyDisposable {
      self.subscriptions.remove(subscription)?.dispose()
    }
  }
}
