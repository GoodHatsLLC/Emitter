#if canImport(Combine)
import Combine
#endif
import Emitter
import XCTest

// MARK: - Benchmarks

final class Benchmarks: XCTestCase {
  let input = Array(repeating: 123, count: 99_999)
}

// MARK: Map

extension Benchmarks {
  func _test_map() {
    measure { // Time: 0.018 sec
      let sourceA: PublishSubject<Int> = .init()
      let stage = DisposableStage()
      sourceA
        .map { $0 + 1 }
        .subscribe { value in
          blackHole(value)
        }
        .stage(on: stage)

      for value in input {
        sourceA.emit(.value(value))
      }
    }
  }

  #if canImport(Combine)
  func _test_map_combine() {
    measure { // Time: 0.014 sec
      let sourceA: PassthroughSubject<Int, Never> = .init()
      var stage = Set<AnyCancellable>()
      sourceA
        .map { $0 + 1 }
        .sink { value in
          blackHole(value)
        }
        .store(in: &stage)

      for value in input {
        sourceA.send(value)
      }
    }
  }
  #endif
}

// MARK: CompactMap

extension Benchmarks {

  func _test_compactMap() {
    measure { // Time: 0.018 sec
      let sourceA: PublishSubject<Int> = .init()
      let stage = DisposableStage()
      var shouldNil = false
      sourceA
        .compactMap {
          shouldNil = !shouldNil
          return shouldNil ? nil : $0
        }
        .subscribe { value in
          blackHole(value)
        }
        .stage(on: stage)

      for value in input {
        sourceA.emit(.value(value))
      }
    }
  }

  #if canImport(Combine)
  func _test_compactMap_combine() {
    measure { // Time: 0.016 sec
      let sourceA: PassthroughSubject<Int, Never> = .init()
      var stage = Set<AnyCancellable>()
      var shouldNil = false
      sourceA
        .compactMap {
          shouldNil = !shouldNil
          return shouldNil ? nil : $0
        }
        .sink { value in
          blackHole(value)
        }
        .store(in: &stage)

      for value in input {
        sourceA.send(value)
      }
    }
  }
  #endif
}

// MARK: FlatMapLatest

extension Benchmarks {

  func _test_flatMapLatest() {
    measure { // Time: 0.095 sec
      let stage = DisposableStage()
      let sourceA: PublishSubject<Int> = .init()
      let sourceB: ValueSubject<Int> = .init(1)

      sourceA
        .flatMapLatest { aValue in
          sourceB.map { _ in aValue }
        }
        .subscribe { value in
          blackHole(value)
        }
        .stage(on: stage)

      for value in input {
        sourceA.emit(.value(value))
      }
    }
  }

  #if canImport(Combine)
  func _test_flatMapLatest_combine() {
    measure { // Time: 0.104 sec
      let sourceA: PassthroughSubject<Int, Never> = .init()
      let sourceB: CurrentValueSubject<Int, Never> = .init(1)
      var stage = Set<AnyCancellable>()
      sourceA
        .map { aValue in
          sourceB.map { _ in aValue }
        }
        .switchToLatest()
        .sink { value in
          blackHole(value)
        }
        .store(in: &stage)

      for value in input {
        sourceA.send(value)
      }
    }
  }
  #endif
}

// MARK: CombineLastest

extension Benchmarks {

  func _test_combineLatest() {
    measure { // Time: 0.045 sec
      let stage = DisposableStage()
      let sourceA: PublishSubject<Int> = .init()
      let sourceB: ValueSubject<Int> = .init(1)

      sourceA
        .combineLatest(sourceB)
        .subscribe { value in
          blackHole(value)
        }
        .stage(on: stage)

      for value in input {
        sourceA.emit(.value(value))
      }
    }
  }

  #if canImport(Combine)
  func _test_combineLatest_combine() {
    measure { // Time: 0.033 sec
      let sourceA: PassthroughSubject<Int, Never> = .init()
      let sourceB: CurrentValueSubject<Int, Never> = .init(1)
      var stage = Set<AnyCancellable>()
      sourceA
        .combineLatest(sourceB)
        .sink { value in
          blackHole(value)
        }
        .store(in: &stage)

      for value in input {
        sourceA.send(value)
      }
    }
  }
  #endif
}

// MARK: Merge

extension Benchmarks {
  func _test_merge() {
    measure { // Time: 0.015 sec
      let stage = DisposableStage()
      let sourceA: PublishSubject<Int> = .init()
      let sourceB: ValueSubject<Int> = .init(1)

      sourceA
        .merge(sourceB)
        .subscribe { value in
          blackHole(value)
        }
        .stage(on: stage)

      for value in input {
        sourceA.emit(.value(value))
      }
    }
  }

  #if canImport(Combine)
  func _test_merge_combine() {
    measure { // Time: 0.015 sec
      let sourceA: PassthroughSubject<Int, Never> = .init()
      let sourceB: CurrentValueSubject<Int, Never> = .init(1)
      var stage = Set<AnyCancellable>()
      sourceA
        .merge(with: sourceB)
        .sink { value in
          blackHole(value)
        }
        .store(in: &stage)

      for value in input {
        sourceA.send(value)
      }
    }
  }
  #endif
}

// MARK: RemoveDuplicates

extension Benchmarks {
  func _test_removeDuplicates() {
    measure { // Time: 0.023 sec
      let stage = DisposableStage()
      let sourceA: PublishSubject<Int> = .init()

      sourceA
        .removeDuplicates()
        .subscribe { value in
          blackHole(value)
        }
        .stage(on: stage)

      var last: Int?
      for value in input {
        sourceA.emit(.value(last ?? value))
        last = last == nil ? value : nil
      }
    }
  }

  #if canImport(Combine)
  func _test_removeDuplicates_combine() {
    measure { // Time: 0.030 sec
      let sourceA: PassthroughSubject<Int, Never> = .init()
      var stage = Set<AnyCancellable>()
      sourceA
        .removeDuplicates()
        .sink { value in
          blackHole(value)
        }
        .store(in: &stage)

      var last: Int?
      for value in input {
        sourceA.send(last ?? value)
        last = last == nil ? value : nil
      }
    }
  }
  #endif
}
