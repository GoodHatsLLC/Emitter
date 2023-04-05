import Disposable

extension Emitter {
  public func filter(
    _ evaluator: @escaping @Sendable (Output) -> Bool
  ) -> some Emitter<Output> {
    Emitters.Filter(upstream: self, evaluator: evaluator)
  }
}

// MARK: - Emitters.Filter

extension Emitters {
  // MARK: - Filter

  public struct Filter<Upstream: Emitter & Sendable, Output: Sendable>: Emitter, Sendable
    where Upstream.Output == Output
  {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      evaluator: @escaping @Sendable (Output) -> Bool
    ) where Upstream.Output == Output {
      self.evaluator = evaluator
      self.upstream = upstream
    }

    // MARK: Public

    public let evaluator: @Sendable (Output) -> Bool
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Value == Output
    {
      upstream.subscribe(Sub<S>(downstream: subscriber, evaluator: evaluator))
    }

    // MARK: Private

    private struct Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output
    {
      fileprivate init(downstream: Downstream, evaluator: @escaping (Output) -> Bool) {
        self.downstream = downstream
        self.evaluator = evaluator
      }

      fileprivate func receive(emission: Emission<Output>) {
        let newEmission: Emission<Output>?
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
