import Disposable
import Emitter
import XCTest

// MARK: - MergeTests

@MainActor
final class MergeTests: XCTestCase {

    var stage: DisposalStage!

    override func setUp() async throws {
        stage = .init()
    }

    override func tearDown() async throws {
        stage.dispose()
        stage = nil
    }

    func testStream_merge() throws {
        var record: [Int] = []
        let sourceA: PublishSubject<Int> = .init()
        let sourceB: PublishSubject<Int> = .init()

        sourceA
            .merge(sourceB)
            .subscribe { value in
                record.append(value)
            }
            .stage(on: stage)

        XCTAssertEqual(record.count, 0)

        sourceA.emit(.value(1))
        sourceB.emit(.value(-1))
        sourceA.emit(.value(2))
        sourceB.emit(.value(-2))
        sourceA.emit(.value(3))
        sourceB.emit(.value(-3))

        XCTAssertEqual([1, -1, 2, -2, 3, -3], record)
    }

    func test_dispose_releasesResources() throws {
        var record: [String] = []
        weak var weakSourceA: PublishSubject<Int>?
        weak var weakSourceB: PublishSubject<String>?

        autoreleasepool {
            autoreleasepool {
                let sourceA: PublishSubject<Int> = .init()
                let sourceB: PublishSubject<String> = .init()
                weakSourceA = sourceA
                weakSourceB = sourceB

                sourceA
                    .map { "\($0)" }
                    .merge(sourceB)
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

        XCTAssertEqual(["1", "2", "a", "3", "b", "c"], record)
    }

}
