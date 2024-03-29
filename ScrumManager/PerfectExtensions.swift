//
//  PerfectExtensions.swift
//  SwiftBlog
//
//  Created by Benjamin Johnson on 19/02/2016.
//  Copyright © 2016 Benjamin Johnson. All rights reserved.
//

import PerfectLib

enum RequestMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

extension Routing {
    class func addRoutesForRESTController(controller: RESTController, supportJSON: Bool = true) {
        
        // Show
        Routing.Routes["GET", "/\(controller.modelPluralName)/{id}"] = { _ in return controller }
        
        // Edit
        Routing.Routes["GET", "/\(controller.modelPluralName)/{id}/{action}"] = { _ in return controller }
        Routing.Routes["POST", "/\(controller.modelPluralName)/{id}/{action}"] = { _ in return controller }

        
        
        // Update
        Routing.Routes["POST", "/\(controller.modelPluralName)/{id}"] = { _ in return controller }
        
        // Delete
        Routing.Routes["DELETE", "/\(controller.modelPluralName)/{id}"] = { _ in return controller }
        
        // Index
        Routing.Routes["GET", "/\(controller.modelPluralName)"] = { _ in return controller }
        if supportJSON {
            Routing.Routes["GET", "/\(controller.modelPluralName).json"] = { _ in return controller }
            Routing.Routes["GET", "/\(controller.modelPluralName)/{id}"] = { _ in return controller }
            
        }
        
        Routing.Routes["GET", "/\(controller.modelPluralName)/new"] = { _ in return controller }
        Routing.Routes["POST", "/\(controller.modelPluralName)"] = { _ in return controller }
    }
}

extension WebResponse {
    func redirectTo(routable: Routable) {
        redirectTo(routable.pathURL)
    }
}

extension RequestHandler {
    func parseMustacheFromURL(url: String, withValues values: [String: Any]) -> String {
        
        let template = MustacheTemplate.FromURL(url)!
        let context =  MustacheEvaluationContext(map: values)
        
        let collector = MustacheEvaluationOutputCollector()
        template.evaluate(context, collector: collector)
        
        return collector.asString()
    }
}


extension WebRequest {
    var format: String {
        return requestURI().componentsSeparatedByString(".").last ?? "html"
    }
}

extension MustacheTemplate {
    class func FromURL(filepath: String) -> MustacheTemplate? {
        do {
            let file = File(filepath)
            try file.openRead()
            defer { file.close() }
            let bytes = try file.readSomeBytes(file.size())
            
            let parser = MustacheParser()
            let str = UTF8Encoding.encode(bytes)
            let template = try! parser.parse(str)
            return template
            
        } catch {
            print(error)
            return nil
        } 
    }
}

extension SessionManager {
    
    func setProject(project: Project) {
        self["projectID"] = project._objectID
        self["projectName"] = project.name
        self["projectPathURL"] = project.pathURL
    }
    
}
