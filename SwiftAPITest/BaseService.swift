//
// Created by drinking on 16/1/25.
// Copyright (c) 2016 drinking. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

public struct Empty:Mappable{
    public init?(map: Map){return nil}
    public static func objectForMapping(_ map: Map) -> Mappable?{return nil}
    public mutating func mapping(map: Map){}
}

public enum BackendError: Error {
    case network(error: Error) // Capture any underlying Error from the URLSession API
    case dataSerialization(error: Error)
    case jsonSerialization(error: Error)
    case xmlSerialization(error: Error)
    case objectSerialization(reason: String)
}

public struct JSONArray<Element: Mappable>: Mappable {
    public let entities: [Element]
    init(_ array: [Element]) {
        self.entities = array
    }
    
    public init?(map: Map){
        var elements:Array<Element> = []
        for j in (map.JSON["array"] as! [[String:Any]]) {
            if let e = Element(JSON: j){
                elements.append(e)
            }
        }
        self.entities = elements
    }
    public mutating func mapping(map: Map){}
    public init?(JSON: [String: Any], context: MapContext? = nil) {    
        self.entities = (JSON["array"] as! [[String:Any]]).map {
            Element(JSON:$0)!
        }
    }
}

extension DataRequest {
    
        
        public func responseObject<T: BaseMappable>(queue: DispatchQueue? = nil,completionHandler: @escaping (DataResponse<T>) -> Void)-> Self{
        
        let responseSerializer = DataResponseSerializer<T> { request, response, data, error in
            
            guard error == nil else { return .failure(BackendError.network(error: error!)) }
            
            guard let _ = response else {
                let reason = "Response collection could not be serialized due to nil response."
                return .failure(BackendError.objectSerialization(reason: reason))
            }
            
            let jsonSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonSerializer.serializeResponse(request, response, data, nil)
            
            guard case let .success(jsonObject) = result else {
                return .failure(BackendError.jsonSerialization(error: result.error!))
            }
            
            //T is Any:BaseMappable except JSONArray
            if let dictionary = jsonObject as? [String:Any] {
                if let responseObject = T(JSON:dictionary) {
                    return .success(responseObject)
                }
            }
            
            //T is JSONArray
            if let array = jsonObject as? [[String:Any]]{
                if let jsonArray = T(JSON: ["array":array]){
                    return .success(jsonArray)
                }
            }
            
            //TODO: T is ErrorType ?
            
            let reason = "Response collection could not be serialized due to nil response."
            return .failure(BackendError.objectSerialization(reason: reason))
        }
        
        return response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
    }
    
}


public extension Dictionary {
    
    mutating func unionInPlace(_ dictionary: Dictionary) {
        dictionary.forEach {
            self.updateValue($1, forKey: $0)
        }
    }
    
    func union(_ dictionary: Dictionary) -> Dictionary {
        var dictionary = dictionary
        dictionary.unionInPlace(self)
        return dictionary
    }
}

public extension String{
    func fillArgs(_ args:[String])->String{
        
        let regex = try! NSRegularExpression(pattern: "\\{.*\\}",
                                             options: [.caseInsensitive])
        let mc = regex.matches(in: self, options: [], range: NSRange(0..<self.characters.count)).count
        precondition(mc == args.count,"Arguments count doesn't match URL")
        if mc == 0 {
            return self
        }
        let str = regex.stringByReplacingMatches(in: self, options: [], range: NSRange(0..<self.characters.count), withTemplate: "%@")
        return String(format: str,arguments:args.map{ $0 as CVarArg})
    }
}

public struct APIConfig {
    public init(host:String,headers:[String:String]){
        self.host = host
        self.headers = headers
    }
    
    var host: String
    var headers: [String:String] = [String: String]()
}

open class APIManager {
    
    static let sharedInstance = APIManager()
    fileprivate var services:[String:APIConfig]
    public init(){
        services = [:]
    }
    
    open func register(service key:String, host:String, headers:[String:String] = [:]){
        services.updateValue(APIConfig(host: host, headers: headers), forKey: key)
    }
    
    open func configFor(service key:String)->APIConfig{
        let empty = APIConfig(host: "", headers: [:])
        return services[key] ?? empty
    }

}


open class APIService {
    
    public init(){
        pathArgs = []
        _subPath = ""
    }
    
    public init(subPath:String,method:Alamofire.HTTPMethod){
        pathArgs = []
        _subPath = subPath
        httpMethod = method
    }
    open var httpMethod:Alamofire.HTTPMethod = .get
    open var customHost: String?
    open var customHeaders: [String:String]?
    var pathArgs: [String]
    fileprivate var _subPath:String
    
    open var subPath:String {
        get {
            return _subPath.fillArgs(pathArgs)
        }
    }
    
    var host: String {
        get {
            return ""
        }
    }
    
    var headers: [String:String] {
        get {
            return [String: String]()
        }
    }
    
    open func fillPathArgs(_ args:String...){
        pathArgs = args
    }
}


