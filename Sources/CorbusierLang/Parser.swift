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

func parse(lineTokens: [Token]) throws -> CRBExpression {
    guard lineTokens.count == 6 else {
        throw ParsingError.invalidExpression(lineTokens)
    }
    var lineTokens = lineTokens
    try eat(.place, in: &lineTokens)
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
    return .place(CRBPlaceExpression(toPlace: toPlace, distance: CRBFloat(number), anchorPointToPlaceFrom: .ofObject(placeFrom)))
}

func parseObjectAnchor(_ identifier: String) throws -> CRBPlaceExpression.ObjectAnchor {
    let comp = identifier.split(separator: ".")
    let count = comp.count
    if count < 2 {
        throw IdentifierMismatchError.noAnchorName(identifier)
    }
    if count > 2 {
        throw IdentifierMismatchError.tryingToAccessAncherOfAnAnchor(identifier)
    }
    return CRBPlaceExpression.ObjectAnchor(objectName: crbname(String(comp[0])),
                                           anchorName: crbname(String(comp[1])))
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
