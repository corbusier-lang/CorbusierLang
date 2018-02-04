//
//  CorbusierLang.swift
//  CorbusierLang
//
//  Created by Олег on 04.02.2018.
//

import CoreCorbusier

public func corbusierRun(line: String, in context: inout CRBContext) throws {
    
    let executor = CRBStatementExecutor()
    let lexer = Lexer(input: line, component: .full)
    let tokens = lexer.lex()
    let statement = try parseStatement(lineTokens: tokens)
    try executor.execute(statement: statement, in: &context)
    
}


