import Disposable
import Emitter
import XCTest

// MARK: - CombineLatestTests

@MainActor
final class CombineLatestTests: XCTestCase {

    var stage: DisposalStage!

    override func setUp() async throws {
        stage = .init()
    }

    override func tearDown() async throws {
        stage.dispose()
        stage = nil
    }

    func testStream_combineLatest() throws {
        var record: [Tuple.Size2<Int, String>] = []
        let sourceA: PublishSubject<Int> = .init()
        let sourceB: PublishSubject<String> = .init()

        sourceA
            .combineLatest(sourceB)
            .subscribe { value in
                record.append(value)
            }
            .stage(on: stage)

        XCTAssertEqual(record.count, 0)

        sourceA.emit(.value(1))
        sourceA.emit(.value(2))
        sourceB.emit(.value("a"))
        sourceA.emit(.value(3))
        sourceB.emit(.value("b"))
        sourceB.emit(.value("c"))

        let intended = [
            Tuple.create(2, "a"),
            Tuple.create(3, "a"),
            Tuple.create(3, "b"),
            Tuple.create(3, "c"),
        ]

        XCTAssertEqual(
            intended,
            record
        )
    }

    func test_dispose_releasesResources() throws {
        var record: [Tuple.Size2<Int, String>] = []
        weak var weakSourceA: PublishSubject<Int>? = nil
        weak var weakSourceB: ValueSubject<String>? = nil

        autoreleasepool {
            autoreleasepool {
                let sourceA: PublishSubject<Int> = .init()
                let sourceB: ValueSubject<String> = .init("Hi")
                weakSourceA = sourceA
                weakSourceB = sourceB

                sourceA
                    .combineLatest(sourceB)
                    .subscribe { value in
                        record.append(value)
                    }
                    .stage(on: stage)

                sourceA.emit(.value(1))
                sourceA.emit(.value(2))
                sourceB.emit(.value("a"))
                sourceA.emit(.value(3))
                sourceB.emit(.value("b"))
                sourceB.emit(.value("c"))
            }
            XCTAssertNotNil(weakSourceA)
            XCTAssertNotNil(weakSourceB)
            stage.dispose()
            stage = DisposalStage()
        }
        XCTAssertNil(weakSourceA)
        XCTAssertNil(weakSourceB)
    }

}
