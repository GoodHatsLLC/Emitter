import Disposable

extension Emitter {

  public func combineLatest<UpstreamB: Emitter, UpstreamC: Emitter>(
    _ otherB: UpstreamB,
    _ otherC: UpstreamC
  ) -> some Emitter<(Output, UpstreamB.Output, UpstreamC.Output), Failure>
    where UpstreamB.Failure == Failure, UpstreamC.Failure == Failure
  {
    Emitters
      .CombineLatestThree(upstreamA: self, upstreamB: otherB, upstreamC: otherC)
      .mapFailure { error in
        switch error {
        case .a(let err),
             .b(let err),
             .c(let err): return err
        }
      }
  }

  public func combineLatest<UpstreamB: Emitter, UpstreamC: Emitter>(
    _ otherB: UpstreamB,
    _ otherC: UpstreamC
  ) -> some Emitter<(Output, UpstreamB.Output, UpstreamC.Output), Error> {
    Emitters
      .CombineLatestThree(upstreamA: self, upstreamB: otherB, upstreamC: otherC)
      .mapFailure { error in
        switch error {
        case .a(let err): return err as Error
        case .b(let err): return err as Error
        case .c(let err): return err as Error
        }
      }
  }

  public func combineLatest<UpstreamB: Emitter, UpstreamC: Emitter>(
    _ otherB: UpstreamB,
    _ otherC: UpstreamC
  ) -> some Emitter<(Output, UpstreamB.Output, UpstreamC.Output), Never> where Failure == Never,
    UpstreamB.Failure == Never,
    UpstreamC.Failure == Never
  {
    Emitters
      .CombineLatestThree(upstreamA: self, upstreamB: otherB, upstreamC: otherC)
      .mapFailure { error in
        switch error {
        case .a,
             .b,
             .c:
          fatalError("Failure == Never")
        }
      }
  }
}

// MARK: - Source

private enum Source: CaseIterable {
  case a
  case b
  case c
}

// MARK: - Emitters.CombineLatestThree

extension Emitters {

  public struct CombineLatestThree<
    UpstreamA: Emitter,
    UpstreamB: Emitter,
    UpstreamC: Emitter
  >: Emitter {

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

    public typealias Output = (UpstreamA.Output, UpstreamB.Output, UpstreamC.Output)
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
      where Downstream.Input == (UpstreamA.Output, UpstreamB.Output, UpstreamC.Output),
      Downstream.Failure == Union3<
        UpstreamA.Failure,
        UpstreamB.Failure,
        UpstreamC.Failure
      >
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Internal

      struct State {
        var finished: Set<Source> = []
        var allFinished = false
        var lastA: UpstreamA.Output? = nil
        var lastB: UpstreamB.Output? = nil
        var lastC: UpstreamC.Output? = nil
      }

      func receive(emission: Emission<
        EmissionData<
          Source,
          Union3<UpstreamA.Output, UpstreamB.Output, UpstreamC.Output>,
          Union3<UpstreamA.Failure, UpstreamB.Failure, UpstreamC.Failure>
        >,
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
              if $0.allFinished {
                return false
              }
              $0.allFinished = true
              return true
            }
            if shouldForward {
              downstream.receive(emission: .failed(union))
            }
          case .value(let union):
            let output: (UpstreamA.Output, UpstreamB.Output, UpstreamC.Output)? = state
              .withLock { mutState in
                if mutState.allFinished {
                  return nil
                }
                switch union {
                case .a(let a):
                  mutState.lastA = a
                case .b(let b):
                  mutState.lastB = b
                case .c(let c):
                  mutState.lastC = c
                }
                if
                  let a = mutState.lastA,
                  let b = mutState.lastB,
                  let c = mutState.lastC
                {
                  return (a, b, c)
                } else {
                  return nil
                }
              }
            if let output {
              downstream.receive(emission: .value(output))
            }
          case .finished:
            let shouldForward = state.withLock { mutValue in
              if mutValue.allFinished {
                return false
              }
              mutValue.finished.insert(meta)
              let didFinish = mutValue.finished.isSuperset(of: Source.allCases)
              mutValue.allFinished = didFinish
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
            downstream: EmissionDataProxy(
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

      private let state = Locked<State>(.init())

    }
  }
}

// MARK: - Emitters.CombineLatestThree + Sendable

extension Emitters.CombineLatestThree: Sendable where UpstreamA: Sendable, UpstreamB: Sendable,
  UpstreamC: Sendable { }
