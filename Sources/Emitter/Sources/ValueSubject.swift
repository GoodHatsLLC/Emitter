import Disposable
import Foundation

// MARK: - ValueSubject

public final class ValueSubject<Value, Failure: Error>: Emitter, Subject {

  // MARK: Lifecycle

  public init(_ value: Value) {
    self.state = Locked((isActive: true, value: value, subs: []))
  }

  // MARK: Public

  public typealias Value = Value

  // MARK: Private

  private let state: Locked<(isActive: Bool, value: Value, subs: Set<Subscription<Value, Failure>>)>
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

  public func fail(_ error: Failure) {
    emit(.failed(error))
  }

  // MARK: Private

  private func emit(_ emission: Emission<Value, Failure>) {
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
      let subs: [Subscription<Value, Failure>] = state.withLock { state in
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
    where S.Value == Value, S.Failure == Failure
  {
    let subscription = Subscription<Value, Failure>(
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

// MARK: Sendable

extension ValueSubject: Sendable where Value: Sendable { }
