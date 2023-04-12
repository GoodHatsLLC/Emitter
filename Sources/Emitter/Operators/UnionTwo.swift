import Disposable

extension Emitter {
  public func union<UpstreamB: Emitter>(
    _ otherB: UpstreamB
  ) -> some Emitter<Union2<Value, UpstreamB.Value>, Failure> where Failure == UpstreamB.Failure {
    Emitters.UnionTwo(upstreamA: self, upstreamB: otherB)
  }
}

// MARK: - Emitters.UnionTwo

extension Emitters {

  public struct UnionTwo<UpstreamA: Emitter, UpstreamB: Emitter>: Emitter
    where UpstreamA.Failure == UpstreamB.Failure
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

    public typealias Value = Union2<UpstreamA.Value, UpstreamB.Value>
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
        upstreamB: UpstreamB
      )
        -> AutoDisposable
      {
        let disposableA = upstreamA
          .subscribe(
            Proxy<UpstreamA.Value, UpstreamA.Failure, IntermediateSub>(
              downstream: self,
              joinInit: Union2.a
            )
          )
        let disposableB = upstreamB
          .subscribe(
            Proxy<UpstreamB.Value, UpstreamB.Failure, IntermediateSub>(
              downstream: self,
              joinInit: Union2.b
            )
          )
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

// MARK: - Emitters.UnionTwo + Sendable

extension Emitters.UnionTwo: Sendable where UpstreamA: Sendable, UpstreamB: Sendable { }
