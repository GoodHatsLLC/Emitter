import Disposable

extension Emitter {
  public func merge<Other: Emitter>(
    _ other: Other
  ) -> some Emitter<Output, Failure> where Other.Output == Output, Other.Failure == Failure {
    Emitters.MergeTwo(upstreamA: self, upstreamB: other)
  }
}

// MARK: - Source

private enum Source: CaseIterable {
  case a
  case b
}

// MARK: - Emitters.MergeTwo

extension Emitters {

  public struct MergeTwo<UpstreamA: Emitter, UpstreamB: Emitter>: Emitter
    where UpstreamA.Output == UpstreamB.Output, UpstreamA.Failure == UpstreamB.Failure
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

    public typealias Output = UpstreamA.Output
    public typealias Failure = UpstreamA.Failure

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
      where Downstream.Input == UpstreamA.Output, Downstream.Failure == UpstreamA.Failure
    {

      // MARK: Lifecycle

      fileprivate init(downstream: Downstream) {
        self.downstream = downstream
      }

      // MARK: Internal

      func receive(emission: Emission<
        EmissionData<Source, UpstreamA.Output, UpstreamA.Failure>,
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

      fileprivate typealias Input = EmissionData<Source, UpstreamA.Output, UpstreamA.Failure>
      fileprivate typealias Failure = Never

      fileprivate let downstream: Downstream

      fileprivate func subscribe(
        upstreamA: UpstreamA,
        upstreamB: UpstreamB
      )
        -> AutoDisposable
      {
        let dispA = upstreamA.subscribe(
          EmissionDataProxy(
            metadata: Source.a,
            downstream: self
          )
        )

        let dispB = upstreamB.subscribe(
          EmissionDataProxy<Source, UpstreamA.Output, UpstreamA.Failure, IntermediateSub>(
            metadata: Source.b,
            downstream: self
          )
        )

        let disposable = AutoDisposable {
          dispA.dispose()
          dispB.dispose()
        }
        return disposable
      }

      // MARK: Private

      private let state = Locked<(finishedSources: Set<Source>, finished: Bool)>(([], false))

    }
  }
}

// MARK: - Emitters.MergeTwo + Sendable

extension Emitters.MergeTwo: Sendable where UpstreamA: Sendable, UpstreamB: Sendable { }
