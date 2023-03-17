import Disposable
import Emitter
import XCTest

// MARK: - PublishSubjectTests

final class PublishSubjectTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func testPublishSubject_doesNotPublish_beforeAnySend() throws {
    let record: Unchecked<[String]> = .init([])
    let source: PublishSubject<String> = .init()
    source
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)
    XCTAssertEqual(record.value.count, 0)
  }

  func testPublishSubject_doesNotPublish_toUnstagedSubscription() throws {
    let record: Unchecked<[String]> = .init([])
    let source: PublishSubject<String> = .init()
    _ = source
      .subscribe { value in
        record.value.append(value)
      }
    source.emit(value: "some value")
    XCTAssertEqual(record.value.count, 0)
  }

  func testPublishSubject_doesNotReplaySend() throws {
    let record: Unchecked<[String]> = .init([])
    let source: PublishSubject<String> = .init()
    source.emit(value: "some value")
    source
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)
    XCTAssertEqual(record.value.count, 0)
  }

  func test_emission() throws {
    let record: Unchecked<[String]> = .init([])

    let source: PublishSubject<String> = .init()

    source
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)

    source.emit(value: "a")
    source.emit(value: "b")
    source.emit(value: "c")

    XCTAssertEqual(["a", "b", "c"], record.value)
  }

  func test_flatMap() throws {
    let record: Unchecked<[String]> = .init([])

    let sourceA: PublishSubject<Int> = .init()
    let sourceB: PublishSubject<String> = .init()

    sourceA
      .flatMapLatest { value in
        sourceB.map { str in
          "\(str):\(value)"
        }
      }
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)

    sourceA.emit(value: 1)
    sourceA.emit(value: 2)
    sourceB.emit(value: "a")
    sourceB.emit(value: "b")
    sourceA.emit(value: 3)
    sourceA.emit(value: 0)
    sourceB.emit(value: "c")

    XCTAssertEqual(["a:2", "b:2", "c:0"], record.value)
  }

  func testPublishSubject_publishesInOrder_toSubscription() throws {
    let record: Unchecked<[String]> = .init([])
    let source: PublishSubject<String> = .init()
    source
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)
    XCTAssertEqual(record.value.count, 0)

    let entries = ["a", "b", "c", "d", "e"]

    for entry in entries {
      source.emit(value: entry)
    }

    XCTAssertEqual(entries, record.value)
  }

}
