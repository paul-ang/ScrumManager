//
//  RESTController.swift
//  SwiftBlog
//
//  Created by Benjamin Johnson on 9/02/2016.
//  Copyright © 2016 Benjamin Johnson. All rights reserved.
//


import PerfectLib
import MongoDB

protocol RESTController: RequestHandler {
    
    var modelName: String { get }
    
    var modelPluralName: String { get }
        
    func show(identifier: String, request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType
    
    func list(request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType
    
    func create(request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType
    
    func new(request: WebRequest, response: WebResponse)
    
    func update(identifier: String, request: WebRequest, response: WebResponse)
    
    func delete(identifier: String, request: WebRequest, response: WebResponse)
    
    func edit(identifier: String, request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType
    
    func beforeAction(request: WebRequest, response: WebResponse) -> MustacheEvaluationContext.MapType
    
    func controllerActions() -> [String: ControllerAction]
    
    func availableActionsForObjectWithIdentifier(identifier: String, request: WebRequest, response: WebResponse) -> [Action]
    
    func availableActionsForControllerObjects(request: WebRequest, response: WebResponse) -> [Action]
}

extension RESTController {
    
  
    
    func availableActionsForObjectWithIdentifier(identifier: String, request: WebRequest, response: WebResponse) -> [Action]
    {
        return []
    }
    
    func availableActionsForControllerObjects(request: WebRequest, response: WebResponse) -> [Action] {
        return []
    }
    
    var modelPluralName: String {
        return "\(modelName)s"
    }
    
    func beforeAction(request: WebRequest, response: WebResponse) -> MustacheEvaluationContext.MapType {
        return [:]
    }
    
    func controllerActions() -> [String: ControllerAction] {
        return [:]
    }
    
    func new(request: WebRequest, response: WebResponse) {
        response.setStatus(404, message: "The file \(request.requestURI()) was not found.")
        response.requestCompletedCallback()
    }
    
    func parseMustacheFromURL(url: String, withValues values: [String: Any]) -> String {
        
        if let template = MustacheTemplate.FromURL(url) {
            print("TEMPLATE \(url)")

            let context =  MustacheEvaluationContext(map: values)
            
            let collector = MustacheEvaluationOutputCollector()
            template.evaluate(context, collector: collector)
            
            return collector.asString()

        } else {
            print("TEMPLATE NOT FOUND \(url)")
            return ""
        }
    }
    
    func loadPageWithTemplate(request: WebRequest, url:String, withValues values: [String: Any]) -> String {
        
        let templateURL = request.documentRoot + "/templates/template.mustache"
        let content = parseMustacheFromURL(url, withValues: values)
        var finalValues = values
        finalValues["content"] = content
       // finalValues["user"] = ["name": "Test"] as [String: Any]
       // let templateContent = ["content": content] as [String: Any]
        
        return parseMustacheFromURL(templateURL, withValues: finalValues)
    }
    
    func handleRequest(request: WebRequest, response: WebResponse) {
        
        print(request.requestURI())
        
        let requestMethod = RequestMethod(rawValue: request.requestMethod())!

        // Show handle

        // Check identifier here

        
        if let identifier = request.urlVariables["id"] {
            
            switch(requestMethod) {
            case .POST, .PATCH, .PUT:
                fatalError()
                //update(identifier, request: request, response: response)
                
            case .DELETE:
                fatalError()
                //delete(identifier, request: request, response: response)
                
            case .GET:
                
                switch(identifier) {
                case "new":
                    
                    
                    let templateURL = request.documentRoot + "/templates/\(modelPluralName)/new.mustache"
                    
                    // Call Show
                    let values = try! create(request, response: response)
                    
                    response.appendBodyString(loadPageWithTemplate(request, url: templateURL, withValues: values))
                    response.requestCompletedCallback()
                    
                default:
      
                    if let action = request.urlVariables["action"]{
                        print("Found action \(action)")
                        
                        // Call Show
                        let templateURL = request.documentRoot + "/templates/\(modelPluralName)/edit.mustache"
                        
                        var values = try! edit(identifier, request: request, response: response)
                        values["url"] = "/\(modelName)s/\(identifier)"
                        
                        response.appendBodyString(loadPageWithTemplate(request, url: templateURL, withValues: values))
                        response.requestCompletedCallback()
                        
                        
                    } else {
                        
                        let templateURL = request.documentRoot + "/templates/\(modelPluralName)/show.mustache"
                        let values = try! show(identifier, request: request, response: response)
                        
                        response.appendBodyString(loadPageWithTemplate(request, url: templateURL, withValues: values))
                        response.requestCompletedCallback()
                    }
                }
                
                
               
            }
            
        } else {
            
            if requestMethod == .POST {
                
                new(request, response: response)
                
            } else {
                
                // Show all posts
                let templateURL: String
                if request.format == "json" {
                    templateURL = request.documentRoot + "//\(modelPluralName)/index.json.mustache"
                } else {
                    templateURL = request.documentRoot + "/templates/\(modelPluralName)/index.mustache"
                }
                
                let values = try! list(request, response: response)
                response.appendBodyString(loadPageWithTemplate(request, url: templateURL, withValues: values))
                response.requestCompletedCallback()
                
            }
        }
    }
    
    func show(identifier: Int,request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType {
        response.setStatus(404, message: "The file \(request.requestURI()) was not found.")
        return MustacheEvaluationContext.MapType()
    }
    
    func edit(identifier: String, request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType {
        response.setStatus(404, message: "The file \(request.requestURI()) was not found.")
        return MustacheEvaluationContext.MapType()
    }
    
    func update(identifier: String,request: WebRequest, response: WebResponse) {
        
        response.setStatus(404, message: "The file \(request.requestURI()) was not found.")
        response.requestCompletedCallback()
        
    }
    
    func delete(identifier: String,request: WebRequest, response: WebResponse) {
        
        response.setStatus(404, message: "The file \(request.requestURI()) was not found.")
        response.requestCompletedCallback()
        
    }
    
    func list(request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType {
        response.setStatus(404, message: "The file \(request.requestURI()) was not found.")
        return MustacheEvaluationContext.MapType()
        
    }
    
    func create(request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType {
        response.setStatus(404, message: "The file \(request.requestURI()) was not found.")
        return MustacheEvaluationContext.MapType()
    
    }
}

