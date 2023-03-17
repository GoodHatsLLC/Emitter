import Disposable
import Foundation

extension Emitter {
  public static func create<Output: Sendable>(
    _: Output.Type,
    _ creator: @escaping @Sendable (_ emit: @escaping @Sendable (Emission<Output>) -> Void) async
      -> Void
  ) -> some Emitting<Output> {
    Emitter.Create(with: creator)
  }
}

// MARK: - Emitter.Create

extension Emitter {
  // MARK: - Create

  private final class Create<Output: Sendable>: Emitting, @unchecked Sendable {

    // MARK: Lifecycle

    fileprivate init(
      with creator: @escaping @Sendable (
        _ source: @escaping @Sendable (Emission<Output>)
          -> Void
      ) async -> Void
    ) {
      self.creator = creator
    }

    // MARK: Fileprivate

    fileprivate func subscribe<S: Subscriber>(_ subscriber: S) -> AnyDisposable
      where S.Value == Output
    {
      let subscription = Subscription<Output>(
        subscriber: subscriber
      )
      let didSubscribe = subscriptions
        .withLock { subscriptions in
          if disposable == nil {
            subscriptions.insert(subscription)
            guard let started = start()
            else {
              subscriptions.remove(subscription)
              return false
            }
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
        return AnyDisposable { }
      }
      return AnyDisposable { [subscriptions] in
        let (subscriptionDisposable, sourceDisposable) = subscriptions.withLock { subscriptions in
          let subscriptionDisposable = subscriptions.remove(subscription)
          let sourceDisposable: AnyDisposable?
          if subscriptions.isEmpty {
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

    // MARK: Private

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

    private var creator: (@Sendable (
      _ source: @escaping @Sendable (Emission<Output>)
        -> Void
    ) async -> Void)?
    private var subscriptions = Locked<Set<Subscription<Output>>>([])
    private var disposable: AnyDisposable?

    private func downstreamEmit(_ emission: Emission<Output>) {
      let subs = subscriptions.withLock { $0 }
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
      let task = Task {
        await creator { event in self.downstreamEmit(event) }
      }
      return AnyDisposable(task)
    }

  }
}
