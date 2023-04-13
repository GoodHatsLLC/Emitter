import Disposable
import Emitter
import XCTest

// MARK: - TryMapTests

final class TryMapTests: XCTestCase {

  struct UppercaseFailure: Error { }

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func testStream_compactMap() throws {
    let record: Unchecked<[String]> = .init([])
    let source = PublishSubject<String, Never>()

    source
      .map {
        if $0.lowercased() != $0 {
          throw UppercaseFailure()
        }
        return "\($0)-and-stuff"
      }
      .subscribe { output in
        record.value.append(output)
      } failed: { error in
        XCTAssert(error is UppercaseFailure)
      }
      .stage(on: stage)

    XCTAssertEqual(record.value.count, 0)

    let entries: [String] = ["a", "b", "C", "d", "e"]

    for entry in entries {
      source.emit(value: entry)
    }

    XCTAssertEqual(
      ["a-and-stuff", "b-and-stuff"],
      record.value
    )
  }

}
