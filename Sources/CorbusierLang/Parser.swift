//
//  Parser.swift
//  CorbusierLang
//
//  Created by Олег on 04.02.2018.
//

import CoreCorbusier

struct EoF : Error { }
enum Mismatch : Error {
    case syntaxError(expected: Token, got: Token)
}

struct MultipleErrors : Error {
    var errors: [Error]
}

func skipEndOfLine(in line: inout [Token]) {
    if peek(in: line) == .endOfLine {
        try! eat(.endOfLine, in: &line)
        skipEndOfLine(in: &line)
    }
}

func peek(in line: [Token]) -> Token? {
    return line.first
}

func eat(_ token: Token, in line: inout [Token]) throws {
    guard !line.isEmpty else {
        throw EoF()
    }
    let current = line.removeFirst()
    if current == token {
        return
    } else {
        throw Mismatch.syntaxError(expected: token, got: current)
    }
}

func eat(oneOf tokens: [Token], in line: inout [Token]) throws {
    var errors: [Error] = []
    for token in tokens {
        var copy = line
        do {
            try eat(token, in: &copy)
            line = copy
            return
        } catch {
            errors.append(error)
        }
    }
    print(errors)
    throw MultipleErrors(errors: errors)
}

let statementParser = parsePlaceStatement
    ~> parseReturn
    ~> parseAssign
    ~> parseDef
    ~> parseIf
    ~> parseUnusedExpression

func parseStatement(lineTokens: inout [Token]) throws -> CRBStatement {
    return try statementParser(&lineTokens)
}

func parseStatements(lineTokens: inout [Token]) -> [CRBStatement] {
    var statements: [CRBStatement] = []
    while true {
        if lineTokens.isEmpty {
            break
        }
        let copy = lineTokens
        do {
            let line = try statementParser(&lineTokens)
            statements.append(line)
        } catch {
            lineTokens = copy
            break
        }
        if !lineTokens.isEmpty {
            let copy = lineTokens
            do {
                try eat(oneOf: [.semicolon, .endOfLine], in: &lineTokens)
            } catch {
                lineTokens = copy
                break
            }
        } else {
            break
        }
    }
    return statements
}

func parsePlaceStatement(lineTokens: inout [Token]) throws -> CRBStatement {
    try eat(.place, in: &lineTokens)
    let expr = try parseExpression(lineTokens: &lineTokens)
    return CRBStatement.place(expr)
}

func parseReturn(lineTokens: inout [Token]) throws -> CRBStatement {
    try eat(.`return`, in: &lineTokens)
    let expression = try parseExpression(lineTokens: &lineTokens)
    return CRBStatement.`return`(expression)
}

func parseAssign(lineTokens: inout [Token]) throws -> CRBStatement {
    try eat(.`let`, in: &lineTokens)
    let toAssign = try parseIdentifier(lineTokens: &lineTokens)
    try eat(.oper(.assign), in: &lineTokens)
    let expression = try parseExpression(lineTokens: &lineTokens)
    return CRBStatement.assign(crbname(toAssign), expression)
}

func parseDef(lineTokens: inout [Token]) throws -> CRBStatement {
    try eat(.def, in: &lineTokens)
    let functionName = try parseIdentifier(lineTokens: &lineTokens)
    try eat(.parenLeft, in: &lineTokens)
    let argNames = try parseArgNames(lineTokens: &lineTokens)
    try eat(.parenRight, in: &lineTokens)
    try eat(.braceLeft, in: &lineTokens)
    skipEndOfLine(in: &lineTokens)
    let statements = parseStatements(lineTokens: &lineTokens)
    skipEndOfLine(in: &lineTokens)
    try eat(.braceRight, in: &lineTokens)
    return CRBStatement.define(crbname(functionName), argNames, statements)
}

func parseIf(lineTokens: inout [Token]) throws -> CRBStatement {
    try eat(.`if`, in: &lineTokens)
    let expression = try parseExpression(lineTokens: &lineTokens)
    try eat(.braceLeft, in: &lineTokens)
    skipEndOfLine(in: &lineTokens)
    let doStatements = parseStatements(lineTokens: &lineTokens)
    skipEndOfLine(in: &lineTokens)
    try eat(.braceRight, in: &lineTokens)
    var elseStatements: [CRBStatement] = []
    if peek(in: lineTokens) == .`else` {
        try eat(.`else`, in: &lineTokens)
        try eat(.braceLeft, in: &lineTokens)
        skipEndOfLine(in: &lineTokens)
        elseStatements = parseStatements(lineTokens: &lineTokens)
        skipEndOfLine(in: &lineTokens)
        try eat(.braceRight, in: &lineTokens)
    }
    return CRBStatement.conditioned(if: expression,
                                    do: .ordered(doStatements),
                                    else: .ordered(elseStatements))
}

func parseUnusedExpression(lineTokens: inout [Token]) throws -> CRBStatement {
    let expr = try parseExpression(lineTokens: &lineTokens)
    return CRBStatement.unused(expr)
}

func parseFunctionCallExpression(lineTokens: inout [Token]) throws -> CRBExpression {
    let ref = try parseReferenceExpression(lineTokens: &lineTokens)
    try eat(.parenLeft, in: &lineTokens)
    let args = try parseArgs(lineTokens: &lineTokens)
    try eat(.parenRight, in: &lineTokens)
    return .call(ref, arguments: args)
}

func parseArgs(lineTokens: inout [Token]) throws -> [CRBExpression] {
    if peek(in: lineTokens) == .parenRight {
        return []
    } else {
        let expr = try parseExpression(lineTokens: &lineTokens)
        if peek(in: lineTokens) == .parenRight {
            return [expr]
        } else {
            try eat(.comma, in: &lineTokens)
            return try [expr] + parseArgs(lineTokens: &lineTokens)
        }
    }
}

func parseArgNames(lineTokens: inout [Token]) throws -> [CRBArgumentName] {
    if peek(in: lineTokens) == .parenRight {
        return []
    } else {
        let argName: CRBArgumentName = crbname(try parseIdentifier(lineTokens: &lineTokens))
        if peek(in: lineTokens) == .parenRight {
            return [argName]
        } else {
            try eat(.comma, in: &lineTokens)
            return try [argName] + parseArgNames(lineTokens: &lineTokens)
        }
    }
}

func parseExpression(lineTokens: inout [Token]) throws -> CRBExpression {
    return try expressionParser(&lineTokens)
}

let expressionParser = parsePlacementExpression
    ~> parseInstanceExpression
    ~> parseFunctionCallExpression
    ~> parseReferenceExpression

typealias Parse<Output> = (inout [Token]) throws -> Output

precedencegroup ParseForward {
    associativity: left
}

infix operator ~> : ParseForward

func ~> <Output>(lhs: @escaping Parse<Output>, rhs: @escaping Parse<Output>) -> Parse<Output> {
    return { (tokens: inout [Token]) throws -> Output in
        var copy = tokens
        do {
            let res = try lhs(&tokens)
            return res
        } catch {
            let secondRes = try rhs(&copy)
            tokens = copy
            return secondRes
        }
    }
}

func parseInstanceExpression(lineTokens: inout [Token]) throws -> CRBExpression {
    let num = try parseNumber(lineTokens: &lineTokens)
    let instance = CRBNumberInstance(CRBFloat(num))
    return CRBExpression.instance(instance)
}

func parseReferenceExpression(lineTokens: inout [Token]) throws -> CRBExpression {
    let identifier = try parseIdentifier(lineTokens: &lineTokens)
    let instanceCall = try parseInstanceCall(identifier)
    return CRBExpression.reference(crbname(instanceCall.name),
                                   instanceCall.keyPath.map(crbname))
}

func parsePlacementExpression(lineTokens: inout [Token]) throws -> CRBExpression {
//    try eat(.object, in: &lineTokens)
    let objectIdentifier = try parseIdentifier(lineTokens: &lineTokens)
    let instanceInfo = try parseInstanceCall(objectIdentifier)
    let objectAnchor = CRBPlaceExpression.ObjectAnchor(objectName: crbname(instanceInfo.name),
                                                       anchorKeyPath: instanceInfo.keyPath.map(crbname))
    try eat(.oper(.layoutLeft), in: &lineTokens)
    let distance = try parseExpression(lineTokens: &lineTokens)
    try eat(.oper(.layoutRight), in: &lineTokens)
    let fromAnchor = try parseExpression(lineTokens: &lineTokens)
    let place = CRBPlaceExpression(toPlace: objectAnchor,
                                   distance: distance,
                                   anchorPointToPlaceFrom: fromAnchor)
    return .placement(place)
}

func parseNumber(lineTokens: inout [Token]) throws -> Double {
    guard let next = peek(in: lineTokens) else {
        throw "No more tokens"
    }
    guard case .number(let num) = next else {
        throw "Not a number"
    }
    try eat(.number(num), in: &lineTokens)
    return num
}

func parseIdentifier(lineTokens: inout [Token]) throws -> String {
    guard let next = peek(in: lineTokens) else {
        throw "No more tokens"
    }
    guard case .identifier(let identifier) = next else {
        throw "Not an identifier"
    }
    try eat(.identifier(identifier), in: &lineTokens)
    return identifier
}

func parseInstanceCall(_ identifier: String) throws -> (name: String, keyPath: [String]) {
    let comp = identifier.split(separator: ".")
    let count = comp.count
    if count < 1 {
        throw IdentifierMismatchError.notAnIdentifier(identifier)
    }
    let slice = comp[1...]
        .lazy
        .map(String.init)
    return (name: String(comp[0]), keyPath: Array(slice))
}

enum ParsingError : Error {
    case invalidExpression([Token])
    case notAnIdentifier(Token)
    case expectedOperator(Token)
    case expectedNumber(Token)
}

enum IdentifierMismatchError : Error {
    case notAnIdentifier(String)
    case tryingToAccessAncherOfAnAnchor(String)
}

extension String : Error { }
