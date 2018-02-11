//
//  CorbusierLang.swift
//  CorbusierLang
//
//  Created by Олег on 04.02.2018.
//

import CoreCorbusier
import Foundation

extension CRBContext {
    
    public mutating func run(line: String) throws {
        let executor = CRBStatementExecutor()
        var tokens = lex(code: line)
        let statement = try parseStatement(lineTokens: &tokens)
        try executor.execute(statement: statement, in: &self)
    }
    
}

public final class Corbusier {
    
    public let originalContext: CRBContext
    public var context: CRBContext

    public var code: String
    
    public init(context: CRBContext, files: [String], includeStdlib: Bool = true) {
        var files = files
        if includeStdlib {
            print("Including stdlib...")
            files.insert(stdlib, at: 0)
        }
        self.code = files.joined(separator: "\n")
        self.context = context
        self.originalContext = context
    }
    
    public convenience init(context: CRBContext, code: String) {
        self.init(context: context, files: [code])
    }
    
    public convenience init(context: CRBContext, lines: [String]) {
        let code = lines.joined(separator: "\n")
        self.init(context: context, code: code)
    }

    public convenience init(context: CRBContext, url: URL) throws {
        let data = try Data.init(contentsOf: url)
        let string = String.init(data: data, encoding: .utf8) ?? ""
        self.init(context: context, code: string)
    }
    
    public func run() throws {
        var tokens = lex(code: code)
        let statements = parseStatements(lineTokens: &tokens)
        try context.execute(statement: .ordered(statements))
    }
    
}
