import XCTest
@testable import CorbusierLang
import CoreCorbusier

class CorbusierLangTests: XCTestCase {
    
    func testLexing() throws {
        let output = lex(code: "unplacedRect.top.left < 5 > firstRect.bottom")
        print(output)
//        let expression = try parseExpression(lineTokens: output)
//        print(expression)
//        var context = CRBContext()
//        try context.run(line: "*unplacedRect.top.left < 5 > firstRect.botoom")
    }
    
    func testCallFuncWithComplexArguments() throws {
        
        let context = try corbusier(context: .init(), code: """
let a = add(add(5, 10), add(10, add(15, 20)))
return a
""")
        dump(context.returningValue)
        
    }
    
    func testRecursion() throws {
        
        let context = try corbusier(context: CRBContext(), code: """
def recursive(a) {
    if greater(a, 10) {
        let less = subtract(a, 1)
        return recursive(less)
    } else {
        return a
    }
}


return recursive(25.5)
""")
        dump(context)
        let returned = context.returningValue as! CRBNumberInstance
        XCTAssertEqual(returned.value, 9.5)
        dump(context)
    }
    
    func testRunCorbusier() throws {
        let first = CGArea(rect: CGRect.init(x: 0, y: 0, width: 40, height: 40))
        let unplaced = CGArea(size: CGSize.init(width: 50, height: 50))
        let alsoUnplaced = CGArea(size: CGSize(width: 50, height: 50))
        var context = CRBContext()
        context.currentScope.instances = [
            crbname("firstRect") : first,
            crbname("secondRect") : unplaced,
            crbname("thirdRect") : alsoUnplaced,
            crbname("dump") : CRBExternalFunctionInstance.print(),
        ]
//        try corbusierRun(line: "place unplaced.bottomLeft < 10 > first.top", in: context)
//        try corbusierRun(line: "place third.bottomLeft < 10 > unplaced.top", in: context)
        
        print(try! first.placed().anchor(at: [crbname("bottom"), crbname("left")])!)
        
        try context.run(line: "let distance = add(3, 2)")
        try context.run(line: "let bottomSpacing = secondRect.top.left < add(distance, 5) > firstRect.bottom.left")
        try context.run(line: "place bottomSpacing")
        try context.run(line: "let placed = secondRect")
        try context.run(line: "let placedAnchor = placed.top.left")
        try context.run(line: "place thirdRect.top.left < 10 > placedAnchor")
        try context.run(line: "dump(bottomSpacing)")
        
        let rect2 = try (unplaced.placed() as! Rect).rect
        let rect3 = try (alsoUnplaced.placed() as! Rect).rect
        
        print(rect2)
        print(rect3)
        
        XCTAssertEqual(rect2, CGRect.init(x: 0, y: -60, width: 50, height: 50))
        XCTAssertEqual(rect3, CGRect.init(x: 0, y: -50, width: 50, height: 50))
        
    }

}
