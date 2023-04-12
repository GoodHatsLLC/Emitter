import Disposable
import Emitter
import XCTest

// MARK: - WithFailureTypeTests

final class WithFailureTypeTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  struct FailureType: Error {}

  enum Emissions<V, F: Error> {
    case value(String)
    case finished
    case failure
  }

  func test_failureType_fromNever() throws {

    var emissions: [Emissions<String, FailureType>] = []

    let source = PublishSubject<String, Never>()
    source
      .withFailure(type: FailureType.self)
      .subscribe { value in
        emissions.append(.value(value))
      } finished: {
        emissions.append(.finished)
      } failed: { error in
        emissions.append(.failure)
      }
      .stage(on: stage)

    source.emit(value: "hi")
    source.emit(value: ".")
    source.emit(value: "how")
    source.emit(value: "are")
    source.emit(value: "you")
    source.emit(value: "?")
    source.finish()

    let joined = emissions.compactMap { emission in
      if case .value(let v) = emission {
        return v
      } else {
        return nil
      }
    }.joined(separator: " ")

    XCTAssertEqual(joined, "hi . how are you ?")
    
  }

}
