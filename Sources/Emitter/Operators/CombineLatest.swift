import Disposable
import EmitterInterface

extension Emitter {
    public func combineLatest<Other: Emitter>(_ other: Other) -> some Emitter<Tuple.Size2<Output, Other.Output>> {
        CombineLatest(upstreamA: self, upstreamB: other)
    }
}

// MARK: - CombineLatest

@MainActor
struct CombineLatest<OutputA: Sendable, OutputB: Sendable>: Emitter {

    init<UpstreamA: Emitter, UpstreamB: Emitter>(
        upstreamA: UpstreamA,
        upstreamB: UpstreamB
    ) where UpstreamA.Output == OutputA, UpstreamB.Output == OutputB {
        self.upstreamA = upstreamA
        self.upstreamB = upstreamB
    }

    typealias Output = Tuple.Size2<OutputA, OutputB>

    @MainActor
    final class Ref<V> {
        init(_ value: V) {
            self.value = value
        }

        var value: V
    }

    @MainActor
    struct Sub<Downstream: Subscriber>: Subscriber
        where Downstream.Value == Output {
        init(downstream: Downstream) {
            self.downstream = downstream
        }

        enum Input {
            case a(OutputA)
            case b(OutputB)
        }

        let downstream: Downstream

        let lastA = Ref<OutputA?>(nil)
        let lastB = Ref<OutputB?>(nil)

        func receive(emission: Emission<Input>) {
            switch emission {
            case .value(let value):
                switch value {
                case .a(let aValue):
                    lastA.value = aValue
                case .b(let bValue):
                    lastB.value = bValue
                }
                if let a = lastA.value, let b = lastB.value {
                    downstream
                        .receive(emission: .value(Tuple.create(a, b)))
                }
            case .finished:
                downstream
                    .receive(emission: .finished)
            case .failed(let error):
                downstream
                    .receive(emission: .failed(error))
            }
        }

    }

    let upstreamA: any Emitter<OutputA>
    let upstreamB: any Emitter<OutputB>

    func subscribe<S: Subscriber>(_ subscriber: S)
        -> AnyDisposable
        where S.Value == Output {
        let stage = DisposalStage()
        let sub = Sub(downstream: subscriber)
        let mapA = Map.Sub(downstream: sub) { value in
            .a(value)
        }
        let mapB = Map.Sub(downstream: sub) { value in
            .b(value)
        }
        upstreamA
            .subscribe(mapA)
            .stage(on: stage)
        upstreamB
            .subscribe(mapB)
            .stage(on: stage)
        return stage
            .erase()
    }

}
