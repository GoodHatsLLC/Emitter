import Disposable

extension Emitter {

  public func combineLatest<UpstreamB: Emitter>(
    _ otherB: UpstreamB
  ) -> some Emitter<(Output, UpstreamB.Output), Failure> where UpstreamB.Failure == Failure {
    Emitters
      .CombineLatestTwo(upstreamA: self, upstreamB: otherB)
      .mapFailure { error in
        switch error {
        case .a(let err): return err
        case .b(let err): return err
        }
      }
  }

  public func combineLatest<UpstreamB: Emitter>(
    _ otherB: UpstreamB
  ) -> some Emitter<(Output, UpstreamB.Output), Error> {
    Emitters
      .CombineLatestTwo(upstreamA: self, upstreamB: otherB)
      .mapFailure { error in
        switch error {
        case .a(let err): return err as any Error
        case .b(let err): return err as any Error
        }
      }
  }

  public func combineLatest<UpstreamB: Emitter>(
    _ otherB: UpstreamB
  ) -> some Emitter<(Output, UpstreamB.Output), Never> where Failure == Never,
    UpstreamB.Failure == Never
  {
    Emitters
      .CombineLatestTwo(upstreamA: self, upstreamB: otherB)
      .mapFailure { _ in
        fatalError("Failure == Never")
      }
  }
}

// MARK: - Source

private enum Source: CaseIterable {
  case a
  case b
}

// MARK: - Emitters.CombineLatestTwo

extension Emitters {

  public struct CombineLatestTwo<UpstreamA: Emitter, UpstreamB: Emitter>: Emitter {

    // MARK: Lifecycle

    public init(
      upstreamA: UpstreamA,
      upstreamB: UpstreamB
    ) {
      self.upstreamA = upstreamA
      self.upstreamB = upstreamB
    }

    // MARK: Public

    public typealias Output = (UpstreamA.Output, UpstreamB.Output)
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

    private final class IntermediateSub<Downstream: Subscriber>: Subscriber
      where Downstream.Input == (UpstreamA.Output, UpstreamB.Output), Downstream.Failure == Union2<
        UpstreamA.Failure,
        UpstreamB.Failure
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
      }

      func receive(emission: Emission<
        EmissionData<
          Source,
          Union2<UpstreamA.Output, UpstreamB.Output>,
          Union2<UpstreamA.Failure, UpstreamB.Failure>
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
            let output: (UpstreamA.Output, UpstreamB.Output)? = state.withLock { mutState in
              if mutState.allFinished {
                return nil
              }
              switch union {
              case .a(let a):
                mutState.lastA = a
              case .b(let b):
                mutState.lastB = b
              }
              if
                let a = mutState.lastA,
                let b = mutState.lastB
              {
                return (a, b)
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
        Union2<UpstreamA.Output, UpstreamB.Output>,
        Union2<UpstreamA.Failure, UpstreamB.Failure>
      >
      fileprivate typealias Failure = Never

      fileprivate let downstream: Downstream

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
            joinFailure: Union2<UpstreamA.Failure, UpstreamB.Failure>.a
          )
        )

        let dispB = upstreamB.subscribe(
          TransformProxy(
            downstream: EmissionDataProxy<
              Source,
              Union2<UpstreamA.Output, UpstreamB.Output>,
              Union2<UpstreamA.Failure, UpstreamB.Failure>,
              IntermediateSub
            >(
              metadata: Source.b,
              downstream: self
            ),
            joinOutput: Union2<UpstreamA.Output, UpstreamB.Output>.b,
            joinFailure: Union2<UpstreamA.Failure, UpstreamB.Failure>.b
          )
        )
        let disposable = AutoDisposable {
          dispA.dispose()
          dispB.dispose()
        }
        return disposable
      }

      // MARK: Private

      private let state = Locked<State>(.init())

    }
  }
}

// MARK: - Emitters.CombineLatestTwo + Sendable

extension Emitters.CombineLatestTwo: Sendable where UpstreamA: Sendable, UpstreamB: Sendable { }
