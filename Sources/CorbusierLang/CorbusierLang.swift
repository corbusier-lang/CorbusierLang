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
        var tokens = lex(code: line)
        let statement = try parseStatement(lineTokens: &tokens)
        try executor.execute(statement: statement, in: &self)
    }
    
}

@discardableResult
public func corbusier(context: CRBContext, files: [String], includeStdlib: Bool = true) throws -> CRBContext {
    let runner = Corbusier(context: context, files: files, includeStdlib: includeStdlib)
    try runner.run()
    return runner.context
}

@discardableResult
public func corbusier(context: CRBContext, code: String) throws -> CRBContext {
    return try corbusier(context: context, files: [code])
}

@discardableResult
public func corbusier(context: CRBContext, urls: [URL]) throws -> CRBContext {
    let codeFiles = try urls
        .map({ try String.init(contentsOf: $0) })
    return try corbusier(context: context, files: codeFiles)
}

@discardableResult
public func corbusier(context: CRBContext, url: URL) throws -> CRBContext {
    return try corbusier(context: context, urls: [url])
}

fileprivate class Corbusier {
    
    let originalContext: CRBContext
    var context: CRBContext

    var code: String
    
    init(context: CRBContext, files: [String], includeStdlib: Bool = true) {
        var files = files
        if includeStdlib {
            print("Including stdlib...")
            files.insert(stdlib, at: 0)
        }
        self.code = files.joined(separator: "\n")
        self.context = context
        self.originalContext = context
    }

    func run() throws {
        var tokens = lex(code: code)
        let statements = parseStatements(lineTokens: &tokens)
        try context.execute(statement: .ordered(statements))
    }
    
}
