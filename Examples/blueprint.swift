
import Foundation
import Alamofire
import ObjectMapper
import RxSwift

public class PUBLICAPIService<REQ:Mappable,RESP:Mappable>: APIService {
    
    lazy public var config: APIConfig = APIManager.sharedInstance.configFor(service: "PUBLICAPIService")
    class public func setup(host h:String, headers hs:[String:String] = [:]){
        APIManager.sharedInstance.register(service: "PUBLICAPIService", host: h,headers:hs)
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
                _ = ch.union(config.headers)
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


public class JSONIPGET: PUBLICAPIService<JSONIPGET_REQUEST,IPInfo> {
    public class func instance()->PUBLICAPIService<JSONIPGET_REQUEST,IPInfo>{
        return PUBLICAPIService<JSONIPGET_REQUEST,IPInfo>(subPath:"/",method:.get)
    }
    
    public class func runTest(_ testor:(_ d:String,_ i:String,_ runner:@escaping (@escaping ((Void)->Void))->())->(),
                              host:String? = nil,
                              argument:((APIService)->JSONIPGET_REQUEST?)? = nil,
                              expect:((IPInfo)->Void)? = nil)->Void{
        func run(done:@escaping ((Void)->Void)){
            let get = JSONIPGET.instance()
            get.customHost = host
            var arguments:JSONIPGET_REQUEST? = nil
            if let args = argument {
                arguments = args(get)
            }
            
            let _ = get.sendSginal(arguments).subscribe(onNext: { (result) in
                if let expect = expect {
                    expect(result)
                }
                done()
            })
            
        }
        let name = "JSONIPGET"
        let method = "GET"
        testor(name,method,run)
    }
    
    
}


public class GITHUBUSER: PUBLICAPIService<Empty,UserInfo> {
    public class func instance()->PUBLICAPIService<Empty,UserInfo>{
        return PUBLICAPIService<Empty,UserInfo>(subPath:"/users/{name}",method:.get)
    }
    
    public class func runTest(_ testor:(_ d:String,_ i:String,_ runner:@escaping (@escaping ((Void)->Void))->())->(),
                              host:String? = nil,
                              argument:((APIService)->Empty?)? = nil,
                              expect:((UserInfo)->Void)? = nil)->Void{
        func run(done:@escaping ((Void)->Void)){
            let get = GITHUBUSER.instance()
            get.customHost = host
            var arguments:Empty? = nil
            if let args = argument {
                arguments = args(get)
            }
            
            let _ = get.sendSginal(arguments).subscribe(onNext: { (result) in
                if let expect = expect {
                    expect(result)
                }
                done()
            })
            
        }
        let name = "GITHUBUSER"
        let method = "GET"
        testor(name,method,run)
    }
    
    
}


public class GITHUBISSUE: PUBLICAPIService<Empty,JSONArray<Issue>> {
    public class func instance()->PUBLICAPIService<Empty,JSONArray<Issue>>{
        return PUBLICAPIService<Empty,JSONArray<Issue>>(subPath:"/repos/vmg/redcarpet/issues",method:.get)
    }
    
    public class func runTest(_ testor:(_ d:String,_ i:String,_ runner:@escaping (@escaping ((Void)->Void))->())->(),
                              host:String? = nil,
                              argument:((APIService)->Empty?)? = nil,
                              expect:((JSONArray<Issue>)->Void)? = nil)->Void{
        func run(done:@escaping ((Void)->Void)){
            let get = GITHUBISSUE.instance()
            get.customHost = host
            var arguments:Empty? = nil
            if let args = argument {
                arguments = args(get)
            }
            
            let _ = get.sendSginal(arguments).subscribe(onNext: { (result) in
                if let expect = expect {
                    expect(result)
                }
                done()
            })
            
        }
        let name = "GITHUBISSUE"
        let method = "GET"
        testor(name,method,run)
    }
    
    
}


public struct JSONIPGET_REQUEST {
    public var about: String?
    public var ip: String?
    public var number: Double?
    public init(){}
    
    init?(json:[String:Any]?){
        guard let dict = json else{ return nil}
        
        self.about = dict["about"] as? String
        self.ip = dict["ip"] as? String
        self.number = dict["number"] as? Double
    }
}
extension JSONIPGET_REQUEST :Mappable {
    
    public init?(map: Map){self.init(json:map.JSON)}
    public mutating func mapping(map: Map){
        about <- map["about"]
        ip <- map["ip"]
        number <- map["number"]
    }
    
}










public struct IPInfo{
    public var ip:String?
    public var about:String?
    public var users:[Author]?
    init?(json:[String:Any]?){
        guard let dict = json else{ return nil}
        self.ip = dict["ip"] as? String
        self.about = dict["about"] as? String
        self.users = (dict["users"] as? [[String:AnyObject]]).flatMap{$0.flatMap{Author(json: $0)}}
    }
}
extension IPInfo:Mappable {
    public init?(map: Map){self.init(json:map.JSON)}
    public mutating func mapping(map: Map){
        ip <- map["ip"]
        about <- map["about"]
        users <- map["users"]
    }
}

public struct Author{
    public var name:String?
    public var email:String?
    init?(json:[String:Any]?){
        guard let dict = json else{ return nil}
        self.name = dict["name"] as? String
        self.email = dict["email"] as? String
    }
}
extension Author:Mappable {
    public init?(map: Map){self.init(json:map.JSON)}
    public mutating func mapping(map: Map){
        name <- map["name"]
        email <- map["email"]
    }
}

public struct UserInfo{
    public var avatarUrl:String?
    public var bio:String?
    public var blog:String?
    public var company:String?
    public var createdAt:String?
    public var email:String?
    public var eventsUrl:String?
    public var followers:Int?
    public var followersUrl:String?
    public var following:Int?
    public var followingUrl:String?
    public var gistsUrl:String?
    public var gravatarId:String?
    public var hireable:Bool?
    public var htmlUrl:String?
    public var id:Int?
    public var location:String?
    public var login:String?
    public var name:String?
    public var organizationsUrl:String?
    public var publicGists:Int?
    public var publicRepos:Int?
    public var receivedEventsUrl:String?
    public var reposUrl:String?
    public var siteAdmin:Bool?
    public var starredUrl:String?
    public var subscriptionsUrl:String?
    public var type:String?
    public var updatedAt:String?
    public var url:String?
    init?(json:[String:Any]?){
        guard let dict = json else{ return nil}
        self.avatarUrl = dict["avatarUrl"] as? String
        self.bio = dict["bio"] as? String
        self.blog = dict["blog"] as? String
        self.company = dict["company"] as? String
        self.createdAt = dict["createdAt"] as? String
        self.email = dict["email"] as? String
        self.eventsUrl = dict["eventsUrl"] as? String
        self.followers = dict["followers"] as? Int
        self.followersUrl = dict["followersUrl"] as? String
        self.following = dict["following"] as? Int
        self.followingUrl = dict["followingUrl"] as? String
        self.gistsUrl = dict["gistsUrl"] as? String
        self.gravatarId = dict["gravatarId"] as? String
        self.hireable = dict["hireable"] as? Bool
        self.htmlUrl = dict["htmlUrl"] as? String
        self.id = dict["id"] as? Int
        self.location = dict["location"] as? String
        self.login = dict["login"] as? String
        self.name = dict["name"] as? String
        self.organizationsUrl = dict["organizationsUrl"] as? String
        self.publicGists = dict["publicGists"] as? Int
        self.publicRepos = dict["publicRepos"] as? Int
        self.receivedEventsUrl = dict["receivedEventsUrl"] as? String
        self.reposUrl = dict["reposUrl"] as? String
        self.siteAdmin = dict["siteAdmin"] as? Bool
        self.starredUrl = dict["starredUrl"] as? String
        self.subscriptionsUrl = dict["subscriptionsUrl"] as? String
        self.type = dict["type"] as? String
        self.updatedAt = dict["updatedAt"] as? String
        self.url = dict["url"] as? String
    }
}
extension UserInfo:Mappable {
    public init?(map: Map){self.init(json:map.JSON)}
    public mutating func mapping(map: Map){
        avatarUrl <- map["avatarUrl"]
        bio <- map["bio"]
        blog <- map["blog"]
        company <- map["company"]
        createdAt <- map["createdAt"]
        email <- map["email"]
        eventsUrl <- map["eventsUrl"]
        followers <- map["followers"]
        followersUrl <- map["followersUrl"]
        following <- map["following"]
        followingUrl <- map["followingUrl"]
        gistsUrl <- map["gistsUrl"]
        gravatarId <- map["gravatarId"]
        hireable <- map["hireable"]
        htmlUrl <- map["htmlUrl"]
        id <- map["id"]
        location <- map["location"]
        login <- map["login"]
        name <- map["name"]
        organizationsUrl <- map["organizationsUrl"]
        publicGists <- map["publicGists"]
        publicRepos <- map["publicRepos"]
        receivedEventsUrl <- map["receivedEventsUrl"]
        reposUrl <- map["reposUrl"]
        siteAdmin <- map["siteAdmin"]
        starredUrl <- map["starredUrl"]
        subscriptionsUrl <- map["subscriptionsUrl"]
        type <- map["type"]
        updatedAt <- map["updatedAt"]
        url <- map["url"]
    }
}

public struct Issue{
    public var assignee:String?
    public var assignees:[String]?
    public var body:String?
    public var closedAt:String?
    public var comments:Int?
    public var commentsUrl:String?
    public var createdAt:String?
    public var eventsUrl:String?
    public var htmlUrl:String?
    public var id:Int?
    public var labels:[String]?
    public var labelsUrl:String?
    public var locked:Bool?
    public var milestone:String?
    public var number:Int?
    public var repositoryUrl:String?
    public var state:String?
    public var title:String?
    public var updatedAt:String?
    public var url:String?
    public var user:IssueUser?
    init?(json:[String:Any]?){
        guard let dict = json else{ return nil}
        self.assignee = dict["assignee"] as? String
        self.assignees = (dict["assignees"] as? [String]).flatMap{$0.flatMap{$0}}
        self.body = dict["body"] as? String
        self.closedAt = dict["closedAt"] as? String
        self.comments = dict["comments"] as? Int
        self.commentsUrl = dict["commentsUrl"] as? String
        self.createdAt = dict["createdAt"] as? String
        self.eventsUrl = dict["eventsUrl"] as? String
        self.htmlUrl = dict["htmlUrl"] as? String
        self.id = dict["id"] as? Int
        self.labels = (dict["labels"] as? [String]).flatMap{$0.flatMap{$0}}
        self.labelsUrl = dict["labelsUrl"] as? String
        self.locked = dict["locked"] as? Bool
        self.milestone = dict["milestone"] as? String
        self.number = dict["number"] as? Int
        self.repositoryUrl = dict["repositoryUrl"] as? String
        self.state = dict["state"] as? String
        self.title = dict["title"] as? String
        self.updatedAt = dict["updatedAt"] as? String
        self.url = dict["url"] as? String
        self.user = IssueUser(json:dict["user"] as? [String:AnyObject])
    }
}
extension Issue:Mappable {
    public init?(map: Map){self.init(json:map.JSON)}
    public mutating func mapping(map: Map){
        assignee <- map["assignee"]
        assignees <- map["assignees"]
        body <- map["body"]
        closedAt <- map["closedAt"]
        comments <- map["comments"]
        commentsUrl <- map["commentsUrl"]
        createdAt <- map["createdAt"]
        eventsUrl <- map["eventsUrl"]
        htmlUrl <- map["htmlUrl"]
        id <- map["id"]
        labels <- map["labels"]
        labelsUrl <- map["labelsUrl"]
        locked <- map["locked"]
        milestone <- map["milestone"]
        number <- map["number"]
        repositoryUrl <- map["repositoryUrl"]
        state <- map["state"]
        title <- map["title"]
        updatedAt <- map["updatedAt"]
        url <- map["url"]
        user <- map["user"]
    }
}

public struct IssueUser{
    public var avatarUrl:String?
    public var eventsUrl:String?
    public var followersUrl:String?
    public var followingUrl:String?
    public var gistsUrl:String?
    public var gravatarId:String?
    public var htmlUrl:String?
    public var id:Int?
    public var login:String?
    public var organizationsUrl:String?
    public var receivedEventsUrl:String?
    public var reposUrl:String?
    public var siteAdmin:Bool?
    public var starredUrl:String?
    public var subscriptionsUrl:String?
    public var type:String?
    public var url:String?
    init?(json:[String:Any]?){ 
        guard let dict = json else{ return nil}
        self.avatarUrl = dict["avatarUrl"] as? String
        self.eventsUrl = dict["eventsUrl"] as? String
        self.followersUrl = dict["followersUrl"] as? String
        self.followingUrl = dict["followingUrl"] as? String
        self.gistsUrl = dict["gistsUrl"] as? String
        self.gravatarId = dict["gravatarId"] as? String
        self.htmlUrl = dict["htmlUrl"] as? String
        self.id = dict["id"] as? Int
        self.login = dict["login"] as? String
        self.organizationsUrl = dict["organizationsUrl"] as? String
        self.receivedEventsUrl = dict["receivedEventsUrl"] as? String
        self.reposUrl = dict["reposUrl"] as? String
        self.siteAdmin = dict["siteAdmin"] as? Bool
        self.starredUrl = dict["starredUrl"] as? String
        self.subscriptionsUrl = dict["subscriptionsUrl"] as? String
        self.type = dict["type"] as? String
        self.url = dict["url"] as? String
    }
}
extension IssueUser:Mappable {
    public init?(map: Map){self.init(json:map.JSON)}
    public mutating func mapping(map: Map){
        avatarUrl <- map["avatarUrl"] 
        eventsUrl <- map["eventsUrl"] 
        followersUrl <- map["followersUrl"] 
        followingUrl <- map["followingUrl"] 
        gistsUrl <- map["gistsUrl"] 
        gravatarId <- map["gravatarId"] 
        htmlUrl <- map["htmlUrl"] 
        id <- map["id"] 
        login <- map["login"] 
        organizationsUrl <- map["organizationsUrl"] 
        receivedEventsUrl <- map["receivedEventsUrl"] 
        reposUrl <- map["reposUrl"] 
        siteAdmin <- map["siteAdmin"] 
        starredUrl <- map["starredUrl"] 
        subscriptionsUrl <- map["subscriptionsUrl"] 
        type <- map["type"] 
        url <- map["url"] 
    }
}
