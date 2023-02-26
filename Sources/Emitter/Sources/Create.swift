import Disposable
import Foundation

extension Emitters {
  public static func create<Output: Sendable>(
    _: Output.Type,
    _ creator: @escaping @Sendable (_ emit: @escaping @Sendable (Emission<Output>) -> Void) async -> Void
  ) -> some Emitter<Output> {
    Emitters.Create(with: creator)
  }
}

// MARK: - Emitters.Create

extension Emitters {
  // MARK: - Create

  private final class Create<Output: Sendable>: Emitter, @unchecked Sendable {

    fileprivate init(
      with creator: @escaping @Sendable (_ source: @escaping @Sendable (Emission<Output>) -> Void) async -> Void
    ) {
      self.creator = creator
    }

    fileprivate func subscribe<S: Subscriber>(_ subscriber: S) -> AnyDisposable
      where S.Value == Output
    {
      let subscription = Subscription<Output>(
        subscriber: subscriber
      )
      let didSubscribe = lock
        .withLock {
          if disposable == nil {
            guard let started = start()
            else {
              return false
            }
            subscriptions.insert(subscription)
            disposable = started
            return true
          } else {
            subscriptions.insert(subscription)
            return true
          }
        }
      guard didSubscribe
      else {
        subscription.receive(emission: .finished)
        return AnyDisposable {}
      }
      return AnyDisposable {
        let (subscriptionDisposable, sourceDisposable) = self.lock.withLock {
          let subscriptionDisposable = self.subscriptions.remove(subscription)
          let sourceDisposable: AnyDisposable?
          if self.subscriptions.isEmpty {
            sourceDisposable = self.disposable
            self.disposable = nil
          } else {
            sourceDisposable = nil
          }
          return (subscriptionDisposable?.erase(), sourceDisposable)
        }
        subscriptionDisposable?.dispose()
        sourceDisposable?.dispose()
      }
    }

    private struct Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output
    {

      fileprivate init(
        downstream: Downstream
      ) {
        self.downstream = downstream
      }

      fileprivate func receive(emission: Emission<Output>) {
        downstream.receive(emission: emission)
      }

      private let downstream: Downstream
    }

    private let lock = NSLock()
    private var creator: (@Sendable (_ source: @escaping @Sendable (Emission<Output>) -> Void) async -> Void)?
    private var subscriptions: Set<Subscription<Output>> = []
    private var disposable: AnyDisposable?

    private func emitDownstream(_ emission: Emission<Output>) {
      let subs = lock.withLock {
        subscriptions
      }
      for sub in subs {
        sub.receive(emission: emission)
      }
    }

    private func start() -> AnyDisposable? {
      guard let creator
      else {
        assertionFailure()
        return nil
      }
      return Task {
        await creator { self.emitDownstream($0) }
      }.erase()
    }

  }
}
