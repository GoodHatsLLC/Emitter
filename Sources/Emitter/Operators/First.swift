import Disposable

extension Emitter {
  public func first() -> some Emitter<Output, Failure> {
    Emitters.First(upstream: self, count: 1)
  }

  public func first(_ count: Int) -> some Emitter<Output, Failure> {
    Emitters.First(upstream: self, count: count)
  }
}

// MARK: - Emitters.First

extension Emitters {
  // MARK: - Prefix

  public struct First<Upstream: Emitter>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      count: Int
    ) {
      self.upstream = upstream
      self.count = count
    }

    // MARK: Public

    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Input == Output, S.Failure == Failure
    {
      return upstream.subscribe(
        Sub<S>(
          downstream: subscriber,
          count: count
        )
      )
    }

    // MARK: Private

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Input == Output, Downstream.Failure == Failure
    {

      // MARK: Lifecycle

      public init(
        downstream: Downstream,
        count: Int
      ) {
        self.downstream = downstream
        self.remaining = .init(count)
      }

      // MARK: Public

      public func receive(emission: Emission<Upstream.Output, Upstream.Failure>) {
        let shouldReceive = remaining.withLock { remaining in
          if remaining > 0 {
            remaining -= 1
            return true
          } else {
            return false
          }
        }
        if shouldReceive {
          switch emission {
          case .value:
            downstream.receive(emission: emission)
            downstream.receive(emission: .finished)
          default:
            downstream.receive(emission: emission)
          }
        }
      }

      // MARK: Private

      private let remaining: Locked<Int>
      private let downstream: Downstream
    }

    private let upstream: Upstream
    private let count: Int
  }
}

// MARK: - Emitters.First + Sendable

extension Emitters.First: Sendable where Upstream: Sendable { }
