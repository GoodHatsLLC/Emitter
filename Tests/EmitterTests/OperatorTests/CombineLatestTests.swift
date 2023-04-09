import Disposable
import Emitter
import XCTest

// MARK: - CombineLatestTests

final class CombineLatestTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func testStream_combineLatest() throws {
    let record: Unchecked<[Tuple.Size2<Int, String>]> = .init([])
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
      Tuple.create(2, "a"),
      Tuple.create(3, "a"),
      Tuple.create(3, "b"),
      Tuple.create(3, "c"),
    ]

    XCTAssertEqual(
      intended,
      record.value
    )
  }

  func test_dispose_releasesResources() throws {
    let record: Unchecked<[Tuple.Size2<Int, String>]> = .init([])
    weak var weakSourceA: PublishSubject<Int, Never>?
    weak var weakSourceB: ValueSubject<String, Never>?

    ({
      ({
        let sourceA: PublishSubject<Int, Never> = .init()
        let sourceB: ValueSubject<String, Never> = .init("Hi")
        weakSourceA = sourceA
        weakSourceB = sourceB

        sourceA
          .combineLatest(sourceB)
          .subscribe { value in
            record.value.append(value)
          }
          .stage(on: stage)

        sourceA.emit(value: 1)
        sourceA.emit(value: 2)
        sourceB.emit(value: "a")
        sourceA.emit(value: 3)
        sourceB.emit(value: "b")
        sourceB.emit(value: "c")
      })()
      XCTAssertNotNil(weakSourceA)
      XCTAssertNotNil(weakSourceB)
      stage.dispose()
    })()
    XCTAssertNil(weakSourceA)
    XCTAssertNil(weakSourceB)
  }

}
