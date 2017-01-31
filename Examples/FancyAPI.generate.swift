
import Foundation 
import Alamofire
import ObjectMapper
import RxSwift

public class FANCYAPIService<REQ:Mappable,RESP:Mappable>: APIService {

    lazy public var config: APIConfig = APIManager.sharedInstance.configFor(service: "FANCYAPIService")
    class public func setup(host h:String, headers hs:[String:String] = [:]){
        APIManager.sharedInstance.register(service: "FANCYAPIService", host: h,headers:hs)
    }

    public override init(subPath: String,method m:Alamofire.HTTPMethod = .get) {
        super.init(subPath: subPath,method:m)
    }
    
    override var host: String {
        get {
            if let ch = customHost {
                return ch
            }
            return config.host
        }
    }
    override var headers: [String:String] {
        get {
            if let ch = customHeaders {
                ch.union(config.headers)
                return ch
            }
            return config.headers
        }
    }
    
    public func send(_ params: REQ?=nil, completionHandler: ((DataResponse<RESP>) -> Void)? = nil) -> DataRequest {
        
        let url = self.host + self.subPath
        return Alamofire.request(url, method: httpMethod, parameters: params?.toJSON(), encoding: URLEncoding.methodDependent, headers: headers).responseObject(queue: nil) { (response:DataResponse<RESP>) in
            if completionHandler != nil {
                completionHandler!(response)
            }
        }
    }
    
    public func sendSginal(_ params:REQ?=nil) -> Observable<RESP> {
        
        return Observable.create { (observer) -> Disposable in
            
            let request = self.send(params){
                response in
                switch(response.result){
                case .success(let value):
                    observer.onNext(value)
                    observer.onCompleted()
                    break
                case .failure(let error):
                    observer.onError(error)
                    break
                }
            }
            
            return Disposables.create {
                request.cancel()
            }
            
        }

    }
    
}
    

public class USERLOGIN: FANCYAPIService<USERLOGIN_REQUEST,LoginResult> {
 	public class func instance()->FANCYAPIService<USERLOGIN_REQUEST,LoginResult>{
		return FANCYAPIService<USERLOGIN_REQUEST,LoginResult>(subPath:"/api/v1/login",method:.post)
	}

public class func runTest(_ testor:(_ d:String,_ i:String,_ runner:@escaping (@escaping ((Void)->Void))->())->(),
                          host:String? = nil,
                          argument:((APIService)->USERLOGIN_REQUEST?)? = nil,
                          expect:((LoginResult)->Void)? = nil)->Void{
    func run(done:@escaping ((Void)->Void)){
        let get = USERLOGIN.instance()
        get.customHost = host
        var arguments:USERLOGIN_REQUEST? = nil
        if let args = argument {
            arguments = args(get)
        }
        
        _ = get.sendSginal(arguments).subscribe(onNext: { (result) in
            if let expect = expect {
                expect(result)
            }
            done()
        })
        
    }
    let name = "USERLOGIN"
    let method = "GET"
    testor(name,method,run)
}


}


public extension FYNetworkEngine {

    public func userlogin(_ params: USERLOGIN_REQUEST?=nil,success:@escaping (_ result:LoginResult)->(),failure:@escaping ()->()){
        USERLOGIN.instance().sendSginal(params).subscribe(onNext: { (result) in
            success(result)
        }, onError: { (error) in
            failure()
        })
    }
}




@objc public class USERLOGIN_REQUEST :NSObject, Mappable{
	public var password: String?
	public var username: String?
public override init(){}

init?(json:[String:Any]?){ 
 guard let dict = json else{ return nil}

	self.password = dict["password"] as? String
	self.username = dict["username"] as? String
}
required convenience public init?(map: Map){self.init(json:map.JSON)}

public func mapping(map: Map){
password <- map["password"] 
username <- map["username"] 
}


}




@objc public class LoginResult:NSObject,Mappable{
public var error:String?
public var login:String?
public var token:String?

 public override init(){} 
 init?(json:[String:Any]?){ 
 guard let dict = json else{ return nil}
self.error = dict["error"] as? String
self.login = dict["login"] as? String
self.token = dict["token"] as? String
}
required convenience public init?(map: Map){self.init(json:map.JSON)}
	 public func mapping(map: Map){
error <- map["error"] 
login <- map["login"] 
token <- map["token"] 
}
}
