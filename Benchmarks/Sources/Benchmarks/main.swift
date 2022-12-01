import CollectionsBenchmark
import Emitter

@MainActor
struct Test {

    func run() async {
        var benchmark = Benchmark(title: "Emitter")

        benchmark.addSimple(
            title: "map",
            input: [Int].self
        ) { input in
            let sourceA: PublishSubject<Int> = .init()
            let stage = DisposalStage()
            sourceA
                .map { $0 + 1 }
                .subscribe { value in
                    blackHole(value)
                }
                .stage(on: stage)

            for value in input {
                sourceA.emit(.value(value))
            }
        }

        benchmark.addSimple(
            title: "compactMap",
            input: [Int].self
        ) { input in
            let sourceA: PublishSubject<Int> = .init()
            let stage = DisposalStage()
            var shouldNil = false
            sourceA
                .compactMap {
                    shouldNil = !shouldNil
                    return shouldNil ? nil : $0
                }
                .subscribe { value in
                    blackHole(value)
                }
                .stage(on: stage)

            for value in input {
                sourceA.emit(.value(value))
            }
        }

        benchmark.addSimple(
            title: "flatMapLatest",
            input: [Int].self
        ) { input in
            let stage = DisposalStage()
            let sourceA: PublishSubject<Int> = .init()
            let sourceB: ValueSubject<Int> = .init(1)

            sourceA
                .flatMapLatest { aValue in
                    sourceB.map { _ in aValue }
                }
                .subscribe { value in
                    blackHole(value)
                }
                .stage(on: stage)

            for value in input {
                sourceA.emit(.value(value))
            }
        }

        benchmark.addSimple(
            title: "combineLatest",
            input: [Int].self
        ) { input in
            let stage = DisposalStage()
            let sourceA: PublishSubject<Int> = .init()
            let sourceB: ValueSubject<Int> = .init(1)

            sourceA
                .combineLatest(sourceB)
                .subscribe { value in
                    blackHole(value)
                }
                .stage(on: stage)

            for value in input {
                sourceA.emit(.value(value))
            }
        }

        benchmark.addSimple(
            title: "merge",
            input: [Int].self
        ) { input in
            let stage = DisposalStage()
            let sourceA: PublishSubject<Int> = .init()
            let sourceB: ValueSubject<Int> = .init(1)

            sourceA
                .merge(sourceB)
                .subscribe { value in
                    blackHole(value)
                }
                .stage(on: stage)

            for value in input {
                sourceA.emit(.value(value))
            }
        }

        benchmark.addSimple(
            title: "removeDuplicates",
            input: [Int].self
        ) { input in
            let stage = DisposalStage()
            let sourceA: PublishSubject<Int> = .init()

            sourceA
                .removeDuplicates()
                .subscribe { value in
                    blackHole(value)
                }
                .stage(on: stage)

            var last: Int?
            for value in input {
                sourceA.emit(.value(last ?? value))
                last = last == nil ? value : nil
            }
        }

        benchmark.main()
    }
}

await Test().run()
