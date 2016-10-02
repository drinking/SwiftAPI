//
// Created by drinking on 16/1/26.
// Copyright (c) 2016 drinking. All rights reserved.
//

import Foundation
import SwiftyJSON

enum DKAPIRequestMethod: CustomStringConvertible {
    case GET
    case POST
    case NONE

    init(_ method: String) {
        switch (method.uppercased()) {
        case "POST": self = .POST
        case "GET":self = .GET
        default: self = .NONE
        }
    }

    var description: String {
        switch (self) {
        case .GET: return ".get"
        case .POST: return ".post"
        case .NONE: return ".get"
        }
    }

    var paramsEncoding: String {
        switch (self) {
        case .POST: return ".JSON"
        case .GET: return ".URL"
        default: return ".URL"
        }
    }
}

public enum DKAPIElement {
    case ResourceGroup
    case Resource
    case Transition
    case Category
    case DataStructure
    case Asset
    case ParseResult
    case Object
    case Member
    case Unknown
}

class DKAPIMeta {

    var groupName: String?
    var resourceName: String?
    var serviceName: String?
    var type: DKAPIElement?
    var name: String?
    var requestType: DKAPIRequestMethod?
    var reqModel: String?
    var respModel: String?
    var herf: String?
    var rawJSON: JSON?

    init() {

    }

    init(groupName: String?, resourceName: String?, serviceName: String?, type: DKAPIElement?, name: String?,
         requestType: DKAPIRequestMethod?, reqModel: String?, respModel: String?, herf: String?, rawJSON: JSON?) {
        self.groupName = groupName
        self.resourceName = resourceName
        self.serviceName = serviceName
        self.type = type
        self.name = name
        self.requestType = requestType
        self.reqModel = reqModel
        self.respModel = respModel
        self.herf = herf
        self.rawJSON = rawJSON
    }

    static func parse(json: JSON) -> [DKAPIMeta] {
        let meta = DKAPIMeta()
        meta.rawJSON = json
        meta.type = json.element
        return meta.parse()
    }

    func parse() -> [DKAPIMeta] {

        if let json = rawJSON {
            let type = json.element
            if(type == .ParseResult){
                return json["content"].arrayValue.map {
                    createInheritor(type: $0.element)($0)
                    }.flatMap {
                        (meta) -> [DKAPIMeta] in
                        meta.parse()
                }
            }else if (type == .Category) {
                grabInfoFromCategory(json: json)
                return json["content"].arrayValue.map {
                    createInheritor(type: $0.element)($0)
                }.flatMap {
                    (meta) -> [DKAPIMeta] in
                    meta.parse()
                }
            } else if (type == .Resource) {
                self.herf = json["attributes"]["href"].stringValue
                self.resourceName = json["meta"]["title"].stringValue
                return json["content"].arrayValue.map {
                    createInheritor(type: .Transition)($0)
                }.flatMap {
                    (meta) -> [DKAPIMeta] in
                    meta.parse()
                }
            } else if (type == .Transition) {
                return [self]
            } else {
                return []
            }
        }

        return []
    }

    func grabInfoFromCategory(json: JSON) {
        if (json.hasMeta(meta: "api")) {
            self.serviceName = json["meta"]["title"].stringValue.uppercased().appending("APIService")
        }

        if (json.hasMeta(meta: "resourceGroup")) {
            self.groupName = json["meta"]["title"].stringValue
        }
    }

    func createInheritor(type: DKAPIElement) -> ((JSON) -> DKAPIMeta) {
        return {
            json in
            DKAPIMeta(groupName: self.groupName, resourceName: self.resourceName, serviceName: self.serviceName,
                    type: type, name: self.name, requestType: self.requestType, reqModel: self.reqModel,
                    respModel: self.respModel, herf: self.herf, rawJSON: json)
        }

    }
}

public class DKAPIBuilder {

    var serviceName: String?
    var transitions: [DKTransition] = []
    let render: DKAPIRenderProtocol

    public init(render: DKAPIRenderProtocol) {
        self.render = render
    }

    func readASTFileAt(path: NSURL) -> JSON? {
        if let fileContent = try? NSString(contentsOf: path as URL, encoding: String.Encoding.utf8.rawValue) {
            if let dataFromString = fileContent.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                return JSON(data: dataFromString)
            }
        }
        return nil
    }
    
    public func parseAST(jsonString:String)->String?{
        let json = JSON.parse(jsonString)
        let result = parseJson(json: json) +  DKDataStructure.parse(json: json)
        return result
    }

    public func parseASTFileAt(path: NSURL, outputPath: NSURL) {
        
        guard let json = readASTFileAt(path: path) else {
            print("Read file failure")
            return
        }
        
        print("Begin parsing \(serviceName ?? "")")
        let result = parseJson(json: json) +  DKDataStructure.parse(json: json)
        outputSwiftAPI(code: result)(outputPath)
        print("Finished \(serviceName ?? "") parsing...")
    }

    func parseJson(json: JSON) -> String {
        parseAPIBluePrintJSON(json: json)
        var output = self.render.renderAPIHeader()
        
//        precondition(self.serviceName != nil, "Service name can't be nil")
        if (self.serviceName == nil){
            return ""
        }
        output += self.render.renderAPIService(serviceName: self.serviceName!)
        output += renderAPITransition()
        output += generateAnonymousDataStructure()
        return output
    }

    func outputSwiftAPI(code: String) -> ((NSURL) -> Void) {
        return {
            path in
            do{
                try code.write(to: path as URL, atomically: true, encoding: String.Encoding.utf8)
            }catch let e{
                print("code output error:\(e)")
            }
        }
    }

    func parseAPIBluePrintJSON(json: JSON) {
        self.transitions.append(contentsOf: DKAPIMeta.parse(json: json).map {
            DKTransition($0)
        })
//        precondition(self.transitions.count > 0, "No transition found")
        if self.transitions.count>0 {
            self.serviceName = self.transitions[0].serviceName
        }
        
    }

    func renderAPITransition() -> String {
        var output = ""
        for transition in transitions {
            output += self.render.renderAPITransition(transition: transition)
            output += "\n\n"
        }
        return output
    }

    func generateAnonymousDataStructure() -> String {
        var output = ""
        for transition in transitions {
            output += self.render.renderDataStructure(transition: transition)
            output += "\n\n"
        }
        return output
    }

    func generateApiService() -> String {
        precondition(self.serviceName != nil)
        return self.render.renderAPIService(serviceName: serviceName!)
    }
}


public struct DKTransition {

    let json: JSON
    let href: String
    let apiName: String
    var serviceName: String
    let meta: DKAPIMeta
    let requestContents: [JSON]
    let responseContents: [JSON]

    var requestMethod: DKAPIRequestMethod {
        get {
            if let request = self.httpRequest {
                let method = request["attributes"]["method"].stringValue
                return DKAPIRequestMethod(method)
            }
            return DKAPIRequestMethod.NONE
        }
    }

    var httpRequest: JSON? {
        get {
            for j in json["content"].arrayValue {
                if (j["element"].string == "httpTransaction") {
                    for ts in j["content"].arrayValue {
                        if (ts["element"].string == "httpRequest") {
                            return ts
                        }
                    }
                }
            }
            return nil
        }
    }

    init(_ meta: DKAPIMeta) {
        self.meta = meta
        precondition(meta.rawJSON != nil, "meta raw json can't be nil")
        self.json = meta.rawJSON!
        self.href = meta.herf ?? ""
        let contact = (meta.groupName ?? "") + (meta.resourceName ?? "") + json["meta"]["title"].stringValue
        self.apiName = contact.uppercased().replacingOccurrences(of: " ", with: "_")
        self.serviceName = meta.serviceName ?? ""
        self.requestContents = self.json.contentsInTransition(name: .HTTPRequest)
        self.responseContents = self.json.contentsInTransition(name: .HTTPResponse)
        // TODO: get headers from attributes
    }

}

