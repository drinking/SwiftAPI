import Foundation
import SwiftyJSON

public enum APITransition {
    case HTTPRequest
    case HTTPResponse
    
    public var stringValue:String {
        switch self {
        case .HTTPRequest:
            return "httpRequest"
        case .HTTPResponse:
            return "httpResponse"
        }
    }
}

public extension JSON {
    
    public func contentsInTransition(name:APITransition)->[JSON]{
        return self["content"].arrayValue.filter({
        v in
        v["element"].string == "httpTransaction"
        }).flatMap{$0["content"].arrayValue}.filter({
        v in
        v["element"].string == name.stringValue
        }).flatMap{$0["content"].arrayValue}
    }
    
    public var element:DKAPIElement {
        let element = self["element"].stringValue
        if (element == "category") {
            return .Category
        } else if (element == "resource") {
            return .Resource
        } else if (element == "transition") {
            return .Transition
        } else if (element == "dataStructure") {
            return .DataStructure
        } else if (element == "parseResult"){
            return .ParseResult
        } else if (element == "object"){
            return .Object
        }else if (element == "member"){
            return .Member
        }else if (element == "asset"){
            return .Asset
        }
        return .Unknown
    }
    
    func hasMeta(meta: String) -> Bool {
        let metas = self["meta"]["classes"].arrayValue
        for m in metas {
            if m.stringValue.lowercased() == meta.lowercased() {
                return true
            }
        }
        return false
    }
    
    func structureName()->String{
        return self["meta"]["id"].stringValue
    }
    
}
