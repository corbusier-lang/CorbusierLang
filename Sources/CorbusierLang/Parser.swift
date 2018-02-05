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

func peek(in line: [Token]) -> Token {
    return line[0]
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

func parseStatement(lineTokens: [Token]) throws -> CRBStatement {
    var lineTokens = lineTokens
    let firstToken = lineTokens[0]
    if firstToken == .place {
        try eat(.place, in: &lineTokens)
        let expr = try parseExpression(lineTokens: &lineTokens)
        return CRBStatement.place(expr)
    } else if firstToken == .`let` {
        try eat(.`let`, in: &lineTokens)
        guard case .identifier(let toAssign) = lineTokens.first! else {
            throw ParsingError.notAnIdentifier(lineTokens.first!)
        }
        try eat(.identifier(toAssign), in: &lineTokens)
        try eat(.oper(.assign), in: &lineTokens)
        let expression = try parseExpression(lineTokens: &lineTokens)
        return CRBStatement.assign(crbname(toAssign), expression)
    } else {
        let expr = try parseExpression(lineTokens: &lineTokens)
        return CRBStatement.unused(expr)
    }
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

func parseExpression(lineTokens: inout [Token]) throws -> CRBExpression {
    return try expressionParser(&lineTokens)
}

let expressionParser = parsePlacementExpression
    ~> parseInstanceExpression
    ~> parseFunctionCallExpression
    ~> parseReferenceExpression

typealias Parse = (inout [Token]) throws -> CRBExpression

precedencegroup ParseForward {
    associativity: left
}

infix operator ~> : ParseForward

func ~> (lhs: @escaping Parse, rhs: @escaping Parse) -> Parse {
    return { (tokens: inout [Token]) throws -> CRBExpression in
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
    guard case .number(let num) = peek(in: lineTokens) else {
        throw "Not a number"
    }
    try eat(.number(num), in: &lineTokens)
    let instance = CRBNumberInstance(CRBFloat(num))
    return CRBExpression.instance(instance)
}

func parseReferenceExpression(lineTokens: inout [Token]) throws -> CRBExpression {
    guard case .identifier(let identifier) = peek(in: lineTokens) else {
        throw "Not an identifier"
    }
    try eat(.identifier(identifier), in: &lineTokens)
    let instanceCall = try parseInstanceCall(identifier)
    return CRBExpression.reference(crbname(instanceCall.name),
                                   instanceCall.keyPath.map(crbname))
}

func parsePlacementExpression(lineTokens: inout [Token]) throws -> CRBExpression {
//    try eat(.object, in: &lineTokens)
    guard case .identifier(let objectIdentifier) = peek(in: lineTokens) else {
        throw "Not an identifier"
    }
    try eat(.identifier(objectIdentifier), in: &lineTokens)
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
