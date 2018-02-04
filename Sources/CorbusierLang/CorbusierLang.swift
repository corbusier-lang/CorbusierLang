//
//  CorbusierLang.swift
//  CorbusierLang
//
//  Created by Олег on 04.02.2018.
//

import CoreCorbusier

@discardableResult
public func corbusierRun(line: String, in context: CRBContext) throws -> CRBContext {
    
    let executor = CRBExpressionExecutor(context: context)
    let lexer = Lexer(input: line, component: .full)
    let tokens = lexer.lex()
    let expression = try parse(lineTokens: tokens)
    try executor.execute(expression: expression)
    return executor.context
    
}


