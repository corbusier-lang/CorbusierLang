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
        let expr = try parseExpression(lineTokens: lineTokens)
        return CRBStatement.place(expr)
    } else if case .identifier(let toAssign) = firstToken {
        let currentLine = lineTokens
        do {
            try eat(.identifier(toAssign), in: &lineTokens)
            try eat(.oper(.assign), in: &lineTokens)
            let expr = try parseExpression(lineTokens: lineTokens)
            return CRBStatement.assign(crbname(toAssign), expr)
        } catch {
            let expr = try parseExpression(lineTokens: currentLine)
            return CRBStatement.unused(expr)
        }
    } else {
        let expr = try parseExpression(lineTokens: lineTokens)
        return CRBStatement.unused(expr)
    }
}

func parseExpression(lineTokens: [Token]) throws -> CRBExpression {
    
    if lineTokens.count == 1 {
        if case .identifier(let instanceName) = lineTokens[0] {
            return CRBExpression.instance(crbname(instanceName))
        }
    }
    
    guard lineTokens.count == 5 else {
        throw ParsingError.invalidExpression(lineTokens)
    }
    var lineTokens = lineTokens

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
    let toPlace = try parseObjectAnchor(leftIdentifier)
    let placeFrom = try parseObjectAnchor(rightIdentifier)
    return CRBExpression.placement(CRBPlaceExpression(toPlace: toPlace, distance: CRBFloat(number), anchorPointToPlaceFrom: .ofObject(placeFrom)))
}

func parseObjectAnchor(_ identifier: String) throws -> CRBPlaceExpression.ObjectAnchor {
    let comp = identifier.split(separator: ".")
    let count = comp.count
    if count < 2 {
        throw IdentifierMismatchError.noAnchorName(identifier)
    }
    let slice = comp[1...]
        .lazy
        .map(String.init)
        .map(CRBAnchorName.init)
    return CRBPlaceExpression.ObjectAnchor(objectName: crbname(String(comp[0])),
                                           anchorKeyPath: Array(slice))
}

enum ParsingError : Error {
    case invalidExpression([Token])
    case notAnIdentifier(Token)
    case expectedOperator(Token)
    case expectedNumber(Token)
}

enum IdentifierMismatchError : Error {
    case noAnchorName(String)
    case tryingToAccessAncherOfAnAnchor(String)
}
