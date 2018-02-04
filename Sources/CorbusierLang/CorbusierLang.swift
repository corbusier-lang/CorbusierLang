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
        let lexer = Lexer(input: line, component: .full)
        let tokens = lexer.lex()
        let statement = try parseStatement(lineTokens: tokens)
        try executor.execute(statement: statement, in: &self)
    }
    
}

public final class Corbusier {
    
    public let originalContext: CRBContext
    private var execution: CRBExecution
    
    public let lines: [String]
    
    public init(lines: [String], context: CRBContext) {
        self.originalContext = context
        self.lines = lines
        self.execution = CRBExecution(context: context)
    }
    
    public convenience init(multiline: String, context: CRBContext) {
        let lines = multiline.split(separator: "\n").map(String.init)
        self.init(lines: lines, context: context)
    }
    
    public convenience init(url: URL, context: CRBContext) throws {
        let data = try Data.init(contentsOf: url)
        let string = String.init(data: data, encoding: .utf8) ?? ""
        self.init(multiline: string, context: context)
    }
    
    public func run() throws {
        for line in lines {
            let lexer = Lexer(input: line, component: .full)
            let tokens = lexer.lex()
            let statement = try parseStatement(lineTokens: tokens)
            try execution.execute(statement: statement)
        }
    }
    
}
