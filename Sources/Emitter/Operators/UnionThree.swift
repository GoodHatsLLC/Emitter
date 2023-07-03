import Disposable

extension Emitter {
  public func unionWithTypedFailure<UpstreamB: Emitter, UpstreamC: Emitter>(
    _ otherB: UpstreamB,
    _ otherC: UpstreamC
  ) -> some Emitter<Union3<Output, UpstreamB.Output, UpstreamC.Output>, Union3<
    Failure,
    UpstreamB.Failure,
    UpstreamC.Failure
  >> {
    Emitters.UnionThree(upstreamA: self, upstreamB: otherB, upstreamC: otherC)
  }

  public func union<UpstreamB: Emitter, UpstreamC: Emitter>(
    _ otherB: UpstreamB,
    _ otherC: UpstreamC
  ) -> some Emitter<Union3<Output, UpstreamB.Output, UpstreamC.Output>, Error> {
    Emitters
      .UnionThree(upstreamA: self, upstreamB: otherB, upstreamC: otherC)
      .mapFailure { error in
        error as any Error
      }
  }

  public func union<UpstreamB: Emitter, UpstreamC: Emitter>(
    _ otherB: UpstreamB,
    _ otherC: UpstreamC
  ) -> some Emitter<Union3<Output, UpstreamB.Output, UpstreamC.Output>, Never>
    where Failure == Never, UpstreamB.Failure == Never, UpstreamC.Failure == Never
  {
    Emitters
      .UnionThree(upstreamA: self, upstreamB: otherB, upstreamC: otherC)
      .mapFailure { error in
        switch error { }
      }
  }
}

// MARK: - Source

private enum Source: CaseIterable {
  case a
  case b
  case c
}

// MARK: - Emitters.UnionThree

extension Emitters {

  public struct UnionThree<UpstreamA: Emitter, UpstreamB: Emitter, UpstreamC: Emitter>: Emitter {

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

    public typealias Output = Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>
    public typealias Failure = Union3<UpstreamA.Failure, UpstreamB.Failure, UpstreamC.Failure>

    public let upstreamA: UpstreamA
    public let upstreamB: UpstreamB
    public let upstreamC: UpstreamC

    public func subscribe<S: Subscriber>(
      _ subscriber: S
    )
      -> AutoDisposable
      where S.Input == Output, S.Failure == Failure
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
      where Downstream.Input == Union3<
        UpstreamA.Output,
        UpstreamB.Output,
        UpstreamC.Output
      >, Downstream.Failure == Union3<UpstreamA.Failure, UpstreamB.Failure, UpstreamC.Failure>
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Internal

      func receive(emission: Emission<
        EmissionData<Source, Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>, Union3<
          UpstreamA.Failure,
          UpstreamB.Failure,
          UpstreamC.Failure
        >>,
        Never
      >) {
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
              if $0.finished {
                return false
              }
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

      // MARK: Fileprivate

      fileprivate typealias Input = EmissionData<
        Source,
        Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>,
        Union3<UpstreamA.Failure, UpstreamB.Failure, UpstreamC.Failure>
      >
      fileprivate typealias Failure = Never

      fileprivate let downstream: Downstream

      fileprivate func subscribe(
        upstreamA: UpstreamA,
        upstreamB: UpstreamB,
        upstreamC: UpstreamC
      )
        -> AutoDisposable
      {
        let dispA = upstreamA.subscribe(
          TransformProxy(
            downstream: EmissionDataProxy<
              Source,
              Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>,
              Union3<UpstreamA.Failure, UpstreamB.Failure, UpstreamC.Failure>,
              IntermediateSub
            >(
              metadata: Source.a,
              downstream: self
            ),
            joinOutput: Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>.a,
            joinFailure: Union3<UpstreamA.Failure, UpstreamB.Failure, UpstreamC.Failure>.a
          )
        )
        let dispB = upstreamB.subscribe(
          TransformProxy(
            downstream: EmissionDataProxy<
              Source,
              Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>,
              Union3<UpstreamA.Failure, UpstreamB.Failure, UpstreamC.Failure>,
              IntermediateSub
            >(
              metadata: Source.b,
              downstream: self
            ),
            joinOutput: Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>.b,
            joinFailure: Union3<UpstreamA.Failure, UpstreamB.Failure, UpstreamC.Failure>.b
          )
        )
        let dispC = upstreamC.subscribe(
          TransformProxy(
            downstream: EmissionDataProxy<
              Source,
              Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>,
              Union3<UpstreamA.Failure, UpstreamB.Failure, UpstreamC.Failure>,
              IntermediateSub
            >(
              metadata: Source.c,
              downstream: self
            ),
            joinOutput: Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>.c,
            joinFailure: Union3<UpstreamA.Failure, UpstreamB.Failure, UpstreamC.Failure>.c
          )
        )
        let disposable = AutoDisposable {
          dispA.dispose()
          dispB.dispose()
          dispC.dispose()
        }
        return disposable
      }

      // MARK: Private

      private let state = Locked<(finishedSources: Set<Source>, finished: Bool)>(([], false))

    }
  }
}

// MARK: - Emitters.UnionThree + Sendable

extension Emitters.UnionThree: Sendable where UpstreamA: Sendable, UpstreamB: Sendable,
  UpstreamC: Sendable { }
