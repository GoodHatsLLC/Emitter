import Disposable
import Foundation

// MARK: - PublishSubject

public final class PublishSubject<Output, Failure: Error>: Emitter, Subject {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public typealias Output = Output

  // MARK: Private

  private let state =
    Locked<(isActive: Bool, subs: Set<Subscription<Output, Failure>>)>((isActive: true, subs: []))
}

// MARK: - Source API
extension PublishSubject {

  // MARK: Public

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
        if state.isActive {
          state.isActive = false
          defer { state.subs.removeAll() }
          return state.subs
        } else {
          return []
        }
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
    where S.Input == Output, S.Failure == Failure
  {
    let subscription = Subscription<Output, Failure>(
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
        _ = self.state.withLock { state in
          state.subs.remove(subscription)
        }
      }
    } else {
      subscription.receive(emission: .finished)
      return AutoDisposable { }
    }
  }
}

// MARK: Sendable

extension PublishSubject: Sendable where Input: Sendable { }
