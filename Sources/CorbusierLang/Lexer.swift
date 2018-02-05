#if os(macOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

extension Character {
    
    var i32: Int32 {
        return Int32(String(self).unicodeScalars.first!.value)
    }
    
    var isSpace: Bool {
        return isspace(i32) != 0
    }
    
    var isAlphanumeric: Bool {
        return isalnum(i32) != 0
    }
    
}

enum Token {
    
    enum BinaryOperator {
        case layoutLeft
        case layoutRight
        case assign
    }
    
    case identifier(String)
    case number(Double)
    case comma
    case oper(BinaryOperator)
    case place
    case parenLeft
    case parenRight
    case `let`
    case object
    
}

extension Token : Equatable {
    
    static func ==(lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case (.identifier(let left), .identifier(let right)):
            return left == right
        case (.number(let left), .number(let right)):
            return left == right
        case (.comma, .comma):
            return true
        case (.place, .place):
            return true
        case (.`let`, .`let`):
            return true
        case (.object, .object):
            return true
        case (.parenLeft, .parenLeft):
            return true
        case (.parenRight, .parenRight):
            return true
        case (.oper(let left), .oper(let right)):
            return left == right
        default:
            return false
        }
    }
    
}

struct LexerComponent {
    
    enum Result {
        case detected(Token, toSkip: Int)
        case none
    }
    
    let _getToken: (IndexingIterator<String>) -> Result
    
    init(getToken: @escaping (IndexingIterator<String>) -> Result) {
        self._getToken = getToken
    }
    
    func getToken(context: IndexingIterator<String>) -> Result {
        return _getToken(context)
    }
    
    func composed(withComponent component: LexerComponent) -> LexerComponent {
        return LexerComponent { context in
            let first = self.getToken(context: context)
            if case .detected = self.getToken(context: context) {
                return first
            } else {
                return component.getToken(context: context)
            }
        }
    }
    
}

struct StringTokenDetector {
    
    let _detect: (String) -> Token?
    
    init(detect: @escaping (String) -> Token?) {
        self._detect = detect
    }
    
    func token(from string: String) -> Token? {
        let result = _detect(string)
        return result
    }
    
    func composed(withDetector detector: StringTokenDetector) -> StringTokenDetector {
        return StringTokenDetector { str in
            return self.token(from: str) ?? detector.token(from: str)
        }
    }
    
}

extension LexerComponent {
    
    static func singleElement(detect: @escaping (Character) -> Token?) -> LexerComponent {
        return LexerComponent { context in
            var cont = context
            guard let char = cont.next() else {
                return .none
            }
            guard let detected = detect(char) else {
                return .none
            }
            return .detected(detected, toSkip: 1)
        }
    }
    
    static func string(detector: StringTokenDetector) -> LexerComponent {
        return LexerComponent { context in
            var cont = context
            var str = ""
            while let char = cont.next(), char.isAlphanumeric || char == "." {
                str.append(char)
            }
            guard !str.isEmpty else {
                return .none
            }
            if let detected = detector.token(from: str) {
                return .detected(detected, toSkip: str.count)
            } else {
                return .none
            }
        }
    }
    
}

extension StringTokenDetector {
    
    static var numbers: StringTokenDetector {
        return StringTokenDetector(detect: { (str) -> Token? in
            if let double = Double(str) {
                return .number(double)
            }
            return nil
        })
    }
    
    static var knownKeywords: StringTokenDetector {
        return StringTokenDetector(detect: { (str) -> Token? in
            switch str {
            case "place":
                return .place
            case "let":
                return .`let`
            default:
                return nil
            }
        })
    }
    
    static var identifier: StringTokenDetector {
        return StringTokenDetector(detect: { str in Token.identifier(str) })
    }
    
}

extension LexerComponent {
    
    static var parenthesis: LexerComponent {
        return LexerComponent.singleElement(detect: { (char) -> Token? in
            switch char {
            case "(":
                return .parenLeft
            case ")":
                return .parenRight
            default:
                return nil
            }
        })
    }
    
    static var operators: LexerComponent {
        return LexerComponent.singleElement(detect: { (char) -> Token? in
            switch char {
            case ">":
                return .oper(.layoutRight)
            case "<":
                return .oper(.layoutLeft)
            case "=":
                return .oper(.assign)
            case "*":
                return .object
            default:
                return nil
            }
        })
    }
    
    static var comma: LexerComponent {
        return LexerComponent.singleElement(detect: { (char) -> Token? in
            if char == "," {
                return .comma
            }
            return nil
        })
    }
    
    static var full: LexerComponent {
        let stringDetectors = StringTokenDetector.numbers
            .composed(withDetector: .knownKeywords)
            .composed(withDetector: .identifier)
        return LexerComponent.operators
            .composed(withComponent: .parenthesis)
            .composed(withComponent: .comma)
            .composed(withComponent: .string(detector: stringDetectors))
    }
    
}

class Lexer {
    
    let input: String
    var index: String.Index
    let component: LexerComponent
    
    init(input: String, component: LexerComponent) {
        self.input = input
        self.index = input.startIndex
        self.component = component
    }
    
    func char(at index: String.Index) -> Character? {
        return index < input.endIndex ? input[index] : nil
    }
    
    var currentChar: Character? {
        return char(at: index)
    }
    
    func advanceIndex(by offset: Int) {
        //        print("Advancing by \(offset)")
        input.formIndex(&index, offsetBy: offset)
    }
    
    func advance() -> Token? {
        while let char = currentChar, char.isSpace {
            advanceIndex(by: 1)
        }
        guard currentChar != nil else {
            return nil
        }
        let sub = input[index ..< input.endIndex]
        let result = component.getToken(context: String(sub).makeIterator())
        switch result {
        case .detected(let tok, let toSkip):
            advanceIndex(by: toSkip)
            return tok
        case .none:
            return nil
        }
    }
    
    func lex() -> [Token] {
        var tokens = [Token]()
        while let tok = advance() {
            tokens.append(tok)
        }
        return tokens
    }
    
}
