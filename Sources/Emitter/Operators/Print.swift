import Disposable

// MARK: - PrintTypes

public enum PrintTypes: Hashable, CaseIterable, Sendable {
  case initializer
  case subscribe
  case finished
  case dispose
  case value
  case error
}

extension Emitter {
  public func print(
    _ identifier: String = "🖨️",
    _ types: Set<PrintTypes> = Set(PrintTypes.allCases),
    _ file: String = #fileID,
    _ line: Int = #line,
    _ column: Int = #column
  ) -> some Emitter<Output> {
    Emitters.Print(
      upstream: self,
      identifier: identifier,
      types: types,
      codeLoc: (
        fileID: file,
        line: line,
        column: column
      )
    )
  }
}

// MARK: - Emitters.Print

extension Emitters {
  // MARK: - Print

  public struct Print<Upstream: Emitter, Output: Sendable>: Emitter
    where Upstream.Output == Output
  {

    // MARK: Lifecycle

    public init(
      upstream: Upstream,
      identifier: String,
      types: Set<PrintTypes>,
      codeLoc: (fileID: String, line: Int, column: Int)
    ) {
      self.identifier = identifier
      self.upstream = upstream
      self.types = types
      self.codeLoc = codeLoc
      if types.contains(.initializer) {
        Swift.print(
          """
          [\(identifier)]<\(Output.self)> init \(codeLoc.fileID):\(codeLoc.line):\(codeLoc.line)
          """
        )
      }
    }

    // MARK: Public

    public let upstream: Upstream

    public func subscribe<S: Subscriber>(_ subscriber: S)
      -> AutoDisposable
      where S.Value == Output
    {
      if types.contains(.subscribe) {
        Swift.print(
          """
          [\(identifier)]<\(Output.self)> init \(codeLoc.fileID):\(codeLoc.line):\(codeLoc.line)
          """
        )
      }
      let disposable = upstream
        .subscribe(
          Sub<S>(
            downstream: subscriber,
            identifier: identifier,
            types: types,
            codeLoc: codeLoc
          )
        )
      return AutoDisposable {
        disposable.dispose()
        if types.contains(.dispose) {
          Swift.print(
            """
            [\(identifier)]<\(Output.self)> init \(codeLoc.fileID):\(codeLoc.line):\(codeLoc.line)
            """
          )
        }
      }
    }

    // MARK: Private

    private struct Sub<Downstream: Subscriber>: Subscriber
      where Downstream.Value == Output
    {

      // MARK: Lifecycle

      fileprivate init(
        downstream: Downstream,
        identifier: String,
        types: Set<PrintTypes>,
        codeLoc: (fileID: String, line: Int, column: Int)
      ) {
        self.downstream = downstream
        self.identifier = identifier
        self.types = types
        self.codeLoc = codeLoc
      }

      // MARK: Fileprivate

      fileprivate func receive(emission: Emission<Output>) {
        let newEmission: Emission<Output>
        switch emission {
        case .value(let value):
          newEmission = .value(value)
          if types.contains(.value) {
            Swift.print(
              """
              [\(identifier)]<\(Output.self)> init \(codeLoc.fileID):\(codeLoc.line):\(codeLoc.line)
              """
            )
          }
        case .finished:
          newEmission = .finished
          if types.contains(.finished) {
            Swift.print(
              """
              [\(identifier)]<\(Output.self)> init \(codeLoc.fileID):\(codeLoc.line):\(codeLoc.line)
              """
            )
          }
        case .failed(let error):
          newEmission = .failed(error)
          if types.contains(.error) {
            Swift.print(
              """
              [\(identifier)]<\(Output.self)> init \(codeLoc.fileID):\(codeLoc.line):\(codeLoc.line)
              """
            )
          }
        }
        downstream.receive(emission: newEmission)
      }

      // MARK: Private

      private let downstream: Downstream
      private let identifier: String
      private let types: Set<PrintTypes>
      private let codeLoc: (fileID: String, line: Int, column: Int)

    }

    private let identifier: String
    private let types: Set<PrintTypes>
    private let codeLoc: (fileID: String, line: Int, column: Int)

  }
}
