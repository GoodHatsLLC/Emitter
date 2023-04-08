import Disposable
import Foundation

// MARK: - ValueSubject

public final class ValueSubject<Value: Sendable>: Emitter, Subject, @unchecked
Sendable {

  // MARK: Lifecycle

  public init(_ value: Value) {
    self.state = Locked((isActive: true, value: value, subs: []))
  }

  // MARK: Public

  public typealias Output = Value

  // MARK: Private

  private let state: Locked<(isActive: Bool, value: Value, subs: Set<Subscription<Value>>)>
}

// MARK: - Source API
extension ValueSubject {

  // MARK: Public

  public var value: Value {
    get {
      state.withLock { state in
        state.value
      }
    }
    set {
      emit(.value(newValue))
    }
  }

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
    case .value(let value):
      let subs: [Subscription<Value>] = state.withLock { state in
        guard state.isActive
        else {
          return []
        }
        state.value = value
        return Array(state.subs)
      }
      subs.forEach { sub in
        sub.receive(emission: emission)
      }
    }
  }
}

// MARK: - Emitter API
extension ValueSubject {
  public func subscribe<S: Subscriber>(
    _ subscriber: S
  )
    -> AutoDisposable
    where S.Value == Value
  {
    let subscription = Subscription<Value>(
      subscriber: subscriber
    )
    let (didSubscribe, value) = state
      .withLock { state in
        if state.isActive {
          state.subs.insert(subscription)
        }
        return (state.isActive, state.value)
      }

    if didSubscribe {
      subscriber.receive(emission: .value(value))
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
