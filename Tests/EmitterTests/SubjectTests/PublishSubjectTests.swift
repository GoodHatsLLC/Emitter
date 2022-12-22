import Disposable
import Emitter
import XCTest

// MARK: - PublishSubjectTests

final class PublishSubjectTests: XCTestCase {

    var stage: DisposableStage!

    override func setUp() {
        stage = .init()
    }

    override func tearDown() {
        stage.dispose()
        stage = nil
    }

    func testPublishSubject_doesNotPublish_beforeAnySend() throws {
        var record: [String] = []
        let source: PublishSubject<String> = .init()
        source
            .subscribe { value in
                record.append(value)
            }
            .stage(on: stage)
        XCTAssertEqual(record.count, 0)
    }

    func testPublishSubject_doesNotPublish_toUnstagedSubscription() throws {
        var record: [String] = []
        let source: PublishSubject<String> = .init()
        _ = source
            .subscribe { value in
                record.append(value)
            }
        source.emit(.value("some value"))
        XCTAssertEqual(record.count, 0)
    }

    func testPublishSubject_doesNotReplaySend() throws {
        var record: [String] = []
        let source: PublishSubject<String> = .init()
        source.emit(.value("some value"))
        source
            .subscribe { value in
                record.append(value)
            }
            .stage(on: stage)
        XCTAssertEqual(record.count, 0)
    }

    func test_emission() throws {
        var record: [String] = []

        let source: PublishSubject<String> = .init()

        source
            .subscribe { value in
                record.append(value)
            }
            .stage(on: stage)

        source.emit(.value("a"))
        source.emit(.value("b"))
        source.emit(.value("c"))

        XCTAssertEqual(["a", "b", "c"], record)
    }

    func test_flatMap() throws {
        var record: [String] = []

        let sourceA: PublishSubject<Int> = .init()
        let sourceB: PublishSubject<String> = .init()

        sourceA
            .flatMapLatest { value in
                sourceB.map { str in
                    "\(str):\(value)"
                }
            }
            .subscribe { value in
                record.append(value)
            }
            .stage(on: stage)

        sourceA.emit(.value(1))
        sourceA.emit(.value(2))
        sourceB.emit(.value("a"))
        sourceB.emit(.value("b"))
        sourceA.emit(.value(3))
        sourceA.emit(.value(0))
        sourceB.emit(.value("c"))

        XCTAssertEqual(["a:2", "b:2", "c:0"], record)
    }

    func testPublishSubject_publishesInOrder_toSubscription() throws {
        var record: [String] = []
        let source: PublishSubject<String> = .init()
        source
            .subscribe { value in
                record.append(value)
            }
            .stage(on: stage)
        XCTAssertEqual(record.count, 0)

        let entries = ["a", "b", "c", "d", "e"]

        for entry in entries {
            source.emit(.value(entry))
        }

        XCTAssertEqual(entries, record)
    }

}
