import Disposable
import EmitterInterface
import Foundation

// MARK: - PrintTypes

public enum PrintTypes: Hashable, CaseIterable {
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
        Print(
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

// MARK: - Print

@MainActor
struct Print<Output: Sendable>: Emitter {

    init(
        upstream: some Emitter<Output>,
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

    @MainActor
    struct Sub<Downstream: Subscriber>: Subscriber
        where Downstream.Value == Output {
        let downstream: Downstream
        let identifier: String
        let id: UUID
        let types: Set<PrintTypes>
        let codeLoc: (fileID: String, line: Int, column: Int)

        func receive(emission: Emission<Output>) {
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
    }

    let id = UUID()

    func subscribe<S: Subscriber>(_ subscriber: S)
        -> AnyDisposable
        where S.Value == Output {
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
                    id: id,
                    types: types,
                    codeLoc: codeLoc
                )
            )
        return AnyDisposable {
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

    private let identifier: String
    private let upstream: any Emitter<Output>
    private let types: Set<PrintTypes>
    private let codeLoc: (fileID: String, line: Int, column: Int)

}
