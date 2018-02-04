import XCTest
@testable import CorbusierLang
import CoreCorbusier

class CorbusierLangTests: XCTestCase {
    
    func testLexing() throws {
        let lexer = Lexer(input: "unplacedRect.topLeft < 5 > firstRect.bottom", component: .full)
        let output = lexer.lex()
        print(output)
//        let expression = try parseExpression(lineTokens: output)
//        print(expression)
        var context = CRBContext()
        try corbusierRun(line: "unplacedRect.topLeft < 5 > firstRect.bottom", in: &context)
    }
    
    func testRunCorbusier() throws {
        let first = RectObject(rect: CGRect.init(x: 0, y: 0, width: 40, height: 40))
        let unplaced = RectObject(size: CGSize.init(width: 50, height: 50))
        let alsoUnplaced = RectObject(size: CGSize(width: 50, height: 50))
        var context = CRBContext()
        context.instances = [
            crbname("firstRect") : first,
            crbname("secondRect") : unplaced,
            crbname("thirdRect") : alsoUnplaced
        ]
//        try corbusierRun(line: "place unplaced.bottomLeft < 10 > first.top", in: context)
//        try corbusierRun(line: "place third.bottomLeft < 10 > unplaced.top", in: context)
        
        try context.run(line: "bottomSpacing = secondRect.bottomLeft < 10 > firstRect.top")
        try context.run(line: "placed = secondRect")
        try context.run(line: "place bottomSpacing")
        try context.run(line: "place thirdRect.bottomLeft < 10 > placed.top")
        
        print(try (unplaced.placed() as! Rect).rect)
        print(try (alsoUnplaced.placed() as! Rect).rect)
    }

}

extension CRBContext {
    
    fileprivate mutating func run(line: String) throws {
        try corbusierRun(line: line, in: &self)
    }
    
}
