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

func lookup(in line: inout [Token], next: (Token) -> Bool) throws {
    let first = line[0]
    if next(first) {
        try eat(first, in: &line)
    }
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

func parseExpression(lineTokens: inout [Token]) throws -> CRBExpression {
    
    if lineTokens.count == 1 {
        if case .identifier(let instanceName) = lineTokens[0] {
            let parsedInstanceName = try parseInstanceCall(instanceName)
            return CRBExpression.subinstance(crbname(parsedInstanceName.name),
                                             parsedInstanceName.keyPath.map(crbname))
        }
    }
    
    guard lineTokens.count == 5 else {
        throw ParsingError.invalidExpression(lineTokens)
    }

    guard case .identifier(let leftIdentifier) = lineTokens.first! else {
        throw ParsingError.notAnIdentifier(lineTokens.first!)
    }
    try eat(.identifier(leftIdentifier), in: &lineTokens)
    try eat(.oper(.layoutLeft), in: &lineTokens)
    guard case .number(let number) = lineTokens.first! else {
        throw ParsingError.expectedNumber(lineTokens.first!)
    }
    try eat(.number(number), in: &lineTokens)
    try eat(.oper(.layoutRight), in: &lineTokens)
    guard case .identifier(let rightIdentifier) = lineTokens.first! else {
        throw ParsingError.notAnIdentifier(lineTokens.first!)
    }
    try eat(.identifier(rightIdentifier), in: &lineTokens)
    let toPlaceParsed = try parseInstanceCall(leftIdentifier)
    let toPlace = CRBPlaceExpression.ObjectAnchor.init(objectName: crbname(toPlaceParsed.name), anchorKeyPath: toPlaceParsed.keyPath.map(crbname))
    let placeFromParsed = try parseInstanceCall(rightIdentifier)
    let placeFrom = CRBPlaceExpression.AnchorPointRef.init(instanceName: crbname(placeFromParsed.name), keyPath: placeFromParsed.keyPath.map(crbname))
    return CRBExpression.placement(CRBPlaceExpression(toPlace: toPlace, distance: CRBFloat(number), anchorPointToPlaceFrom: placeFrom))
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
