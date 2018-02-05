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
    
    func testParseFunc() throws {
        
        let funcTokens: [Token] = [.identifier("callMe"), .parenLeft, .identifier("my"), .comma, .identifier("another"), .parenRight]
        var toParse = funcTokens
        let call = try parseFunctionCallExpression(lineTokens: &toParse)
        dump(call)
        print(toParse)
        
    }
    
}
