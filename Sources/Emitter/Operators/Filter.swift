import Disposable

extension Emitter {
  public func filter(
    _ evaluator: @escaping @Sendable (Output) -> Bool
  ) -> some Emitter<Output, Failure> {
    Emitters.Filter(upstream: self, evaluator: evaluator)
  }
}

// MARK: - Emitters.Filter

extension Emitters {
  // MARK: - Filter

  public struct Filter<Upstream: Emitter>: Emitter {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      evaluator: @escaping @Sendable (Output) -> Bool
    ) where Upstream.Output == Output {
      self.evaluator = evaluator
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Output = Upstream.Output
    public typealias Failure = Upstream.Failure

    public let evaluator: @Sendable (Output) -> Bool
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Input == Output, S.Failure == Failure
    {
      upstream.subscribe(Sub<S>(downstream: subscriber, evaluator: evaluator))
    }

    // MARK: Private

    private struct Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Input == Output, Downstream.Failure == Failure
    {
      fileprivate init(downstream: Downstream, evaluator: @escaping (Output) -> Bool) {
        self.downstream = downstream
        self.evaluator = evaluator
      }

      fileprivate func receive(emission: Emission<Output, Failure>) {
        let newEmission: Emission<Output, Failure>?
        switch emission {
        case .value(let value):
          if evaluator(value) {
            newEmission = .value(value)
          } else {
            newEmission = nil
          }
        case _:
          newEmission = emission
        }
        if let newEmission {
          downstream.receive(emission: newEmission)
        }
      }

      private let downstream: Downstream
      private let evaluator: (Output)
        -> Bool
    }
  }
}

// MARK: - Emitters.Filter + Sendable

extension Emitters.Filter: Sendable where Upstream: Sendable { }
