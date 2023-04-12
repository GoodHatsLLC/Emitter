import Disposable

extension Emitter {
  public func union<UpstreamB: Emitter, UpstreamC: Emitter>(
    _ otherB: UpstreamB,
    _ otherC: UpstreamC
  ) -> some Emitter<Union3<Value, UpstreamB.Value, UpstreamC.Value>, Failure>
    where Failure == UpstreamB.Failure, Failure == UpstreamC.Failure
  {
    Emitters.UnionThree(upstreamA: self, upstreamB: otherB, upstreamC: otherC)
  }
}

// MARK: - Emitters.UnionThree

extension Emitters {

  public struct UnionThree<UpstreamA: Emitter, UpstreamB: Emitter, UpstreamC: Emitter>: Emitter
    where UpstreamA.Failure == UpstreamB.Failure, UpstreamA.Failure == UpstreamC.Failure
  {

    // MARK: Lifecycle

    public init(
      upstreamA: UpstreamA,
      upstreamB: UpstreamB,
      upstreamC: UpstreamC
    ) {
      self.upstreamA = upstreamA
      self.upstreamB = upstreamB
      self.upstreamC = upstreamC
    }

    // MARK: Public

    public typealias Value = Union3<UpstreamA.Value, UpstreamB.Value, UpstreamC.Value>
    public typealias Failure = UpstreamA.Failure

    public let upstreamA: UpstreamA
    public let upstreamB: UpstreamB
    public let upstreamC: UpstreamC

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AutoDisposable
      where S.Input == Value, S.Failure == Failure
    {
      IntermediateSub<S>(downstream: subscriber)
        .subscribe(
          upstreamA: upstreamA,
          upstreamB: upstreamB,
          upstreamC: upstreamC
        )
    }

    // MARK: Private

    private final class IntermediateSub<Downstream: Subscriber>: Subscriber
      where Downstream.Input == Value, Downstream.Failure == Failure
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Fileprivate

      fileprivate let downstream: Downstream

      fileprivate func subscribe(
        upstreamA: UpstreamA,
        upstreamB: UpstreamB,
        upstreamC: UpstreamC
      )
        -> AutoDisposable
      {
        let disposableA = upstreamA
          .subscribe(
            Proxy<UpstreamA.Value, UpstreamA.Failure, IntermediateSub>(
              downstream: self,
              joinInit: Union3.a
            )
          )
        let disposableB = upstreamB
          .subscribe(
            Proxy<UpstreamB.Value, UpstreamB.Failure, IntermediateSub>(
              downstream: self,
              joinInit: Union3.b
            )
          )
        let disposableC = upstreamC
          .subscribe(
            Proxy<UpstreamC.Value, UpstreamC.Failure, IntermediateSub>(
              downstream: self,
              joinInit: Union3.c
            )
          )
        let disposable = AutoDisposable {
          disposableA.dispose()
          disposableB.dispose()
          disposableC.dispose()
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

    private struct Proxy<UpstreamValue, UpstreamFailure: Error, Downstream: Subscriber>: Subscriber
      where Downstream.Failure == UpstreamFailure
    {

      public typealias Value = UpstreamValue
      public typealias Failure = Downstream.Failure

      fileprivate init(
        downstream: Downstream,
        joinInit: @escaping (UpstreamValue) ->  Downstream.Input
      ) {
        self.downstream = downstream
        self.joinInit = joinInit
      }

      fileprivate func receive(emission: Emission<UpstreamValue, Failure>) {
        let forwarded: Emission< Downstream.Input, Failure>
        switch emission {
        case .value(let value):
          forwarded = .value(joinInit(value))
        case .finished:
          forwarded = .finished
        case .failed(let error):
          forwarded = .failed(error)
        }
        downstream.receive(emission: forwarded)
      }

      private let downstream: Downstream
      private let joinInit: (UpstreamValue) ->  Downstream.Input

    }

  }
}
