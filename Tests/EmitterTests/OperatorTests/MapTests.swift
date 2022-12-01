import Disposable
import Emitter
import XCTest

// MARK: - MapTests

@MainActor
final class MapTests: XCTestCase {

    var stage: DisposalStage!

    override func setUp() async throws {
        stage = .init()
    }

    override func tearDown() async throws {
        stage.dispose()
        stage = nil
    }

    func testStream_compactMap() throws {
        var record: [String] = []
        let source = PublishSubject<String>()

        source
            .map { "\($0)-and-stuff" }
            .subscribe { output in
                record.append(output)
            }
            .stage(on: stage)

        XCTAssertEqual(record.count, 0)

        let entries: [String] = ["a", "b", "c", "d", "e"]

        for entry in entries {
            source.emit(.value(entry))
        }

        XCTAssertEqual(["a-and-stuff", "b-and-stuff", "c-and-stuff", "d-and-stuff", "e-and-stuff"], record)
    }

    func test_dispose_releasesResources() throws {
        var record: [Int] = []
        weak var weakSourceA: PublishSubject<Int>?

        autoreleasepool {
            autoreleasepool {
                let sourceA: PublishSubject<Int> = .init()
                weakSourceA = sourceA

                sourceA
                    .map { $0 + 1 }
                    .subscribe { value in
                        record.append(value)
                    }
                    .stage(on: stage)

                sourceA.emit(.value(1))
                sourceA.emit(.value(2))
                sourceA.emit(.value(3))
                sourceA.emit(.value(4))
                sourceA.emit(.value(5))
            }
            XCTAssertNotNil(weakSourceA)
            stage.dispose()
            stage = DisposalStage()
        }
        XCTAssertNil(weakSourceA)
    }

}
