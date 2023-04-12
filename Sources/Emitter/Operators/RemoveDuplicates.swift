import Disposable

extension Emitter {
  public func removeDuplicates() -> some Emitter<Output, Failure>
    where Output: Equatable
  {
    Emitters.RemoveDuplicates(upstream: self, eqFunc: ==)
  }

  public func removeDuplicates(by filter: @escaping (_ lhs: Output, _ rhs: Output) -> Bool)
    -> some Emitter<Output, Failure>
  {
    Emitters.RemoveDuplicates(upstream: self, eqFunc: filter)
  }
}

// MARK: - Emitters.RemoveDuplicates

extension Emitters {
  // MARK: - RemoveDuplicates

  public struct RemoveDuplicates<Upstream: Emitter>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      eqFunc: @escaping (Upstream.Output, Upstream.Output) -> Bool
    ) {
      self.upstream = upstream
      self.eqFunc = eqFunc
    }

    // MARK: Public

    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Input == Output, S.Failure == Failure
    {
      upstream.subscribe(
        Sub<S>(
          downstream: subscriber,
          eqFunc: eqFunc
        )
      )
    }

    // MARK: Private

    private final class Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Input == Upstream.Output, Downstream.Failure == Upstream.Failure
    {

      // MARK: Lifecycle

      public init(
        downstream: Downstream,
        eqFunc: @escaping (Upstream.Output, Upstream.Output) -> Bool
      ) {
        self.downstream = downstream
        self.eqFunc = eqFunc
      }

      // MARK: Public

      public func receive(emission: Emission<Output, Failure>) {
        switch emission {
        case .value(let curr):
          if let last, eqFunc(curr, last) {
            // curr == last, skip emission.
          } else {
            last = curr
            downstream.receive(emission: emission)
          }
        case _:
          downstream.receive(emission: emission)
        }
      }

      // MARK: Private

      private let downstream: Downstream
      private let eqFunc: (Upstream.Output, Upstream.Output) -> Bool
      private var last: Output?

    }

    private let upstream: Upstream
    private let eqFunc: (Upstream.Output, Upstream.Output) -> Bool
  }
}
