//
//  AuthController.swift
//  ScrumManager
//
//  Created by Ben Johnson on 15/04/2016.
//  Copyright © 2016 Benjamin Johnson. All rights reserved.
//

import Foundation
import PerfectLib

protocol AuthController: RESTController, RoutableController {
    
 //   associatedtype DBManagedObject

    
    func currentUser(request: WebRequest, response: WebResponse) -> User?
    
    func getUserInformation(request: WebRequest, response: WebResponse) -> [String: Any]
    
    var anonymousUserCanView: Bool { get }
    
    var pageTitle: String { get }
    
}

extension AuthController {
    
    var anonymousUserCanView: Bool {
        return false
    }
    
    var pageTitle: String {
        return "Scrum Manager"
    }
    
    func currentUser(request: WebRequest, response: WebResponse) -> User? {
        
        // Obtain Session
        let currentSession = response.getSession("user")
        print(currentSession["user_id"])
        
        guard let currentUserID = currentSession["user_id"] as? String, let user = try! DatabaseManager().getObjectWithID(User.self, objectID: currentUserID) else {
            
            if anonymousUserCanView {
                return User(email: "", name: "anonymous", authKey: "", role: 0, profilePictureURL: "")
            }
            
            return  nil
        }
        
        return user
    }
    
    func getUserInformation(request: WebRequest, response: WebResponse) -> [String: Any] {
        print("Getting user informmation")

        if let user = currentUser(request, response: response) {
            print("Got user informmation")

            return ["user":["name": user.name] as [String: Any]]
        } else {
            return [:]
        }
    }
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        print("Using AUTH Controller")

        print(request.requestURI())
        
        let requestMethod = RequestMethod(rawValue: request.requestMethod())!
      
        // Redirect to login if no logged in user
        guard let user = currentUser(request, response: response) else {
            response.redirectTo("/login")
            response.requestCompletedCallback()
            return
        }
        
        // Add logged in user information to provided values for templates
        var values: MustacheEvaluationContext.MapType = ["user":["name": user.name] as [String: Any]]
        values["pageTitle"] = pageTitle
        
        values.update(routeDictionary)
        
        if let identifier = request.urlVariables["id"] {

            switch(requestMethod) {
            case .PATCH, .PUT:
                fatalError()
                //update(identifier, request: request, response: response)
                
            case .DELETE:
                fatalError()
                //delete(identifier, request: request, response: response)
                
            case .GET, .POST:
                
                switch(identifier) {
                case "new":
                    
                    
                    let templateURL = request.documentRoot + "/templates/\(modelPluralName)/new.mustache"
                    
                    // Call Show
                    values.update(try! create(request, response: response))
                    response.appendBodyString(loadPageWithTemplate(request, url: templateURL, withValues: values))
                
                default:
                    
                    if let action = request.urlVariables["action"]{
                        print("Found action \(action)")
                        
                        if let actionHandler = actions()[action] {
                            actionHandler(request, response, identifier)
                            
                        } else if action == "destroy" {
                            
                            delete(identifier, request: request, response: response)
                        } else {
                            // Call Show
                            let templateURL = request.documentRoot + "/templates/\(modelPluralName)/edit.mustache"
                            values.update( try! edit(identifier, request: request, response: response))
                            //    var values = try! edit(identifier, request: request, response: response)
                            values["url"] = "/\(modelPluralName)/\(identifier)"
                            
                            response.appendBodyString(loadPageWithTemplate(request, url: templateURL, withValues: values))
                        }
                        
                        
                      

                    } else if requestMethod == .POST {
                        
                        update(identifier, request: request, response: response)
                        
                    } else {
                        
                        let templateURL = request.documentRoot + "/templates/\(modelPluralName)/show.mustache"

                        //let values = try! show(identifier, request: request, response: response)
                        values.update(try! show(identifier, request: request, response: response))
                        values["url"] = "/\(modelPluralName)/\(identifier)"
                        let destoryURL = "/\(modelPluralName)/\(identifier)/destroy"
                        let editURL = "/\(modelPluralName)/\(identifier)/edit"

                        values["actions"] = [Action(url: editURL, icon: "", name: "Edit").dictionary, Action(url: destoryURL, icon: "icon-trash", name: "").dictionary]
                        

                        response.appendBodyString(loadPageWithTemplate(request, url: templateURL, withValues: values))
                    }
                }
                
                
                
            }
            
        } else {
            
            if requestMethod == .POST {
                
                new(request, response: response)
                
            } else {
                print("Listing models")
                // Show all posts
                let templateURL: String
                if request.format == "json" {
                    templateURL = request.documentRoot + "//\(modelPluralName)/index.json.mustache"
                } else {
                    templateURL = request.documentRoot + "/templates/\(modelPluralName)/index.mustache"
                }
                
               // var values = try! list(request, response: response)
                values.update(try! list(request, response: response))
                print("getting user information")
                print("DICT: \(getUserInformation(request, response: response))")
                values.update(getUserInformation(request, response: response))
                values["actions"] = [Action(url: newURL, icon: "icon-plus", name: "").dictionary]
                // Add routing
               
                response.appendBodyString(loadPageWithTemplate(request, url: templateURL, withValues: values))
                response.requestCompletedCallback()
                
            }
        }
        
        response.requestCompletedCallback()

        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
}