import Disposable

extension Emitter {
  public func merge<Other: Emitter>(
    _ other: Other
  ) -> some Emitter<Value, Failure> where Other.Value == Value, Other.Failure == Failure {
    Emitters.MergeTwo(upstreamA: self, upstreamB: other)
  }
}

// MARK: - Emitters.MergeTwo

extension Emitters {
  // MARK: - Merge

  public struct MergeTwo<UpstreamA: Emitter, UpstreamB: Emitter>: Emitter
    where UpstreamA.Value == UpstreamB.Value, UpstreamA.Failure == UpstreamB.Failure
  {

    // MARK: Lifecycle

    public init(
      upstreamA: UpstreamA,
      upstreamB: UpstreamB
    ) {
      self.upstreamA = upstreamA
      self.upstreamB = upstreamB
    }

    // MARK: Public

    public typealias Value = UpstreamA.Value
    public typealias Failure = UpstreamA.Failure

    public let upstreamA: UpstreamA
    public let upstreamB: UpstreamB

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AutoDisposable
      where S.Input == Value, S.Failure == Failure
    {
      IntermediateSub<S>(downstream: subscriber)
        .subscribe(
          upstreamA: upstreamA,
          upstreamB: upstreamB
        )
    }

    // MARK: Private

    private final class IntermediateSub<Downstream: Subscriber>: Subscriber
      where  Downstream.Input == UpstreamA.Value, Downstream.Failure == UpstreamA.Failure
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Internal

      typealias Value =  Downstream.Input
      typealias Failure = Downstream.Failure

      // MARK: Fileprivate

      fileprivate let downstream: Downstream

      fileprivate func subscribe(
        upstreamA: UpstreamA,
        upstreamB: UpstreamB
      )
        -> AutoDisposable where
        UpstreamA.Value == Value, UpstreamA.Failure == Failure,
        UpstreamB.Value == Value, UpstreamB.Failure == Failure
      {
        let disposableA = upstreamA.subscribe(self)
        let disposableB = upstreamB.subscribe(self)
        let disposable = AutoDisposable {
          disposableA.dispose()
          disposableB.dispose()
        }
        self.disposable = disposable
        return disposable
      }

      fileprivate func receive(emission: Emission<Value, Failure>) {
        downstream.receive(emission: emission)

        switch emission {
        case .value: break
        case .failed,
             .finished:
          if let disposable {
            disposable.dispose()
          }
        }
      }

      // MARK: Private

      private var disposable: AutoDisposable?

    }

  }
}

// MARK: - Emitters.MergeTwo + Sendable

extension Emitters.MergeTwo: Sendable where UpstreamA: Sendable, UpstreamB: Sendable { }
