import Disposable
import Emitter
import XCTest

// MARK: - MapTests

final class MapTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func testStream_compactMap() throws {
    let record: Unchecked<[String]> = .init([])
    let source = PublishSubject<String>()

    source
      .map { "\($0)-and-stuff" }
      .subscribe { output in
        record.value.append(output)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    let entries: [String] = ["a", "b", "c", "d", "e"]

    for entry in entries {
      source.emit(value: entry)
    }

    XCTAssertEqual(
      ["a-and-stuff", "b-and-stuff", "c-and-stuff", "d-and-stuff", "e-and-stuff"],
      record.value
    )
  }

  func test_dispose_releasesResources() throws {
    var record: [Int] = []
    weak var weakSourceA: PublishSubject<Int>?

    ({
      ({
        let sourceA: PublishSubject<Int> = .init()
        weakSourceA = sourceA

        sourceA
          .map { $0 + 1 }
          .subscribe { value in
            record.append(value)
          }
          .stage(on: stage)

        sourceA.emit(value: 1)
        sourceA.emit(value: 2)
        sourceA.emit(value: 3)
        sourceA.emit(value: 4)
        sourceA.emit(value: 5)
      })()
      XCTAssertNotNil(weakSourceA)
      stage.dispose()
    })()
    XCTAssertNil(weakSourceA)
  }

}
