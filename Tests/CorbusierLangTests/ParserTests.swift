//
//  ParserTests.swift
//  CorbusierLangTests
//
//  Created by Олег on 05.02.2018.
//

import XCTest
@testable import CorbusierLang

class ParserTests: XCTestCase {
    
    func testParseArgs() throws {
        
        let argsTokens: [Token] = [.identifier("some"), .comma, .identifier("args"), .parenRight]
        var toParse = argsTokens
        let args = try parseArgs(lineTokens: &toParse)
        dump(args)
        print(toParse)
        
    }
    
    func testParseReturn() throws {
        let code = "return abba"
        var tokens = lex(code: code)
        let statement = try parseStatement(lineTokens: &tokens)
        dump(statement)
    }
    
    func testParseDef() throws {
        let code = "def newfunc(a, b, c) { return a }"
        var tokens = lex(code: code)
        print(tokens)
        let statement = try parseStatement(lineTokens: &tokens)
        dump(statement)
    }
    
    func testParseMultilineDef() throws {
        let code = """
def sum(a, b, c) {
    let first = add(a, b)
    let second = add(first, c)
    place main
    return second
}
let three = sum(5, 10, 15)
"""
        var tokens = lex(code: code)
        let statement = parseStatements(lineTokens: &tokens)
        dump(statement)
    }
    
    func testParseIfElse() throws {
        let code = """
if equals(a, b) {
    let main = 10
} else {
    let main = 15
}
"""
        var tokens = lex(code: code)
        let statement = try parseStatement(lineTokens: &tokens)
        dump(statement)
    }
    
    func testParseIf() throws {
        let code = """
if equals(a, b) { let main = 10 }
"""
        var tokens = lex(code: code)
        let statement = try parseStatement(lineTokens: &tokens)
        dump(statement)
    }
    
    func testParseFunc() throws {
        
        let funcTokens: [Token] = [.identifier("callMe"), .parenLeft, .identifier("my"), .comma, .identifier("another"), .parenRight]
        var toParse = funcTokens
        let call = try parseFunctionCallExpression(lineTokens: &toParse)
        dump(call)
        print(toParse)
        
    }
    
}
