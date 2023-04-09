import Disposable
import Emitter
import XCTest

// MARK: - WithSuffixTests

final class WithSuffixTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_suffix() throws {
    let record: Unchecked<[String]> = .init([])
    let source = PublishSubject<String, Never>()
    let suffixed = source
      .withSuffix("z", "z")
      .withSuffix(["0", "1", "2", "3"])

    suffixed
      .subscribe { output in
        record.value.append(output)
      }
      .stage(on: stage)

    let entries: [String] = ["a", "b", "c", "d", "e"]

    for entry in entries {
      source.emit(value: entry)
    }
    XCTAssertEqual(
      ["a", "b", "c", "d", "e"],
      record.value
    )
    source.finish()
    source.emit(value: "PAST-END")

    XCTAssertEqual(
      ["a", "b", "c", "d", "e", "z", "z", "0", "1", "2", "3"],
      record.value
    )
  }

}
