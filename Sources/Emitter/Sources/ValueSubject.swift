import Disposable
import Foundation

// MARK: - ValueSubject

public final class ValueSubject<Output, Failure: Error>: Emitter, Subject {

  // MARK: Lifecycle

  public init(_ value: Output) {
    self.state = Locked((isActive: true, value: value, subs: []))
  }

  // MARK: Public

  public typealias Output = Output

  // MARK: Private

  private let state: Locked<(
    isActive: Bool,
    value: Output,
    subs: Set<Subscription<Output, Failure>>
  )>
}

// MARK: - Source API
extension ValueSubject {

  // MARK: Public

  public var value: Output {
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

  public func emit(value: Output) {
    emit(.value(value))
  }

  public func fail(_ error: Failure) {
    emit(.failed(error))
  }

  // MARK: Private

  private func emit(_ emission: Emission<Output, Failure>) {
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
      let subs: [Subscription<Output, Failure>] = state.withLock { state in
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
    where S.Input == Output, S.Failure == Failure
  {
    let subscription = Subscription<Output, Failure>(
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

extension ValueSubject: Sendable where Output: Sendable { }
