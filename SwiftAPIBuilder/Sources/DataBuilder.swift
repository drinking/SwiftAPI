import Foundation
//remove when build from workspace
import SwiftyJSON

public struct DKDataStructure {
    let json: JSON
    static func findDataStructures(json:JSON)->[JSON]{
        let content = json["content"].arrayValue
        if json.hasMeta(meta: "dataStructures"){
            return content
        }else if (content.count>0) {
            return content.map({ (json) -> [JSON] in
                return findDataStructures(json: json)
            }).reduce([], +)
        }else {
            return []
        }
    }
    
    static func parse(json:JSON)->String{
        let s = findDataStructures(json: json)
        return s.reduce("") { (result, json) -> String in
            result + DKDataStructure(json: json).generate()
        }
    }
    
    func generate() -> String {
        guard let contents = self.json["content"].array else{
            return ""
        }
        
        func construct(json:JSON)->String{
            var result = ""
            if (json.element == .Object){
                let clzName = json["meta"]["id"].stringValue.replacingOccurrences(of: " ", with: "_")
                result += "@objc public class " + clzName + ":NSObject,Mappable{\n"
            }
            
            guard let members = json["content"].array?.filter({ (json) -> Bool in
                json.element == .Member
            }) else{
                return result + "}"
            }
            
            //define properties
            
            result += members.map { (member) -> PropertyType in
                let property = PropertyType(member:member)
                result += property.description
                return property
                }.reduce("\n public override init(){} \n init?(json:[String:Any]?){ \n guard let dict = json else{ return nil}\n") { $0 + $1.initializer} + "}\n"
            
            result += genExtension(json: json)
            
            return result + "}\n"
        }
        
        return contents.reduce("") { (result, json) -> String in
            result + "\n" + construct(json: json)
        }
    }
    
    func genExtension(json:JSON)->String {
        var result = ""
        
        guard let members = json["content"].array?.filter({ (json) -> Bool in
            json.element == .Member
        }) else{
            return result + "}"
        }
        result += "required convenience public init?(map: Map){self.init(json:map.JSON)}\n"
        result += members.map {PropertyType(member:$0)}.reduce("\t public func mapping(map: Map){\n") { $0 + $1.mapper} + "}\n"
        return result
    }
    
}

public indirect enum PropertyType {
    case _String(String,String)
    case _Number(String,String)
    case _Bool(String,String)
    case _Object(String,String)
    case _Class(String,String)
    case _Array(String,PropertyType)
    
    init(type:String,value:String){ //
        switch (type.lowercased()) {
        case "string": self = ._String("","String")
        case "number":self = ._Number("",value)
        case "object": self = ._Object("",value)
        case "boolean": self = ._Bool("","Bool")
        default:
            self = ._Class("", type)
        }
    }
    
    init(member:JSON){
        
        let mType = member["content"]["value"]["element"].stringValue
        let mName = member["content"]["key"]["content"].stringValue
        if ( mType.lowercased() == "array" ) {
            let json = member["content"]["value"]["content"].arrayValue.first!
            self = ._Array(mName, PropertyType(type: json["element"].stringValue, value: json["content"].stringValue))
            return
        }
        
        let mValue = member["content"]["value"]["content"].stringValue
        switch (mType.lowercased()) {
        case "string": self = ._String(mName,"String")
        case "number":self = ._Number(mName,mValue)
        case "object": self = ._Object(mName,mValue)
        case "boolean": self = ._Bool(mName,"Bool")
        default:
            self = ._Class(mName, mType)
        }
        
    }
    
    var description:String {
        switch self {
        case ._String(let name, let type):
            return "public var \(name):\(type) = \"\" \n"
        case ._Number(let name,let value):
            return "public var \(name):\(parseNumberType(number: value)) = 0 \n"
        case ._Object(let name,let type):
            return "public var \(name):\(type)?\n"
        case ._Bool(let name, let type):
            return "public var \(name):\(type) = false\n"
        case ._Class(let name,let type):
            return "public var \(name):\(type)?\n"
        case ._Array(let name, let property):
            return "public var \(name):[\(property.arrayType)]? \n"
        }
    }
    
    var arrayType:String {
        switch self {
        case ._String(_,_):
            return "String"
        case ._Number(_,let value):
            return "\(parseNumberType(number: value))"
        case ._Object(_,let type):
            return type
        case ._Bool(_,_):
            return "Bool"
        case ._Class(_,let type):
            return type
        case ._Array(_,_):
            return "Array"
        }
    }
    
    var arrayRawType:String {
        switch self {
        case ._String(_,_):
            return "String"
        case ._Number(_,let value):
            return "\(parseNumberType(number: value))"
        case ._Object(_,_):
            return "[String:AnyObject]"
        case ._Bool(_,_):
            return "Bool"
        case ._Class(_,_):
            return "[String:AnyObject]"
        case ._Array(_,_):
            return "Array"
        }
    }
    
    var initializer:String{
        switch self {
        case ._String(let name, _):
            return "self.\(name) <= dict[\"\(name)\"] \n"
        case ._Number(let name, _):
            return "self.\(name) <= dict[\"\(name)\"] \n"
        case ._Object(let name,let type):
            return "self.\(name) = \(type)(json:dict[\"\(name)\"] as? [String:AnyObject])\n"
        case ._Bool(let name, _):
            return "self.\(name) <= dict[\"\(name)\"] \n"
        case ._Class(let name,let type):
            return "self.\(name) = \(type)(json:dict[\"\(name)\"] as? [String:AnyObject])\n"
        case ._Array(let name, let property):
            return "self.\(name) = (dict[\"\(name)\"] as? [\(property.arrayRawType)]).flatMap{$0.flatMap{\(property.construction)}}\n"
        }
    }
    
    var mapper:String{
        switch self {
        case ._String(let name, _):
            return "\(name) <- map[\"\(name)\"] \n"
        case ._Number(let name,_):
            return "\(name) <- map[\"\(name)\"] \n"
        case ._Object(let name,_):
            return "\(name) <- map[\"\(name)\"] \n"
        case ._Bool(let name, _):
            return "\(name) <- map[\"\(name)\"] \n"
        case ._Class(let name,_):
            return "\(name) <- map[\"\(name)\"] \n"
        case ._Array(let name, _):
            return "\(name) <- map[\"\(name)\"] \n"
        }
    }
    
    var construction:String{
        switch self {
        case ._Object(_,let type):
            return "\(type)(json: $0)"
        case ._Class(_,let type):
            return "\(type)(json: $0)"
        default:
            return "$0"
        }
    }
    
    func parseNumberType(number:String)->String{
        if(number.contains(".")){
            return "Float"
        }else{
            return "Int"
        }
    }
    
}
