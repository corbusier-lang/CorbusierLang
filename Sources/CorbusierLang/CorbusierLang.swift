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
    
    public init(multiline: String, context: CRBContext) {
        self.code = multiline
        self.context = context
        self.originalContext = context
    }

    public convenience init(lines: [String], context: CRBContext) {
        let code = lines.joined(separator: "\n")
        self.init(multiline: code, context: context)
    }

    public convenience init(url: URL, context: CRBContext) throws {
        let data = try Data.init(contentsOf: url)
        let string = String.init(data: data, encoding: .utf8) ?? ""
        self.init(multiline: string, context: context)
    }
    
    public func run() throws {
//        for line in lines {
//            let lexer = Lexer(input: line, component: .full)
//            var tokens = lexer.lex()
//            let statement = try parseStatement(lineTokens: &tokens)
//            try context.execute(statement: statement)
//        }
        var tokens = lex(code: code)
        let statements = parseStatements(lineTokens: &tokens)
        try context.execute(statement: .ordered(statements))
    }
    
}
