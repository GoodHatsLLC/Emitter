import Disposable
import Emitter
import XCTest

// MARK: - WithFailureTypeTests

final class WithFailureTypeTests: XCTestCase {

  enum Emissions<V, F: Error> {
    case value(String)
    case finished
    case failure
  }

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func test_failureType_fromNever() throws {

    let source = PublishSubject<String, Never>()
    let sub = HardcodedFailureSubscribe<String>()
    source
      .withFailure(type: HardcodedFailureSubscribe<String>.Failure.self)
      .subscribe(sub)
      .stage(on: stage)
    

    source.emit(value: "hi")
    source.emit(value: ".")
    source.emit(value: "how")
    source.emit(value: "are")
    source.emit(value: "you")
    source.emit(value: "?")
    source.finish()

    XCTAssertEqual(sub.values.joined(), "hi.howareyou?")
    XCTAssert(sub.failures.count == 0)
    XCTAssert(sub.finishes.count == 1)
  }

  private class HardcodedFailureSubscribe<Output>: Subscriber {

    struct Failure: Error { }

    fileprivate func receive(emission: Emission<Output, Failure>) {
      switch emission {
      case .value(let value):
        values.append(value)
      case .failed(let error):
        failures.append(error)
      case .finished:
        finishes.append(())
      }
    }

    var values: [Output] = []
    var finishes: [()] = []
    var failures: [Failure] = []

  }

}
