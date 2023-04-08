import Disposable
import Foundation

// MARK: - PublishSubject

public final class PublishSubject<Value: Sendable>: Emitter, Subject, @unchecked
Sendable {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public typealias Output = Value

  // MARK: Private

  private let state =
    Locked<(isActive: Bool, subs: Set<Subscription<Value>>)>((isActive: true, subs: []))
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
    switch emission {
    case .failed,
         .finished:
      let subs = state.withLock { state in
        state.isActive = false
        let subs = state.subs
        state.subs.removeAll()
        return subs
      }
      subs.forEach { sub in
        sub.receive(emission: emission)
      }
    case .value:
      let subs = state.withLock { state in
        state.subs
      }
      subs.forEach { sub in
        sub.receive(emission: emission)
      }
    }
  }
}

// MARK: - Emitter API
extension PublishSubject {
  public func subscribe<S: Subscriber>(
    _ subscriber: S
  )
    -> AutoDisposable
    where S.Value == Value
  {
    let subscription = Subscription<Value>(
      subscriber: subscriber
    )
    let didSubscribe = state
      .withLock { state in
        if state.isActive {
          state.subs.insert(subscription)
        }
        return state.isActive
      }

    if didSubscribe {
      return AutoDisposable {
        if
          let subscription = self.state.withLock(action: { state in
            state.subs.remove(subscription)
          })
        {
          subscription.receive(emission: .finished)
        }
      }
    } else {
      subscription.receive(emission: .finished)
      return AutoDisposable { }
    }
  }
}
