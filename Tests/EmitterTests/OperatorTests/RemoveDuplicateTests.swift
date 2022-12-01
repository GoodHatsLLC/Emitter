import Disposable
import Emitter
import XCTest

// MARK: - RemoveDuplicatesTests

@MainActor
final class RemoveDuplicatesTests: XCTestCase {

    var stage: DisposalStage!

    override func setUp() async throws {
        stage = .init()
    }

    override func tearDown() async throws {
        stage.dispose()
        stage = nil
    }

    func testStream_removeDuplicates() {
        var record: [String] = []
        let source = PublishSubject<String>()

        source
            .removeDuplicates()
            .subscribe { output in
                record.append(output)
            }
            .stage(on: stage)

        XCTAssertEqual(record.count, 0)

        let entries: [String] = ["a", "a", "d", "e", "e"]

        for entry in entries {
            source.emit(.value(entry))
        }

        XCTAssertEqual(["a", "d", "e"], record)
    }

    func test_dispose_releasesResources() throws {
        var record: [Int] = []
        weak var weakSourceA: PublishSubject<Int>?

        autoreleasepool {
            autoreleasepool {
                let sourceA: PublishSubject<Int> = .init()
                weakSourceA = sourceA

                sourceA
                    .removeDuplicates()
                    .subscribe { value in
                        record.append(value)
                    }
                    .stage(on: stage)

                sourceA.emit(.value(1))
                sourceA.emit(.value(2))
                sourceA.emit(.value(2))
                sourceA.emit(.value(3))
                sourceA.emit(.value(3))
                sourceA.emit(.value(1))
            }
            XCTAssertNotNil(weakSourceA)
            stage.dispose()
            stage = DisposalStage()
        }
        XCTAssertNil(weakSourceA)
        XCTAssertEqual([1, 2, 3, 1], record)
    }

}
