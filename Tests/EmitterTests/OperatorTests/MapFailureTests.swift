import Disposable
import Emitter
import XCTest

// MARK: - MapFailureTests

final class MapFailureTests: XCTestCase {

  struct OneError: Error {
    let msg: String
  }

  struct TwoError: Error {
    init(_ one: OneError) { self.msg = one.msg }
    let msg: String
  }

  struct ThreeError: Error, Equatable {
    init(msg: String) {
      self.msg = msg
    }

    init(_ two: TwoError) { self.msg = two.msg }
    let msg: String
  }

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_MapFailure() throws {
    var record: [String] = []
    var err: [ThreeError] = []
    var fin: [()] = []
    let source = PublishSubject<String, OneError>()

    source
      .map { $0.uppercased() }
      .mapFailure { TwoError($0) }
      .map { Array($0).map { "\($0)" } }
      .map { $0.joined(separator: "-") }
      .mapFailure {
        ThreeError($0)
      }
      .subscribe { output in
        record.append(output)
      } finished: {
        fin.append(())
      } failed: { error in
        err.append(error)
      }
      .stage(on: stage)

    source.emit(value: "somethingfun")
    source.emit(value: "ish")
    source.fail(.init(msg: "Failure"))
    source.emit(value: "off-the-end")
    source.finish()

    XCTAssertEqual(record, ["S-O-M-E-T-H-I-N-G-F-U-N", "I-S-H"])
    XCTAssertEqual(err, [ThreeError(msg: "Failure")])
    XCTAssertEqual(fin.count, 0)
  }

  func test_MapFailure_fatalError() throws {
    var record: [String] = []
    var fin: [()] = []
    let source = PublishSubject<String, OneError>()

    source
      .map { $0.uppercased() }
      .mapFailure { _ in fatalError() }
      .map { Array($0).map { "\($0)" } }
      .map { $0.joined(separator: "-") }
      .subscribe { output in
        record.append(output)
      } finished: {
        fin.append(())
      }
      .stage(on: stage)

    source.emit(value: "somethingfun")
    source.emit(value: "ish")
    source.finish()
    source.emit(value: "off-the-end")
    source.finish()

    XCTAssertEqual(record, ["S-O-M-E-T-H-I-N-G-F-U-N", "I-S-H"])
    XCTAssertEqual(fin.count, 1)
  }

}
