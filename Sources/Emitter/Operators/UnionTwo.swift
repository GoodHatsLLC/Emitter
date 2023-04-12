import Disposable

extension Emitter {
  public func unionWithTypedFailure<UpstreamB: Emitter>(
    _ otherB: UpstreamB
  ) -> some Emitter<Union2<Output, UpstreamB.Output>, Union2<Failure, UpstreamB.Failure>> {
    Emitters.UnionTwo(upstreamA: self, upstreamB: otherB)
  }
  public func union<UpstreamB: Emitter>(
    _ otherB: UpstreamB
  ) -> some Emitter<Union2<Output, UpstreamB.Output>, Error> {
    Emitters
      .UnionTwo(upstreamA: self, upstreamB: otherB)
      .mapFailure { error in
        error as Error
      }
  }
  public func union<UpstreamB: Emitter>(
    _ otherB: UpstreamB
  ) -> some Emitter<Union2<Output, UpstreamB.Output>, Never> where Failure == Never, UpstreamB.Failure == Never {
    Emitters
      .UnionTwo(upstreamA: self, upstreamB: otherB)
      .mapFailure { error in
        switch error {}
      }
  }
}

fileprivate enum Source: CaseIterable {
  case a
  case b
}

// MARK: - Emitters.UnionTwo

extension Emitters {

  public struct UnionTwo<UpstreamA: Emitter, UpstreamB: Emitter>: Emitter
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

    public typealias Output = Union2<UpstreamA.Output, UpstreamB.Output>
    public typealias Failure = Union2<UpstreamA.Failure, UpstreamB.Failure>

    public let upstreamA: UpstreamA
    public let upstreamB: UpstreamB

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AutoDisposable
      where S.Input == Output, S.Failure == Failure
    {
      IntermediateSub<S>(downstream: subscriber)
        .subscribe(
          upstreamA: upstreamA,
          upstreamB: upstreamB
        )
    }

    // MARK: Private

    private final class IntermediateSub<Downstream: Subscriber>: Subscriber where Downstream.Input == Union2<UpstreamA.Output, UpstreamB.Output>, Downstream.Failure == Union2<UpstreamA.Failure, UpstreamB.Failure>
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Fileprivate

      fileprivate let downstream: Downstream

      fileprivate typealias Input = EmissionData<Source, Union2<UpstreamA.Output, UpstreamB.Output>, Union2<UpstreamA.Failure, UpstreamB.Failure>>
      fileprivate typealias Failure = Never

      fileprivate func subscribe(
        upstreamA: UpstreamA,
        upstreamB: UpstreamB
      )
        -> AutoDisposable
      {

        let dispA = upstreamA.subscribe(
          TransformProxy(
            downstream: EmissionDataProxy(
              metadata: Source.a,
              downstream: self
            ),
            joinOutput: Union2<UpstreamA.Output, UpstreamB.Output>.a,
            joinFailure: Union2<UpstreamA.Failure, UpstreamB.Failure>.a)
        )

        let dispB = upstreamB.subscribe(
          TransformProxy(
            downstream: EmissionDataProxy<Source, Union2<UpstreamA.Output, UpstreamB.Output>, Union2<UpstreamA.Failure, UpstreamB.Failure>, IntermediateSub>(
              metadata: Source.b,
              downstream: self
            ),
            joinOutput: Union2<UpstreamA.Output, UpstreamB.Output>.b,
            joinFailure: Union2<UpstreamA.Failure, UpstreamB.Failure>.b)
        )
        let disposable = AutoDisposable {
          dispA.dispose()
          dispB.dispose()
        }
        return disposable
      }

      func receive(emission: Emission<EmissionData<Source, Union2<UpstreamA.Output, UpstreamB.Output>, Union2<UpstreamA.Failure, UpstreamB.Failure>>, Never>) {
        switch emission {
        case .finished:
          assertionFailure()
          downstream.receive(emission: .finished)
        case .value(let data):
          let meta = data.meta
          let emission = data.emission
          switch emission {
          case .failure(let union):
            let shouldForward = state.withLock {
              if $0.finished { return false }
              $0.finished = true
              return true
            }
            if shouldForward {
              downstream.receive(emission: .failed(union))
            }
          case .value(let union):
            let shouldForward = state.withLock { !$0.finished }
            if shouldForward {
              downstream.receive(emission: .value(union))
            }
          case .finished:
            let shouldForward = state.withLock { mutValue in
              if mutValue.finished {
                return false
              }
              mutValue.finishedSources.insert(meta)
              let didFinish = mutValue.finishedSources.isSuperset(of: Source.allCases)
              mutValue.finished = didFinish
              return didFinish
            }

            if shouldForward {
              downstream.receive(emission: .finished)
            }
          }
        }
      }

      // MARK: Private

      private let state = Locked<(finishedSources: Set<Source>, finished: Bool)>(([], false))

    }
  }
}

// MARK: - Emitters.UnionTwo + Sendable

extension Emitters.UnionTwo: Sendable where UpstreamA: Sendable, UpstreamB: Sendable { }
