////
////  SprintReviewReportController.swift
////  ScrumManager
////
////  Created by Fagan Ooi on 17/05/2016.
////  Copyright © 2016 Benjamin Johnson. All rights reserved.



import Foundation
import PerfectLib

class SprintReviewReportController: AuthController {
    
    let modelName = "report"
    
    let modelPluralName: String = "reports"
    
    func controllerActions() -> [String: ControllerAction] {
        var modelActions:[String: ControllerAction] = [:]
        modelActions["comments"] = ControllerAction() {(request, resp,identifier) in self.newComment(request, response: resp, identifier: identifier)}
        
      modelActions["updatecomment"] = ControllerAction() {(request, resp,identifier) in self.updateComment(request, response: resp, identifier: identifier)}
        
         modelActions["deletecomment"] = ControllerAction() {(request, resp,identifier) in self.deleteComment(request, response: resp, identifier: identifier)}
        
        return modelActions
    }

    func list(request: WebRequest, response: WebResponse) throws -> MustacheEvaluationContext.MapType {
        return [:]
    }
    
    func show(identifier: String, request: WebRequest, response: WebResponse) throws -> MustacheEvaluationContext.MapType {
        // Query Sprint
        let id = Int(identifier)!

        let db = try! DatabaseManager()
        guard let sprint = db.executeFetchRequest(Sprint.self, predicate: ["identifier": id]).first else {
            return [:]
        }
        
        if sprint.reviewReport.tasks.count <= 0 {
            // Load User Stories Completed
            let userStoryIdentifier = sprint.userStoryIDs
            for eachID in userStoryIdentifier{
                
                let userstory = db.getObjectWithID(UserStory.self, objectID: eachID)
                let name = (userstory?.title)!
                sprint.reviewReport.userStoriesCompleted.append(["userstory":name])
            }
            
            
            // Load Tasks
            for task in sprint.tasks{
                sprint.reviewReport.tasks.append(["task": task.title, "status": task.status.description, "icon":
                    TaskStatusIcon(rawValue: task.status.rawValue)?.description])
            }
            db.updateObject(sprint)
        }
        /*
         
            // Load User Stories Completed
            let userStoryIdentifier = sprint.userStoryIDs
            for eachID in userStoryIdentifier{
                
                let userstory = db.getObjectWithID(UserStory.self, objectID: eachID)
                sprint.reviewReport.userStoriesCompleted.append(["userstory":userstory!.title])
            }
            

            // Load Tasks
            for task in sprint.tasks{
                sprint.reviewReport.tasks.append(["task": task.title, "status": task.status.description, "icon":
                    TaskStatusIcon(rawValue: task.status.rawValue)?.description])
            }
            db.updateObject(sprint)
            
            var values: MustacheEvaluationContext.MapType = [:]
            values["reviewReport"] = sprint.reviewReport.dictionary
            
            // Set Current username
            let user = currentUser(request, response: response)
            values["user"] = user?.name

            return values
        
        */
        var values: MustacheEvaluationContext.MapType = [:]
        values["reviewReport"] = sprint.reviewReport.dictionary
        // Set Current username
        let user = currentUser(request, response: response)

        // Set comment list be post by others
        let commentList : [[String:Any]] = sprint.reviewReport.loadCommentDetailsForMustahce(user!)
        
        values["commentList"] = commentList
        values["identifier"] = identifier
        return values
        
    }
    
    func update(identifier: String, request: WebRequest, response: WebResponse) {

    }
    
    
    func updateComment(request: WebRequest, response: WebResponse, identifier: String) {
        // 0: Sprint identifier, 1: New comment, 2: index of old comment
        let informationGet = identifier.componentsSeparatedByString("_")
        
        let id = Int(informationGet[0])!
        
        let newComment = informationGet[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        let indexOfOldComment = Int(informationGet[2])
        
        let db = try! DatabaseManager()
        
        guard let sprint = db.executeFetchRequest(Sprint.self, predicate: ["identifier": id]).first else{
            return
        }
        
        sprint.reviewReport.comments[indexOfOldComment!].comment = newComment
        
        db.updateObject(sprint)
        
        response.redirectTo("/reports/\(id)")

    }
    
    func newComment(request: WebRequest, response: WebResponse,identifier: String) {
        
        print("New Comment")
        let id = Int(identifier)!
        let db = try! DatabaseManager()
        guard let sprint = db.executeFetchRequest(Sprint.self, predicate: ["identifier": id]).first else {
            return
        }


        if let comment = request.param("comment"), user = currentUser(request, response: response) {
            // Post comment
            let newComment = Comment(comment: comment, user: user)
            sprint.reviewReport.comments.append(newComment)
            // Update the database
            db.updateObject(sprint)
            response.redirectTo("/reports/\(identifier)")
            
        }
    }
    
    func new(request: WebRequest, response: WebResponse) {
        
    }
    
    func create(request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType
    {
        return [:]
    }
    
    func deleteComment(request: WebRequest, response: WebResponse, identifier: String) {
        // 0: Sprint identifier, 1: Comment position
        let informationGet = identifier.componentsSeparatedByString("_")
        
        let id = Int(informationGet[0])!
        
        let deleteIndex = Int(informationGet[1])
        
        let db = try! DatabaseManager()
        
        guard let sprint = db.executeFetchRequest(Sprint.self, predicate: ["identifier": id]).first else {
            return
        }
        
        sprint.reviewReport.comments.removeAtIndex(deleteIndex!)
        
        db.updateObject(sprint)
        
        response.redirectTo("/reports/\(id)")
    }
    
    
}
