import Disposable
import Emitter
import XCTest

// MARK: - CompactMapTests

final class CompactMapTests: XCTestCase {

  var stage: DisposableStage!

  override func setUp() {
    stage = .init()
  }

  override func tearDown() {
    stage.dispose()
    stage = nil
  }

  func testStream_compactMap() throws {
    var record: [String?] = []
    let source = PublishSubject<String?>()

    source
      .compactMap { $0 }
      .subscribe { output in
        record.append(output)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 0)

    let entries: [String?] = [nil, "a", nil, nil, "d", "e"]

    for entry in entries {
      source.emit(.value(entry))
    }

    XCTAssertEqual(["a", "d", "e"], record)
  }

  func test_dispose_releasesResources() throws {
    var record: [Int] = []
    weak var weakSourceA: PublishSubject<Int?>?

    autoreleasepool {
      autoreleasepool {
        let sourceA: PublishSubject<Int?> = .init()
        weakSourceA = sourceA

        sourceA
          .compactMap { $0 }
          .subscribe { value in
            record.append(value)
          }
          .stage(on: stage)

        sourceA.emit(.value(1))
        sourceA.emit(.value(nil))
        sourceA.emit(.value(2))
        sourceA.emit(.value(nil))
        sourceA.emit(.value(3))
      }
      XCTAssertNotNil(weakSourceA)
      stage.dispose()
      stage = DisposableStage()
    }
    XCTAssertNil(weakSourceA)
  }

}
