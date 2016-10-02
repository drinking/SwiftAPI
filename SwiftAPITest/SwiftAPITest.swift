//
//  SwiftAPITest.swift
//  SwiftAPITest
//
//  Created by drinking on 16/9/28.
//  Copyright © 2016年 drinking. All rights reserved.
//

import XCTest
import Quick
import Nimble

//Ref: http://www.mokacoding.com/blog/async-testing-with-quick-and-nimble/

func testor(d:String,i:String,runner:@escaping (@escaping ((Void)->Void))->()){
    describe(d){
        it(i){
            waitUntil (timeout: 15){ done in
                runner(done)
            }
        }
    }
}

class TableOfContentsSpec: QuickSpec {
    
    override func spec() {
        
        GITHUBISSUE.runTest(testor ,host: "https://api.github.com",expect:{
            let issues = $0.entities;
            expect(issues.count) == 30
        })

        GITHUBUSER.runTest(testor, host: "https://api.github.com",argument:{
            $0.fillPathArgs("drinking")
            return nil
            },expect:{
                expect($0.email) == "pan49@126.com"
                expect($0.login) == "drinking"
        })
        
        JSONIPGET.runTest(testor, host: "http://jsonip.com",expect:{
            expect($0.about!) == "/about"
        })
        
    }
}
