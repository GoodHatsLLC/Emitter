import Disposable
import Emitter
import XCTest

// MARK: - ReplaceFailureTests

final class ReplaceFailureTests: XCTestCase {

  struct TestError: Error { }

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_MapFailure_fatalError() throws {
    var record: [String] = []
    var fin: [()] = []
    let source1 = PublishSubject<String, TestError>()
    let source2 = PublishSubject<String, TestError>()

    source1
      .union(source2)
      .map { switch $0 {
      case .a(let str): return str
      case .b(let str): return str
      }}
      .map { $0.uppercased() }
      .map { Optional($0) }
      .replaceFailures(with: nil)
      .compact()
      .map { Array($0).map { "\($0)" } }
      .map { $0.joined(separator: "-") }
      .subscribe { output in
        record.append(output)
      } finished: {
        fin.append(())
      }
      .stage(on: stage)

    source1.emit(value: "somethingfun")
    source1.fail(TestError())
    source2.emit(value: "off-the-end")

    XCTAssertEqual(record, ["S-O-M-E-T-H-I-N-G-F-U-N"])
    XCTAssertEqual(fin.count, 0)
  }

}
