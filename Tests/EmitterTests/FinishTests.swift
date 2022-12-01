import Disposable
import Emitter
import XCTest

// MARK: - FinishTests

@MainActor
final class FinishTests: XCTestCase {

    var source: PublishSubject<String>!
    var stage: DisposalStage!

    override func setUp() async throws {
        source = .init()
        stage = .init()
    }

    override func tearDown() async throws {
        source = nil
        stage.dispose()
        stage = nil
    }

    func testStream_valueDoesNotFinish() throws {
        var record: [String] = []
        var didComplete = false
        var failure: Error? = nil
        source
            .subscribe(
                value: { value in
                    record.append(value)
                },
                finished: {
                    didComplete = true
                },
                failed: { error in
                    failure = error
                }
            )
            .stage(on: stage)
        XCTAssertEqual(record.count, 0)

        let entries = ["a", "b", "c", "d", "e"]

        for entry in entries {
            source.emit(.value(entry))
        }

        XCTAssertFalse(didComplete)
        XCTAssertNil(failure)
    }

    func testStream_failureFinishes() throws {
        var record: [String] = []
        var didComplete = false
        var failure: Error? = nil
        source
            .subscribe(
                value: { value in
                    record.append(value)
                },
                finished: {
                    didComplete = true
                },
                failed: { error in
                    failure = error
                }
            )
            .stage(on: stage)
        XCTAssertEqual(record.count, 0)

        let entries = ["a", "b", "c", "d", "e"]

        for entry in entries {
            if entry == "c" {
                source.emit(.failed(Failure.sourceFail))
            } else {
                source.emit(.value(entry))
            }
        }

        XCTAssertEqual(["a", "b"], record)
        XCTAssertFalse(didComplete)
        XCTAssert((failure as? Failure) == .sourceFail)
    }

    func testStream_finishCompletes() throws {
        var record: [String] = []
        var didComplete = false

        source
            .subscribe(
                value: { value in
                    record.append(value)
                },
                finished: {
                    didComplete = true
                },
                failed: { _ in
                }
            )
            .stage(on: stage)
        XCTAssertEqual(record.count, 0)

        let entries = ["a", "b", "c", "d", "e"]

        for entry in entries {
            if entry == "c" {
                source.emit(.finished)
            } else {
                source.emit(.value(entry))
            }
        }

        XCTAssertEqual(["a", "b"], record)
        XCTAssert(didComplete)
    }

}

// MARK: FinishTests.Failure

extension FinishTests {
    enum Failure: Error {
        case sourceFail
    }
}
