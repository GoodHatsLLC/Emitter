import Disposable
import Emitter
import XCTest

// MARK: - FlatMapLatestTests

final class FlatMapLatestTests: XCTestCase {

  let stage = DisposableStage()

  override func setUp() { }

  override func tearDown() {
    stage.reset()
  }

  func testStream_flatMapLatest() throws {
    var record: [String] = []
    let sourceA: PublishSubject<Int, Never> = .init()
    let sourceZ: PublishSubject<Void, Never> = .init()
    @Sendable
    func sourceBFunc(input: Int, count _: Int) -> some Emitter<String, Never> {
      sourceZ
        .map { _ in String(repeating: "\(input)", count: 2) }
    }

    sourceA
      .flatMapLatest { aValue in
        sourceBFunc(input: aValue, count: 2)
      }
      .subscribe { output in
        record.append(output)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 0)

    let entriesA: [Int] = [1, 2, 3]
    for entry in entriesA {
      sourceA.emit(value: entry)
      sourceZ.emit(value: ())
    }

    XCTAssertEqual(["11", "22", "33"], record)
  }

  func testStream_flatMapLatest_value() throws {
    var record: [String] = []
    let sourceA: ValueSubject<Int, Never> = .init(0)
    let sourceZ: ValueSubject<Void, Never> = .init(())
    @Sendable
    func sourceBFunc(input: Int, count _: Int) -> some Emitter<String, Never> {
      sourceZ
        .map { _ in String(repeating: "\(input)", count: 2) }
    }

    sourceA
      .flatMapLatest { aValue in
        sourceBFunc(input: aValue, count: 2)
      }
      .subscribe { output in
        record.append(output)
      }
      .stage(on: stage)

    XCTAssertEqual(record.count, 1)

    let entriesA: [Int] = [1, 2, 3]
    for entry in entriesA {
      sourceA.emit(value: entry)
      sourceZ.emit(value: ())
    }

    XCTAssertEqual(["00", "11", "11", "22", "22", "33", "33"], record)
  }

  func test_dispose_releasesResources_outerPublishSubject() throws {
    var record: [String] = []
    weak var weakSourceA: PublishSubject<Int, Never>?
    weak var weakSourceB: ValueSubject<String, Never>?

    ({
      ({
        let sourceA: PublishSubject<Int, Never> = .init()
        let sourceB: ValueSubject<String, Never> = .init("initial")
        weakSourceA = sourceA
        weakSourceB = sourceB

        sourceA
          .flatMapLatest { value in
            sourceB.map { str in
              "\(str):\(value)"
            }
          }
          .subscribe { value in
            record.append(value)
          }
          .stage(on: stage)

        sourceA.emit(value: 1)
        sourceA.emit(value: 2)
        sourceB.emit(value: "a")
        sourceB.emit(value: "b")
        sourceA.emit(value: 3)
        sourceA.emit(value: 0)
        sourceB.emit(value: "c")
      })()
      XCTAssertNotNil(weakSourceA)
      XCTAssertNotNil(weakSourceB)
      stage.dispose()
    })()
    XCTAssertNil(weakSourceA)
    XCTAssertNil(weakSourceB)

    XCTAssertEqual(["initial:1", "initial:2", "a:2", "b:2", "b:3", "b:0", "c:0"], record)
  }

  func test_dispose_releasesResources_outerValueSubject() throws {
    var record: [String] = []
    weak var weakSourceA: ValueSubject<Int, Never>?
    weak var weakSourceB: PublishSubject<String, Never>?

    ({
      ({
        let sourceA: ValueSubject<Int, Never> = .init(0)
        let sourceB: PublishSubject<String, Never> = .init()
        weakSourceA = sourceA
        weakSourceB = sourceB

        sourceA
          .flatMapLatest { value in
            sourceB.map { str in
              "\(str):\(value)"
            }
          }
          .subscribe { value in
            record.append(value)
          }
          .stage(on: stage)

        sourceA.emit(value: 1)
        sourceA.emit(value: 2)
        sourceB.emit(value: "a")
        sourceB.emit(value: "b")
        sourceA.emit(value: 3)
        sourceA.emit(value: 0)
        sourceB.emit(value: "c")
      })()
      XCTAssertNotNil(weakSourceA)
      XCTAssertNotNil(weakSourceB)
      stage.dispose()
    })()
    XCTAssertNil(weakSourceA)
    XCTAssertNil(weakSourceB)

    XCTAssertEqual(["a:2", "b:2", "c:0"], record)
  }
}

#if canImport(Combine)
import Combine

// MARK: Combine comparisons
extension FlatMapLatestTests {

  func disabled_testStream_flatMapLatest_combine() throws {
    var cancellables = Set<AnyCancellable>()
    var record: [String] = []
    let sourceA: PassthroughSubject<Int, Never> = .init()
    let sourceZ: PassthroughSubject<Void, Never> = .init()
    func sourceBFunc(input: Int, count _: Int) -> some Publisher<String, Never> {
      sourceZ
        .map { _ in String(repeating: "\(input)", count: 2) }
    }

    sourceA
      .map { aValue in
        sourceBFunc(input: aValue, count: 2)
      }
      .switchToLatest()
      .sink { output in
        record.append(output)
      }
      .store(in: &cancellables)

    XCTAssertEqual(record.count, 0)

    let entriesA: [Int] = [1, 2, 3]
    for entry in entriesA {
      sourceA.send(entry)
      sourceZ.send(())
    }

    XCTAssertEqual(["11", "22", "33"], record)
  }

  func disabled_testStream_flatMapLatest_value_combine() throws {
    var cancellables = Set<AnyCancellable>()
    var record: [String] = []
    let sourceA: CurrentValueSubject<Int, Never> = .init(0)
    let sourceZ: CurrentValueSubject<Void, Never> = .init(())
    func sourceBFunc(input: Int, count _: Int) -> some Publisher<String, Never> {
      sourceZ
        .map { _ in String(repeating: "\(input)", count: 2) }
    }

    sourceA
      .map { aValue in
        sourceBFunc(input: aValue, count: 2)
      }
      .switchToLatest()
      .sink { output in
        record.append(output)
      }
      .store(in: &cancellables)

    XCTAssertEqual(record.count, 1)

    let entriesA: [Int] = [1, 2, 3]
    for entry in entriesA {
      sourceA.send(entry)
      sourceZ.send(())
    }

    XCTAssertEqual(["00", "11", "11", "22", "22", "33", "33"], record)
  }
}
#endif
