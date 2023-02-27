import Disposable
import Emitter
import XCTest

// MARK: - FilterTests

final class FilterTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() {}

  override func tearDown() {
    stage.reset()
  }

  func testStream_compactMap() throws {
    var record: [String] = []
    let source = PublishSubject<String>()

    source
      .filter { $0 != "INVALID" }
      .subscribe { output in
        record.append(output)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 0)

    let entries: [String] = ["INVALID", "a", "INVALID", "INVALID", "d", "e"]

    for entry in entries {
      source.emit(.value(entry))
    }

    XCTAssertEqual(["a", "d", "e"], record)
  }

  func test_dispose_releasesResources() throws {
    var record: [Int] = []
    weak var weakSourceA: PublishSubject<Int>?

    ({
      ({
        let sourceA: PublishSubject<Int> = .init()
        weakSourceA = sourceA

        sourceA
          .filter { $0 != 99 }
          .subscribe { value in
            record.append(value)
          }
          .stage(on: stage)

        sourceA.emit(.value(1))
        sourceA.emit(.value(99))
        sourceA.emit(.value(2))
        sourceA.emit(.value(99))
        sourceA.emit(.value(3))
      })()
      XCTAssertNotNil(weakSourceA)
      stage.dispose()
    })()
    XCTAssertNil(weakSourceA)
  }

}
