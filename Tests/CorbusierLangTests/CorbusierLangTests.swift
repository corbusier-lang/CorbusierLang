import XCTest
@testable import CorbusierLang
import CoreCorbusier

class CorbusierLangTests: XCTestCase {
    
    func testLexing() throws {
        let lexer = Lexer(input: "place unplacedRect.topLeft < 5 > firstRect.bottom", component: .full)
        let output = lexer.lex()
        print(output)
        let expression = try parse(lineTokens: output)
        print(expression)
    }
    
    func testRunCorbusier() throws {
        let first = RectObject(rect: CGRect.init(x: 0, y: 0, width: 40, height: 40))
        let unplaced = RectObject(size: CGSize.init(width: 50, height: 50))
        let alsoUnplaced = RectObject(size: CGSize(width: 50, height: 50))
        var context = CRBContext()
        context.objectsMap = [
            crbname("first") : first,
            crbname("unplaced") : unplaced,
            crbname("third") : alsoUnplaced
        ]
        try corbusierRun(line: "place unplaced.bottomLeft < 10 > first.top", in: context)
        try corbusierRun(line: "place third.bottomLeft < 10 > unplaced.top", in: context)
        print(try (unplaced.placed() as! Rect).rect)
        print(try (alsoUnplaced.placed() as! Rect).rect)
    }

}
