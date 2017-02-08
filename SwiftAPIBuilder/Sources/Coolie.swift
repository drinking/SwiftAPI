//
//  Coolie.swift
//  Coolie
//
//  Created by NIX on 16/1/23.
//  Copyright © 2016年 nixWork. All rights reserved.
//

import Foundation

public class Coolie {
    
    private let scanner: Scanner
    
    public init(JSONString: String) {
        scanner = Scanner(string: JSONString)
    }
    
    public func printModelWithName(modelName: String) {
        if let value = parse() {
            //value.printAtLevel(0, modelName: modelName)
            value.printStruct(level: 0, modelName: modelName)
        } else {
            print("Parse failed!")
        }
    }
    
    public func printApibModelWithName(modelName:String)->String{
        if let value = parse() {
            var result = ""
            value.outPutApibModel(modelName: modelName,toStream: &result)
            return result
        }
        return ""
    }
    
    public func printObjCModelWithName(modelName:String)->String{
        if let value = parse() {
            var result = ""
            value.outPutObjcModel(modelName: modelName,toStream: &result)
            return result
        }
        return ""
    }
    
    public func printSwiftMappableModelWithName(modelName:String)->String{
        var result = ""
        outPutSwiftMappableModel(modelName: modelName, toStream: &result)
        return result
    }
    
    fileprivate enum Token {
        
        case BeginObject(Swift.String)      // {
        case EndObject(Swift.String)        // }
        
        case BeginArray(Swift.String)       // [
        case EndArray(Swift.String)         // ]
        
        case Colon(Swift.String)            // ;
        case Comma(Swift.String)            // ,
        
        case Bool(Swift.Bool)               // true or false
        enum NumberType {
            case Int(Swift.Int)
            case Double(Swift.Double)
        }
        case Number(NumberType)             // 42, 99.99
        case String(Swift.String)           // "nix", ...
        
        case Null
    }
    
    fileprivate enum Value {
        
        case Bool(Swift.Bool)
        enum NumberType {
            case Int(Swift.Int)
            case Double(Swift.Double)
        }
        case Number(NumberType)
        case String(Swift.String)
        
        case Null
        
        indirect case Dictionary([Swift.String: Value])
        indirect case Array(name: Swift.String?, values: [Value])
        
        
    }
    
    lazy var numberScanningSet: NSCharacterSet = {
        let symbolSet = NSMutableCharacterSet.decimalDigit()
        symbolSet.addCharacters(in: ".-")
        return symbolSet
    }()
    
    lazy var stringScanningSet: NSCharacterSet = {
        let symbolSet = NSMutableCharacterSet.alphanumeric()
        symbolSet.formUnion(with: NSCharacterSet.punctuationCharacters)
        symbolSet.formUnion(with: NSCharacterSet.symbols)
        symbolSet.formUnion(with: NSCharacterSet.whitespacesAndNewlines)
        symbolSet.removeCharacters(in: "\"")
        return symbolSet
    }()
    
    private func generateTokens() -> [Token] {
        
        func scanBeginObject() -> Token? {
            
            if scanner.scanString("{", into: nil) {
                return .BeginObject("{")
            }
            
            return nil
        }
        
        func scanEndObject() -> Token? {
            
            if scanner.scanString("}", into: nil) {
                return .EndObject("}")
            }
            
            return nil
        }
        
        func scanBeginArray() -> Token? {
            
            if scanner.scanString("[", into: nil) {
                return .BeginArray("[")
            }
            
            return nil
        }
        
        func scanEndArray() -> Token? {
            
            if scanner.scanString("]", into: nil) {
                return .EndArray("]")
            }
            
            return nil
        }
        
        func scanColon() -> Token? {
            
            if scanner.scanString(":", into: nil) {
                return .Colon(":")
            }
            
            return nil
        }
        
        func scanComma() -> Token? {
            
            if scanner.scanString(",", into: nil) {
                return .Comma(",")
            }
            
            return nil
        }
        
        func scanBool() -> Token? {
            
            if scanner.scanString("true", into: nil) {
                return .Bool(true)
            }
            
            if scanner.scanString("false", into: nil) {
                return .Bool(false)
            }
            
            return nil
        }
        
        func scanNumber() -> Token? {
            
            var string: NSString?
            
            if scanner.scanCharacters(from: numberScanningSet as CharacterSet, into: &string) {
                
                if let string = string as? String {
                    
                    if let number = Int(string) {
                        return .Number(.Int(number))
                        
                    } else if let number = Double(string) {
                        return .Number(.Double(number))
                    }
                }
            }
            
            return nil
        }
        
        func scanString() -> Token? {
            
            var string: NSString?
            
            if scanner.scanString("\"\"", into: nil) {
                return .String("")
            }
            
            if scanner.scanString("\"", into: nil) &&
                scanner.scanCharacters(from: stringScanningSet as CharacterSet, into: &string) &&
                scanner.scanString("\"", into: nil) {
                
                if let string = string as? String {
                    return .String(string)
                }
            }
            
            return nil
        }
        
        func scanNull() -> Token? {
            
            if scanner.scanString("null", into: nil) {
                return .Null
            }
            
            return nil
        }
        
        var tokens = [Token]()
        
        while !scanner.isAtEnd {
            
            let previousScanLocation = scanner.scanLocation
            
            if let token = scanBeginObject() {
                tokens.append(token)
            }
            
            if let token = scanEndObject() {
                tokens.append(token)
            }
            
            if let token = scanBeginArray() {
                tokens.append(token)
            }
            
            if let token = scanEndArray() {
                tokens.append(token)
            }
            
            if let token = scanColon() {
                tokens.append(token)
            }
            
            if let token = scanComma() {
                tokens.append(token)
            }
            
            if let token = scanBool() {
                tokens.append(token)
            }
            
            if let token = scanNumber() {
                tokens.append(token)
            }
            
            if let token = scanString() {
                tokens.append(token)
            }
            
            if let token = scanNull() {
                tokens.append(token)
            }
            
            let currentScanLocation = scanner.scanLocation
            guard currentScanLocation > previousScanLocation else {
                print("Not found valid token")
                break
            }
        }
        
        return tokens
    }
    
    fileprivate func parse() -> Value? {
        
        let tokens = generateTokens()
        
        guard !tokens.isEmpty else {
            print("No tokens")
            return nil
        }
        
        var next = 0
        
        func parseValue() -> Value? {
            
            guard let token = tokens[safe: next] else {
                print("No token for parseValue")
                return nil
            }
            
            switch token {
                
            case .BeginArray:
                
                var arrayName: String?
                let nameIndex = next - 2
                if nameIndex >= 0 {
                    if let nameToken = tokens[safe: nameIndex] {
                        if case .String(let name) = nameToken {
                            arrayName = name.capitalized
                        }
                    }
                }
                
                next += 1
                return parseArray(name: arrayName)
                
            case .BeginObject:
                next += 1
                return parseObject()
                
            case .Bool:
                return parseBool()
                
            case .Number:
                return parseNumber()
                
            case .String:
                return parseString()
                
            case .Null:
                return parseNull()
                
            default:
                return nil
            }
        }
        
        func parseArray(name: String? = nil) -> Value? {
            
            guard let token = tokens[safe: next] else {
                print("No token for parseArray")
                return nil
            }
            
            var array = [Value]()
            
            if case .EndArray = token {
                next += 1
                return .Array(name: name, values: array)
                
            } else {
                while true {
                    guard let value = parseValue() else {
                        break
                    }
                    
                    array.append(value)
                    
                    if let token = tokens[safe: next] {
                        
                        if case .EndArray = token {
                            next += 1
                            return .Array(name: name, values: array)
                            
                        } else {
                            guard let _ = parseComma() else {
                                print("Expect comma")
                                break
                            }
                            
                            guard let nextToken = tokens[safe: next] , nextToken.isNotEndArray else {
                                print("Invalid JSON, comma at end of array")
                                break
                            }
                        }
                    }
                }
                
                return nil
            }
        }
        
        func parseObject() -> Value? {
            
            guard let token = tokens[safe: next] else {
                print("No token for parseObject")
                return nil
            }
            
            var dictionary = [String: Value]()
            
            if case .EndObject = token {
                next += 1
                return .Dictionary(dictionary)
                
            } else {
                while true {
                    guard let key = parseString(), let _ = parseColon(), let value = parseValue() else {
                        print("Expect key : value")
                        break
                    }
                    
                    if case .String(let key) = key {
                        dictionary[key] = value
                    }
                    
                    if let token = tokens[safe: next] {
                        
                        if case .EndObject = token {
                            next += 1
                            return .Dictionary(dictionary)
                            
                        } else {
                            guard let _ = parseComma() else {
                                print("Expect comma")
                                break
                            }
                            
                            guard let nextToken = tokens[safe: next] , nextToken.isNotEndObject else {
                                print("Invalid JSON, comma at end of object")
                                break
                            }
                        }
                    }
                }
            }
            
            return nil
        }
        
        func parseColon() -> Value? {
            
            defer {
                next += 1
            }
            
            guard let token = tokens[safe: next] else {
                print("No token for parseColon")
                return nil
            }
            
            if case .Colon(let string) = token {
                return .String(string)
            }
            
            return nil
        }
        
        func parseComma() -> Value? {
            
            defer {
                next += 1
            }
            
            guard let token = tokens[safe: next] else {
                print("No token for parseComma")
                return nil
            }
            
            if case .Comma(let string) = token {
                return .String(string)
            }
            
            return nil
        }
        
        func parseBool() -> Value? {
            
            defer {
                next += 1
            }
            
            guard let token = tokens[safe: next] else {
                print("No token for parseBool")
                return nil
            }
            
            if case .Bool(let bool) = token {
                return .Bool(bool)
            }
            
            return nil
        }
        
        func parseNumber() -> Value? {
            
            defer {
                next += 1
            }
            
            guard let token = tokens[safe: next] else {
                print("No token for parseNumber")
                return nil
            }
            
            if case .Number(let number) = token {
                switch number {
                case .Int(let int):
                    return .Number(.Int(int))
                case .Double(let double):
                    return .Number(.Double(double))
                }
            }
            
            return nil
        }
        
        func parseString() -> Value? {
            
            defer {
                next += 1
            }
            
            guard let token = tokens[safe: next] else {
                print("No token for parseString")
                return nil
            }
            
            if case .String(let string) = token {
                return .String(string)
            }
            
            return nil
        }
        
        func parseNull() -> Value? {
            
            defer {
                next += 1
            }
            
            guard let token = tokens[safe: next] else {
                print("No token for parseNull")
                return nil
            }
            
            if case .Null = token {
                return .Null
            }
            
            return nil
        }
        
        return parseValue()
    }
}

private extension Coolie.Value {
    
    var type: Swift.String {
        switch self {
        case .Bool:
            return "Bool"
        case .Number(let number):
            switch number {
            case .Int:
                return "Int"
            case .Double:
                return "Double"
            }
        case .String:
            return "String"
        case .Null:
            return "UnknownType?"
        default:
            fatalError("Unknown type")
        }
    }
    
    var apibType: Swift.String {
        switch self {
        case .Bool:
            return "boolean"
        case .Number(_):
            return "number"
        case .String:
            return "string"
        case .Null:
            return "Unknown"
        default:
            fatalError("Unknown type")
        }
    }
    
    var objCType: Swift.String {
        switch self {
        case .Bool:
            return "NSNumber"
        case .Number(_):
            return "NSNumber"
        case .String:
            return "NSString"
        case .Null:
            return "NSNull"
        default:
            fatalError("Unknown type")
        }
    }
    
    var isDictionaryOrArray: Swift.Bool {
        switch self {
        case .Dictionary:
            return true
        case .Array:
            return true
        default:
            return false
        }
    }
    
    var isDictionary: Swift.Bool {
        switch self {
        case .Dictionary:
            return true
        default:
            return false
        }
    }
    
    var isArray: Swift.Bool {
        switch self {
        case .Array:
            return true
        default:
            return false
        }
    }
    
    var isNull: Swift.Bool {
        switch self {
        case .Null:
            return true
        default:
            return false
        }
    }
}

private extension Coolie.Token {
    
    var isNotEndObject: Swift.Bool {
        switch self {
        case .EndObject:
            return false
        default:
            return true
        }
    }
    
    var isNotEndArray: Swift.Bool {
        switch self {
        case .EndArray:
            return false
        default:
            return true
        }
    }
}

private extension Coolie.Value {
    
    func unionValues(values: [Coolie.Value]) -> Coolie.Value? {
        
        guard values.count > 1 else {
            return values.first
        }
        
        if let first = values.first, case .Dictionary(let firstInfo) = first {
            
            var info: [Swift.String: Coolie.Value] = firstInfo
            
            let keys = firstInfo.keys
            
            for i in 1..<values.count {
                let next = values[i]
                if case .Dictionary(let nextInfo) = next {
                    for key in keys {
                        if let value = nextInfo[key] , !value.isNull {
                            info[key] = value
                        }
                    }
                }
            }
            
            return .Dictionary(info)
        }
        
        return values.first
    }
}

private extension Coolie.Value {
    
    func printAtLevel(level: Int, modelName: Swift.String? = nil) {
        
        func indentLevel(level: Int) {
            for _ in 0..<level {
                print("\t", terminator: "")
            }
        }
        
        switch self {
            
        case .Bool, .Number, .String, .Null:
            print(type)
            
        case .Dictionary(let info):
            // struct name
            indentLevel(level: level)
            print("struct \(modelName ?? "Model") {")
            
            // properties
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        value.printAtLevel(level: level + 1, modelName: key.capitalized)
                        indentLevel(level: level + 1)
                        if value.isArray {
                            if case .Array(_, let values) = value, let unionValue = unionValues(values: values) , !unionValue.isDictionaryOrArray {
                                print("let \(key.coolie_lowerCamelCase): [\(unionValue.type)]", terminator: "\n")
                            } else {
                                print("let \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)]", terminator: "\n")
                            }
                        } else {
                            print("let \(key.coolie_lowerCamelCase): \(key.capitalized)", terminator: "\n")
                        }
                    } else {
                        indentLevel(level: level + 1)
                        print("let \(key.coolie_lowerCamelCase): ", terminator: "")
                        value.printAtLevel(level: level)
                    }
                }
            }
            
            // generate method
            indentLevel(level: level + 1)
            print("static func fromJSONDictionary(info: [String: AnyObject]) -> \(modelName ?? "Model")? {")
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        if value.isDictionary {
                            indentLevel(level: level + 2)
                            print("guard let \(key.coolie_lowerCamelCase)JSONDictionary = info[\"\(key)\"] as? [String: AnyObject] else { return nil }")
                            indentLevel(level: level + 2)
                            print("guard let \(key.coolie_lowerCamelCase) = \(key.capitalized).fromJSONDictionary(\(key.coolie_lowerCamelCase)JSONDictionary) else { return nil }")
                        } else if value.isArray {
                            if case .Array(_, let values) = value, let unionValue = unionValues(values: values) , !unionValue.isDictionaryOrArray {
                                indentLevel(level: level + 2)
                                if unionValue.isNull {
                                    print("let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? UnknownType")
                                } else {
                                    print("guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? [\(unionValue.type)] else { return nil }")
                                }
                            } else {
                                indentLevel(level: level + 2)
                                print("guard let \(key.coolie_lowerCamelCase)JSONArray = info[\"\(key)\"] as? [[String: AnyObject]] else { return nil }")
                                indentLevel(level: level + 2)
                                print("let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalized.coolie_dropLastCharacter).fromJSONDictionary($0) }).flatMap({ $0 })")
                            }
                        }
                    } else {
                        indentLevel(level: level + 2)
                        if value.isNull {
                            print("let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? UnknownType")
                        } else {
                            print("guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(value.type) else { return nil }")
                        }
                    }
                }
            }
            
            // return model
            indentLevel(level: level + 2)
            print("return \(modelName ?? "Model")(", terminator: "")
            let lastIndex = info.keys.count - 1
            for (index, key) in info.keys.sorted().enumerated() {
                let suffix = (index == lastIndex) ? ")" : ", "
                print("\(key.coolie_lowerCamelCase): \(key.coolie_lowerCamelCase)" + suffix, terminator: "")
            }
            print("")
            
            indentLevel(level: level + 1)
            print("}")
            
            indentLevel(level: level)
            print("}")
            
        case .Array(let name, let values):
            if let unionValue = unionValues(values: values) {
                if unionValue.isDictionaryOrArray {
                    unionValue.printAtLevel(level:level, modelName: name?.coolie_dropLastCharacter)
                }
            }
        }
    }
}

private extension Coolie.Value {
    
    func printStruct(level: Int, modelName: Swift.String? = nil) {
        
        func indentLevel(level: Int) {
            for _ in 0..<level {
                print("\t", terminator: "")
            }
        }
        
        switch self {
            
        case .Bool, .Number, .String, .Null:
            print(type)
            
        case .Dictionary(let info):
            // struct name
            indentLevel(level: level)
            print("struct \(modelName ?? "Model") {")
            
            // properties
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        value.printStruct(level: level + 1, modelName: key.capitalized)
                        indentLevel(level: level + 1)
                        if value.isArray {
                            if case .Array(_, let values) = value, let unionValue = unionValues(values: values) , !unionValue.isDictionaryOrArray {
                                print("let \(key.coolie_lowerCamelCase): [\(unionValue.type)]", terminator: "\n")
                            } else {
                                print("let \(key.coolie_lowerCamelCase): [\(key.capitalized.coolie_dropLastCharacter)]", terminator: "\n")
                            }
                        } else {
                            print("let \(key.coolie_lowerCamelCase): \(key.capitalized)", terminator: "\n")
                        }
                    } else {
                        indentLevel(level: level + 1)
                        print("let \(key.coolie_lowerCamelCase): ", terminator: "")
                        value.printStruct(level: level)
                    }
                }
            }
            
            // generate method
            indentLevel(level: level + 1)
            print("init?(_ info: [String: AnyObject]) {")
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        if value.isDictionary {
                            indentLevel(level: level + 2)
                            print("guard let \(key.coolie_lowerCamelCase)JSONDictionary = info[\"\(key)\"] as? [String: AnyObject] else { return nil }")
                            indentLevel(level: level + 2)
                            print("guard let \(key.coolie_lowerCamelCase) = \(key.capitalized)(\(key.coolie_lowerCamelCase)JSONDictionary) else { return nil }")
                        } else if value.isArray {
                            if case .Array(_, let values) = value, let unionValue = unionValues(values: values) , !unionValue.isDictionaryOrArray {
                                indentLevel(level: level + 2)
                                if unionValue.isNull {
                                    print("let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? UnknownType")
                                } else {
                                    print("guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? [\(unionValue.type)] else { return nil }")
                                }
                            } else {
                                indentLevel(level: level + 2)
                                print("guard let \(key.coolie_lowerCamelCase)JSONArray = info[\"\(key)\"] as? [[String: AnyObject]] else { return nil }")
                                indentLevel(level: level + 2)
                                print("let \(key.coolie_lowerCamelCase) = \(key.coolie_lowerCamelCase)JSONArray.map({ \(key.capitalized.coolie_dropLastCharacter)($0) }).flatMap({ $0 })")
                            }
                        }
                    } else {
                        indentLevel(level: level + 2)
                        if value.isNull {
                            print("let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? UnknownType")
                        } else {
                            print("guard let \(key.coolie_lowerCamelCase) = info[\"\(key)\"] as? \(value.type) else { return nil }")
                        }
                    }
                }
            }
            
            for key in info.keys.sorted() {
                indentLevel(level: level + 2)
                let property = key.coolie_lowerCamelCase
                print("self.\(property) = \(property)")
            }
            
            indentLevel(level: level + 1)
            print("}")
            
            indentLevel(level: level)
            print("}")
            
        case .Array(let name, let values):
            if let unionValue = unionValues(values: values) {
                if unionValue.isDictionaryOrArray {
                    unionValue.printStruct(level: level, modelName: name?.coolie_dropLastCharacter)
                }
            }
        }
    }
}

private extension String {
    
    var coolie_dropLastCharacter: String {
        
        if characters.count > 0 {
            return String(characters.dropLast())
        }
        
        return self
    }
    
    var coolie_lowerCamelCase: String {
        
        let symbolSet = NSMutableCharacterSet.alphanumeric()
        symbolSet.addCharacters(in: "_")
        symbolSet.invert()
        
        
        
        let validString = self.components(separatedBy: symbolSet as CharacterSet).joined(separator:"_")
        let parts = validString.components(separatedBy: "_")
        
        return parts.enumerated().map({ index, part in
            return index == 0 ? part : part.capitalized
        }).joined(separator: "")
    }
    
    var coolie_StructureCase:String {
        let symbolSet = NSMutableCharacterSet.alphanumeric()
        symbolSet.addCharacters(in: "_")
        symbolSet.invert()
        
        let validString = self.components(separatedBy: symbolSet as CharacterSet).joined(separator:"_")
        let parts = validString.components(separatedBy: "_")
        
        return parts.enumerated().map({ index, part in
            return part.capitalized
        }).joined(separator:"_")
    }
}

private extension Array {
    
    subscript (safe index: Int) -> Element? {
        return index >= 0 && index < count ? self[index] : nil
    }
}

// extensions for API builder

private extension String {
    
    var coolie_dropLastCharIfNeeded: String {
        if (self.lowercased() == "value") {
            //DKAPI first Key
            return self
        } else {
            return coolie_dropLastCharacter
        }
    }
    
}

extension Coolie {
    
    public func printAPIModelExtensionWithName(modelName: String, toStream output: inout String) {
        if let value = parse() {
            value.apiPrintExtensionAtLevel(level: 0, modelName: modelName, toStream: &output)
        } else {
            print("Parse failed!")
        }
    }
    
    public func printAPIModelWithName(modelName: String, toStream output: inout String) {
        if let value = parse() {
            value.apiPrintAtLevel(level: 0, modelName: modelName, toStream: &output)
        } else {
            print("Parse failed!")
        }
    }
    
    public func outPutSwiftMappableModel(modelName: String, toStream output: inout String){
        if let value = parse() {
            value.apiPrintAtLevel(level: 0, modelName: modelName, toStream: &output)
            value.apiPrintExtensionAtLevel(level: 0, modelName: modelName, toStream: &output)
        }
    }
    
}

extension Coolie.Value {
    
    public func apiPrintAtLevel(level: Int, modelName: Swift.String? = nil) {
        var output = ""
        apiPrintAtLevel(level: level, modelName: modelName, toStream: &output)
        print(output)
    }
    
    public func apiPrintAtLevel(level: Int, modelName: Swift.String? = nil, toStream output: inout Swift.String) {
        
        func indentLevel(level: Int) {
            for _ in 0 ..< level {
                print("\t", terminator: "", to: &output)
            }
        }
        
        switch self {
            
        case .Bool:
            print(type + " = false", to: &output)
        case .Number:
            print(type + " = 0", to: &output)
        case .String:
            print(type + " = \"\"", to: &output)
        case .Null:
            print(type + "?", to: &output)
            
        case .Dictionary(let info):
            // struct name
            indentLevel(level: level)
            if let modelName = modelName {
                print("@objc public class \(modelName) :NSObject, Mappable{", to: &output)
            } else {
                print("@objc public class Model :NSObject, Mappable{", to: &output)
            }
            
            // properties
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        value.apiPrintAtLevel(level: level + 1, modelName: key.capitalized, toStream: &output)
                        indentLevel(level: level + 1)
                        if value.isArray {
                            if case .Array(_, let values) = value, let first = values.first , !first.isDictionaryOrArray {
                                print("public var \(key): [\(first.type)]?", terminator: "\n", to: &output)
                            } else {
                                print("public var \(key): [\(key.capitalized.coolie_dropLastCharIfNeeded)]?", terminator: "\n", to: &output)
                            }
                        } else {
                            print("public var \(key): \(key.capitalized)?", terminator: "\n", to: &output)
                        }
                    } else {
                        indentLevel(level: level + 1)
                        print("public var \(key): ", terminator: "", to: &output)
                        value.apiPrintAtLevel(level: level, toStream: &output)
                    }
                }
            }
            
            // initializer
            
            print ("public override init(){}\n",to:&output)
            print ("init?(json:[String:Any]?){ \n guard let dict = json else{ return nil}\n",to:&output)
            
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionaryOrArray {
                        value.apiPrintAtLevel(level: level + 1, modelName: key.capitalized, toStream: &output)
                        indentLevel(level: level + 1)
                        if value.isArray {
                            if case .Array(_, let values) = value, let first = values.first , !first.isDictionaryOrArray {
                                
                                print("self.\(key) = (dict[\"\(key)\"] as? [\(first.type)]).flatMap{$0.flatMap{$0}}", terminator: "\n", to: &output)
                            } else {
                                print("self.\(key) = (dict[\"\(key)\"] as? [[String:AnyObject]]).flatMap{$0.flatMap{\(key.capitalized.coolie_dropLastCharIfNeeded)(json: $0)}}", terminator: "\n", to: &output)
                            }
                        } else {
                            print("self.\(key) = \(key.capitalized)(json: (dict[\"\(key)\"] as? [String:AnyObject]))", terminator: "\n", to: &output)
                        }
                    } else {
                        indentLevel(level: level + 1)
                        print("self.\(key) <= dict[\"\(key)\"] \n", terminator: "", to: &output)
                    }
                }
            }
            print("}", to: &output)
            // end initializer 
            
        case .Array(let name, let values):
            if let first = values.first {
                if first.isDictionaryOrArray {
                    first.apiPrintAtLevel(level: level, modelName: name?.coolie_dropLastCharIfNeeded, toStream: &output)
                }
            }
        }
    }
    
    
    func apiPrintExtensionAtLevel(level: Int, modelName: Swift.String? = nil, toStream output: inout Swift.String) {
        
        func indentLevel(level: Int) {
            for _ in 0 ..< level {
                print("\t", terminator: "", to: &output)
            }
        }
        
        switch self {
            
        case .Dictionary(let info):
            indentLevel(level: level)
            if let name = modelName {
                printExtension(info: info, modelName: name, toStream: &output)
            }
            
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isDictionary {
                        let name = "\(modelName!).\(key.capitalized)"
                        value.apiPrintExtensionAtLevel(level: level + 1, modelName: name, toStream: &output)
                    } else if value.isArray {
                        switch (value) {
                        case .Array(let name, let values):
                            if let first = values.first {
                                if first.isDictionaryOrArray {
                                    if let n = name,
                                        let mn = modelName {
                                        let an = "\(mn).\(n.capitalized.coolie_dropLastCharIfNeeded)"
                                        first.apiPrintExtensionAtLevel(level: level, modelName: an, toStream: &output)
                                    }
                                }
                            }
                        default: break;
                        }
                    }
                    
                }
            }
            
        case .Array(let name, let values):
            if let first = values.first {
                if first.isDictionaryOrArray {
                    if let n = name,
                        let mn = modelName {
                        let an = "\(mn).\(n.capitalized.coolie_dropLastCharIfNeeded)"
                        first.apiPrintExtensionAtLevel(level: level, modelName: an, toStream: &output)
                    }
                }
            }
        default: break;
        }
    }
    
    
    func printExtension(info: [Swift.String:Coolie.Value], modelName: Swift.String, toStream output: inout Swift.String) {
        
        print("required convenience public init?(map: Map){self.init(json:map.JSON)}\n", to: &output)
        print("public func mapping(map: Map){", to: &output)
        for key in info.keys.sorted() {
            if let _ = info[key] {
                print("\(key) <- map[\"\(key)\"] \n", terminator: "", to: &output)
            }
        }
        print("}\n", to: &output)
    }
    
}

extension Coolie.Value {
    
    func extractDictionaryOrArray(name:Swift.String,input:Coolie.Value)->[Swift.String:Coolie.Value]{
        
        var structures:[Swift.String:Coolie.Value] = [:]
        structures[name] = input
        
        switch input {
        case .Dictionary(let info):
            for key in info.keys.sorted() {
                if let value = info[key] {
                    if value.isArray {
                        if case .Array(_, let values) = value, let first = values.first , !first.isDictionaryOrArray {
                            let dict = extractDictionaryOrArray(name: key, input: first)
                            for (k,v) in dict {
                                structures.updateValue(v, forKey: k)
                            }
                        }
                    } else if (value.isDictionary) {
                        let dict = extractDictionaryOrArray(name: key, input: value)
                        for (k,v) in dict {
                            structures.updateValue(v, forKey: k)
                        }
                    }
                }
            }
            
        case .Array(let name, let values):
            if let first = values.first {
                let dict = extractDictionaryOrArray(name: name!, input: first)
                for (k,v) in dict {
                    structures.updateValue(v, forKey: k)
                }
            }
        default:break
        }
        return structures
    }
}

extension Coolie.Value {
    
    func outPutApibModel(modelName: Swift.String, toStream output: inout Swift.String) {
        
        let structures = extractDictionaryOrArray(name: modelName, input: self)
        
        for (name,structure) in structures{
            print("## \(name.uppercased()) (object)", to: &output)
            switch structure {
            case .Dictionary(let info):
                for key in info.keys.sorted() {
                    if let value = info[key] {
                        if value.isDictionary {
                            print("+ \(key): (\(key.uppercased())) \n", terminator: "", to: &output)
                        }else if value.isArray{
                            print("+ \(key): (array[\(key.uppercased())]) \n", terminator: "", to: &output)
                        }else {
                            
                            switch (value){
                            case .Number(let n):
                                switch n {
                                case .Int(let i):
                                    print("+ \(key): \(i) (\(value.apibType)) \n", terminator: "", to: &output)
                                case .Double(let d):
                                    print("+ \(key): \(d) (\(value.apibType)) \n", terminator: "", to: &output)
                                }
                                
                            default:
                                print("+ \(key): (\(value.apibType)) \n", terminator: "", to: &output)
                            }
                        }
                    }
                }
            default:continue
            }
         
            print("\n ", to: &output)
        }
    }
    
    
    func outPutObjcModel(modelName: Swift.String, toStream output: inout Swift.String) {
        
        let structures = extractDictionaryOrArray(name: modelName, input: self)
        
        for (name,structure) in structures{
            print("@interface \(name.uppercased()) : NSObject", to: &output)
            switch structure {
            case .Dictionary(let info):
                for key in info.keys.sorted() {
                    if let value = info[key] {
                        if value.isDictionary {
                            print("@property(nonatomic, strong) \(key.uppercased()) *\(key);\n", terminator: "", to: &output)
                        }else if value.isArray{
                            print("@property(nonatomic, strong) NSArray *\(key);\n", terminator: "", to: &output)
                        }else {
                            let attribute = value.objCType == "NSString" ? "copy" : "strong"
                            print("@property(nonatomic, \(attribute)) \(value.objCType) *\(key); \n", terminator: "", to: &output)
                        }
                    }
                }
            default:continue
            }
            print("@end \n", to: &output)
        }
    }

}
