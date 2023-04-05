import Disposable
import Emitter
import XCTest

// MARK: - CreateTests

final class CreateTests: XCTestCase {

  var stage: DisposableStage = .init()

  override func tearDown() {
    stage.reset()
  }

  func testEmittersCreate_emitsInOrder() async throws {
    let entries = ["a", "b", "c", "d", "e"]
    var record: [String] = []

    let createSource = Emitters.create(String.self) { emit in
      _ = await Task {
        for entry in entries {
          emit(.value(entry))
        }
      }.result
    }

    XCTAssertEqual(record.count, 0)

    createSource
      .subscribe { value in
        record.append(value)
      }
      .stage(on: stage)

    await Task.flushHack()

    XCTAssertEqual(record, entries)
  }

  func testEmittersCreate_finishes() async throws {
    let entries = ["a", "b", "c", "d", "e"]
    var didFinish = false

    let createSource = Emitters.create(String.self) { emit in
      _ = await Task {
        for entry in entries {
          emit(.value(entry))
        }
        emit(.finished)
      }.result
    }

    XCTAssertFalse(didFinish)

    createSource
      .subscribe { _ in

      } finished: {
        didFinish = true
      } failed: { _ in
        XCTFail()
      }
      .stage(on: stage)

    await Task.flushHack()

    XCTAssert(didFinish)
  }

  func testEmittersCreate_fails() async throws {
    let entries = ["a", "b", "c", "d", "e"]
    var didFail = false

    let createSource = Emitters.create(String.self) { emit in
      _ = await Task {
        for entry in entries {
          emit(.value(entry))
        }
        emit(.failed(ExampleFailure()))
      }.result
    }

    XCTAssertFalse(didFail)

    createSource
      .subscribe { _ in

      } finished: {
        XCTFail()
      } failed: { error in
        XCTAssert(error is ExampleFailure)
        didFail = true
      }
      .stage(on: stage)

    await Task.flushHack()

    XCTAssert(didFail)
  }

  func testEmittersCreate_emitsOnMain_givenSourceActor() async throws {
    let entries = ["a", "b", "c", "d", "e"]
    var record: [String] = []
    var didFinish = false

    let createSource = Emitters.create(String.self) { emit in
      _ = await Task { @MainActor in
        for entry in entries {
          emit(.value(entry))
        }
        emit(.finished)
      }.result
    }

    XCTAssertEqual(record.count, 0)

    createSource
      .subscribe { value in
        XCTAssert(Thread.isMainThread)
        record.append(value)
      } finished: {
        // for lack of a way to test for the current executor
        XCTAssert(Thread.isMainThread)
        didFinish = true
      } failed: { _ in
        XCTFail()
      }
      .stage(on: stage)

    await Task.flushHack()

    XCTAssertEqual(record, entries)
    XCTAssert(didFinish)
  }

}

// MARK: - ExampleFailure

private struct ExampleFailure: Error { }
