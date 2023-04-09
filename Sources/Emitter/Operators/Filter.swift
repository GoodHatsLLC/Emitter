import Disposable

extension Emitter {
  public func filter(
    _ evaluator: @escaping @Sendable (Value) -> Bool
  ) -> some Emitter<Value, Failure> {
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
      evaluator: @escaping @Sendable (Value) -> Bool
    ) where Upstream.Value == Value {
      self.evaluator = evaluator
      self.upstream = upstream
    }

    // MARK: Public

    public typealias Value = Upstream.Value
    public typealias Failure = Upstream.Failure

    public let evaluator: @Sendable (Value) -> Bool
    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Value == Value, S.Failure == Failure
    {
      upstream.subscribe(Sub<S>(downstream: subscriber, evaluator: evaluator))
    }

    // MARK: Private

    private struct Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Value, Downstream.Failure == Failure
    {
      fileprivate init(downstream: Downstream, evaluator: @escaping (Value) -> Bool) {
        self.downstream = downstream
        self.evaluator = evaluator
      }

      fileprivate func receive(emission: Emission<Value, Failure>) {
        let newEmission: Emission<Value, Failure>?
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
      private let evaluator: (Value)
        -> Bool
    }
  }
}

// MARK: - Emitters.Filter + Sendable

extension Emitters.Filter: Sendable where Upstream: Sendable { }
