import Disposable
import Emitter
import XCTest

// MARK: - CombineLatestThreeTests

final class CombineLatestThreeTests: XCTestCase {

  struct CombFail: Error { }

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_combineLatest2() throws {
    let record: Unchecked<[(Int, String, Bool)]> = .init([])
    let sourceA: PublishSubject<Int, Never> = .init()
    let sourceB: PublishSubject<String, Never> = .init()
    let sourceC: PublishSubject<Bool, Never> = .init()

    sourceA
      .combineLatest(sourceB, sourceC)
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    sourceA.emit(value: 1)
    sourceA.emit(value: 2)
    sourceB.emit(value: "a")
    sourceC.emit(value: false)
    sourceA.emit(value: 3)
    sourceC.emit(value: true)
    sourceB.emit(value: "b")
    sourceB.emit(value: "c")

    let intended = [
      (2, "a", false),
      (3, "a", false),
      (3, "a", true),
      (3, "b", true),
      (3, "c", true),
    ]

    XCTAssertEqual(
      intended.map(\.0),
      record.value.map(\.0)
    )
    XCTAssertEqual(
      intended.map(\.1),
      record.value.map(\.1)
    )
    XCTAssertEqual(
      intended.map(\.2),
      record.value.map(\.2)
    )
  }

  func test_combineLatest2_fail() throws {
    let record: Unchecked<[(Int, String, Bool)]> = .init([])
    let sourceA: PublishSubject<Int, Error> = .init()
    let sourceB: PublishSubject<String, Error> = .init()
    let sourceC: PublishSubject<Bool, Error> = .init()

    sourceA
      .combineLatest(sourceB, sourceC)
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    sourceA.emit(value: 1)
    sourceA.emit(value: 2)
    sourceB.emit(value: "a")
    sourceC.emit(value: false)
    sourceC.fail(CombFail())
    sourceA.emit(value: 3)
    sourceC.emit(value: true)
    sourceB.emit(value: "b")
    sourceB.emit(value: "c")

    let intended = [
      (2, "a", false),
    ]

    XCTAssertEqual(
      intended.map(\.0),
      record.value.map(\.0)
    )
    XCTAssertEqual(
      intended.map(\.1),
      record.value.map(\.1)
    )
    XCTAssertEqual(
      intended.map(\.2),
      record.value.map(\.2)
    )
  }

  func test_combineLatest2_finish() throws {
    let record: Unchecked<[(Int, String, Bool)]> = .init([])
    let sourceA: PublishSubject<Int, Never> = .init()
    let sourceB: PublishSubject<String, Never> = .init()
    let sourceC: PublishSubject<Bool, Never> = .init()

    sourceA
      .combineLatest(sourceB, sourceC)
      .subscribe { value in
        record.value.append(value)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    sourceA.emit(value: 1)
    sourceA.emit(value: 2)
    sourceB.emit(value: "a")
    sourceB.finish()
    sourceC.emit(value: false)
    sourceC.finish()
    sourceA.emit(value: 3)
    sourceA.emit(value: 2)
    sourceA.emit(value: 1)
    sourceA.finish()
    sourceA.emit(value: 1)
    sourceB.emit(value: "c")
    sourceC.emit(value: true)

    let intended = [
      (2, "a", false),
      (3, "a", false),
      (2, "a", false),
      (1, "a", false),
    ]

    XCTAssertEqual(
      intended.map(\.0),
      record.value.map(\.0)
    )
    XCTAssertEqual(
      intended.map(\.1),
      record.value.map(\.1)
    )
    XCTAssertEqual(
      intended.map(\.2),
      record.value.map(\.2)
    )
  }

}
