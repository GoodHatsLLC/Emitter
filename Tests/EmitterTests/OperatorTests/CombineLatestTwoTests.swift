import Disposable
import Emitter
import XCTest

// MARK: - CombineLatestTwoTests

final class CombineLatestTwoTests: XCTestCase {

  struct CombFail: Error { }

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_combineLatest() throws {
    let record: Unchecked<[(Int, String)]> = .init([])
    let sourceA: PublishSubject<Int, Never> = .init()
    let sourceB: PublishSubject<String, Never> = .init()

    sourceA
      .combineLatest(sourceB)
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    sourceA.emit(value: 1)
    sourceA.emit(value: 2)
    sourceB.emit(value: "a")
    sourceA.emit(value: 3)
    sourceB.emit(value: "b")
    sourceB.emit(value: "c")

    let intended = [
      (2, "a"),
      (3, "a"),
      (3, "b"),
      (3, "c"),
    ]

    XCTAssertEqual(
      intended.map(\.0),
      record.value.map(\.0)
    )
    XCTAssertEqual(
      intended.map(\.1),
      record.value.map(\.1)
    )
  }

  func test_combineLatest_finish() throws {
    let record: Unchecked<[(Int, String)]> = .init([])
    let sourceA: PublishSubject<Int, Never> = .init()
    let sourceB: PublishSubject<String, Never> = .init()

    sourceA
      .combineLatest(sourceB)
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    sourceA.emit(value: 1)
    sourceA.emit(value: 2)
    sourceB.emit(value: "a")
    sourceA.finish()
    sourceA.emit(value: 3)
    sourceB.emit(value: "b")
    sourceB.finish()
    sourceB.emit(value: "c")

    let intended = [
      (2, "a"),
      (2, "b"),
    ]

    XCTAssertEqual(
      intended.map(\.0),
      record.value.map(\.0)
    )
    XCTAssertEqual(
      intended.map(\.1),
      record.value.map(\.1)
    )
  }

  func test_combineLatest_fail() throws {
    let record: Unchecked<[(Int, String)]> = .init([])
    let sourceA: PublishSubject<Int, CombFail> = .init()
    let sourceB: PublishSubject<String, Error> = .init()

    sourceA
      .combineLatest(sourceB)
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    sourceA.emit(value: 1)
    sourceA.emit(value: 2)
    sourceB.emit(value: "a")
    sourceA.fail(CombFail())
    sourceA.emit(value: 3)
    sourceB.emit(value: "b")
    sourceB.finish()
    sourceB.emit(value: "c")

    let intended = [
      (2, "a"),
    ]

    XCTAssertEqual(
      intended.map(\.0),
      record.value.map(\.0)
    )
    XCTAssertEqual(
      intended.map(\.1),
      record.value.map(\.1)
    )
  }
}
