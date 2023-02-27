import Disposable
import Emitter
import XCTest

// MARK: - RemoveDuplicatesTests

final class RemoveDuplicatesTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() {}

  override func tearDown() {
    stage.reset()
  }

  func testStream_removeDuplicates() {
    let record: Unchecked<[String]> = .init([])
    let source = PublishSubject<String>()

    source
      .removeDuplicates()
      .subscribe { output in
        record.value.append(output)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    let entries: [String] = ["a", "a", "d", "e", "e"]

    for entry in entries {
      source.emit(.value(entry))
    }

    XCTAssertEqual(["a", "d", "e"], record.value)
  }

  func test_dispose_releasesResources() throws {
    let record: Unchecked<[Int]> = .init([])
    weak var weakSourceA: PublishSubject<Int>?

    ({
      ({
        let sourceA: PublishSubject<Int> = .init()
        weakSourceA = sourceA

        sourceA
          .removeDuplicates()
          .subscribe { value in
            record.value.append(value)
          }
          .stage(on: stage)

        sourceA.emit(.value(1))
        sourceA.emit(.value(2))
        sourceA.emit(.value(2))
        sourceA.emit(.value(3))
        sourceA.emit(.value(3))
        sourceA.emit(.value(1))
      })()
      XCTAssertNotNil(weakSourceA)
      stage.dispose()
    })()
    XCTAssertNil(weakSourceA)
    XCTAssertEqual([1, 2, 3, 1], record.value)
  }

}
