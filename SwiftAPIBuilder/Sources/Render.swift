//
// Created by drinking on 16/3/28.
// Copyright (c) 2016 drinking. All rights reserved.
//

import Foundation
import SwiftyJSON

public protocol DKAPIRenderProtocol {
    func renderAPIService(serviceName: String) -> String
    func renderAPITransition(transition: DKTransition) -> String
    func renderAPIHeader() -> String
    func renderDataStructure(transition: DKTransition) -> String
}

public struct DKAPIRender: DKAPIRenderProtocol {

    let text: String?
    let enableTestor:Bool
    var prefix: String {
        get {
            guard let p = getTextBetweenTag(tag: "Prefix") else { return "" }
            return p.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }

    public init(path: NSURL) {
        if let fileContent = try? NSString(contentsOf: path as URL, encoding: String.Encoding.utf8.rawValue) {
            text = fileContent as String
        } else {
            text = nil
        }
        enableTestor = true
    }

    public func renderAPIService(serviceName: String) -> String {
        if let content = getTextBetweenTag(tag: "Service") {
            return String(format: content, serviceName,serviceName,serviceName)
        }

        print("Tag Service not found")
        return ""
    }

    public func renderAPITransition(transition: DKTransition) -> String {
        let serviceName = "\(transition.serviceName)<\(transition.requestModelName),\(transition.responseModelName)>"
        let method = transition.requestMethod.description
        return "public class \(self.prefix + transition.apiName): \(serviceName) {\n \t" +
                    "public class func instance()->\(serviceName){\n" +
                    "\t\treturn \(serviceName)(subPath:\"\(transition.href)\",method:\(method))\n\t}\(renderTestor(transition: transition))\n}\n"
    }

    public func renderAPIHeader() -> String {
        return getTextBetweenTag(tag: "Headers") ?? ""
    }
    
    public func renderTestor(transition: DKTransition) -> String {
        if (enableTestor){
            return String(format: getTextBetweenTag(tag: "Testor")!, transition.requestModelName,
                          transition.responseModelName,transition.apiName,transition.requestModelName,
                          transition.apiName,transition.meta.requestType?.description ?? "GET")
        }
        return ""
    }

    public func renderDataStructure(transition: DKTransition) -> String {

        var result = ""
        
        if (transition.requestModelName.hasSuffix("_REQUEST")){
            let jsonString = transition.requestJSONString
            let modelName = transition.requestModelName
            var output = ""
            Coolie(JSONString: jsonString).printAPIModelWithName(modelName: modelName, toStream: &output)
            Coolie(JSONString: jsonString).printAPIModelExtensionWithName(modelName: modelName, toStream: &output)
            result += output
            result += "\n\n"
        }
        
        if (transition.responseModelName.hasSuffix("_RESPONSE")){
            let jsonString = transition.responseJSONString
            let modelName = transition.responseModelName
            var output = ""
            Coolie(JSONString: jsonString).printAPIModelWithName(modelName: modelName, toStream: &output)
            Coolie(JSONString: jsonString).printAPIModelExtensionWithName(modelName: modelName, toStream: &output)
            result += output
            result += "\n\n"
        }
        
        return result
    }

    func getTextBetweenTag(tag: String) -> String? {

        if let content = text {
            //TODO focus on
            let start = content.range(of: "###" + tag)
            let end = content.range(of: tag + "###")
            if let s = start, let e = end {
                let range = s.upperBound ..< e.lowerBound
                return content.substring(with: range)
            }
        }

        return nil
    }

}

extension DKTransition {

    var requestModelName: String {
        get {
            return buildModelName(contents: self.requestContents,modelName: self.apiName + "_REQUEST")
        }
    }

    var responseModelName: String {
        get {
            return buildModelName(contents: self.responseContents,modelName: self.apiName + "_RESPONSE")
        }
    }
    
    func buildModelName(contents:[JSON],modelName:String="Empty") ->String {
        
        if self.responseContents.count == 0 {
            return "Empty"
        }
        
        //first search data structure then json object else Empty
        for json in contents {
            if (json.element == .DataStructure){
                for c in json["content"].arrayValue {
                    if c["element"].stringValue == "array" {
                        for j in c["content"].arrayValue {
                            return "JSONArray<\(j["element"].stringValue)>"
                        }
                    }else{
                        return c["element"].stringValue
                    }
                }
            }
        }
        
        for json in contents {
            if (json.element == .Asset && json.hasMeta(meta: "messageBody")
                && json["content"].stringValue.characters.count>0){
                return modelName
            }
        }
        
        return "Empty"
    }
    
    
    var requestJSONString: String{
        get {
            for json in self.requestContents {
                let requestJSON = json["content"].stringValue
                if (json.element == .Asset && json.hasMeta(meta: "messageBody")
                    && requestJSON.characters.count>0){
                    return requestJSON
                }
            }
            return ""
        }
    }
    
    var responseJSONString: String{
        get {
            for json in self.responseContents {
                let responseJSON = json["content"].stringValue
                if (json.element == .Asset && json.hasMeta(meta: "messageBody")
                    && responseJSON.characters.count>0){
                    return responseJSON
                }
            }
            return ""
        }
    }
}

