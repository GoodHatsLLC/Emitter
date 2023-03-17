import Disposable

extension Emitting {
  public func removeDuplicates() -> some Emitting<Output>
    where Output: Equatable
  {
    Emitter.RemoveDuplicates(upstream: self)
  }
}

// MARK: - Emitter.RemoveDuplicates

extension Emitter {
  // MARK: - RemoveDuplicates

  public struct RemoveDuplicates<Upstream: Emitting, Output: Sendable>: Emitting
    where Output: Equatable,
    Upstream.Output == Output
  {

    // MARK: Lifecycle

    public init(
      upstream: Upstream
    ) {
      self.upstream = upstream
    }

    // MARK: Public

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AnyDisposable
      where S.Value == Output, Output: Equatable
    {
      upstream.subscribe(Sub<S>(downstream: subscriber))
    }

    // MARK: Private

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output, Output: Equatable
    {

      // MARK: Lifecycle

      public init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Public

      public func receive(emission: Emission<Output>) {
        switch emission {
        case .value(let value):
          if value != last {
            last = value
            downstream.receive(emission: emission)
          }
        case _:
          downstream.receive(emission: emission)
        }
      }

      // MARK: Private

      private let downstream: Downstream
      private var last: Output?

    }

    private let upstream: Upstream

  }
}
