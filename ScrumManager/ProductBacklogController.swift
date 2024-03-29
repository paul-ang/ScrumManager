//
//  ArticleController.swift
//  SwiftBlog
//
//  Created by Benjamin Johnson on 9/02/2016.
//  Copyright © 2016 Benjamin Johnson. All rights reserved.
//


import PerfectLib

class ProductBacklogController: AuthController {
    
    let modelName = "userstory"
    
    let modelPluralName: String = "userstories"
    
    let pageTitle: String = "Product Backlog"
        
    //var actions: [String: (WebRequest,WebResponse) -> ()] = ["comments": {(request, resp) in self.newComment(request, response: resp)}]
    
    func controllerActions() -> [String: ControllerAction] {
        var modelActions:[String: ControllerAction] = [:]
		modelActions["comments"] = ControllerAction() {(request, resp,identifier) in self.newComment(request, response: resp, identifier: identifier)}
		
		modelActions["arrange"] = ControllerAction(){(request, resp, identifier) in self.arrange(request, response:resp)}
		
		modelActions["delete"] = ControllerAction(){(request, resp, identifier) in self.delete(request, response:resp, identifier: identifier)}
        
        modelActions["updatecomment"] = ControllerAction() {(request, resp,identifier) in self.updateComment(request, response: resp, identifier: identifier)}
        
        modelActions["deletecomment"] = ControllerAction() {(request, resp,identifier) in self.deleteComment(request, response: resp, identifier: identifier)}
		
		
		
		
        return modelActions
    }
    
    func availableActionsForControllerObjects(request: WebRequest, response: WebResponse) -> [Action] {
        
        guard let user = currentUser(request, response: response) else {
            return []
        }
        
        switch user.role {
        case .Admin, .ProductOwner, .ScrumMaster:
            return [addAction]
        default:
            return []
        }
        
    }
	
    func list(request: WebRequest, response: WebResponse) throws -> MustacheEvaluationContext.MapType {
        
        // Get Articles
		let curProject = currentProject(request, response: response)
		
        let db = try! DatabaseManager()
        var userStories = curProject!.userStories
		userStories = userStories.sort({$0.rankingIndex < $1.rankingIndex})

        var counter = 0
        let userStoriesJSON = userStories.map { (userStory) -> [String: Any] in
			let userStoryDict = userStory.dictionary
            
            return userStoryDict
        }
		
        let values :MustacheEvaluationContext.MapType = ["userStories": userStoriesJSON]
        return values
    }
    
    func getUserStoryWithIdentifier(identifier: Int) -> UserStory? {
        let db = try! DatabaseManager()
        guard let userStory = db.executeFetchRequest(UserStory.self, predicate: ["identifier": identifier]).first else {
            return nil
        }
       
        return userStory
    }
	
	func arrange(request:WebRequest, response:WebResponse){
		
		let sequence  = request.param("sequence")
		let sequenceArr = sequence!.componentsSeparatedByString("_")
		
		let db = try! DatabaseManager()
		
		let curProject = currentProject(request, response: response)
		
		var userStories = curProject?.userStories
		
		userStories = userStories!.sort({$0.rankingIndex < $1.rankingIndex})
		
		var tmpUserStories : [UserStory] = []
		
		for(var i = 1; i < sequenceArr.count; i++){
			for(var j = 0; j < userStories!.count; j++){
				if(userStories![j].rankingIndex == Int(sequenceArr[i])){
					tmpUserStories.append(userStories![j])
				}
			}
		}
		
		for(var i = 0; i < tmpUserStories.count ; i++ ){
			
			tmpUserStories[i].rankingIndex = i+1
			
			db.updateObject(tmpUserStories[i])
			
		}
		
		response.redirectTo("/userstories")
		response.requestCompletedCallback()
	}
	
    func show(identifier: String, request: WebRequest, response: WebResponse) throws -> MustacheEvaluationContext.MapType {
        // Query User Story
        let id = Int(identifier)!
        let tempUserStory: UserStory? = getUserStoryWithIdentifier(id)

        guard let userStory = tempUserStory else {
            return MustacheEvaluationContext.MapType()
        }
        
        var values: MustacheEvaluationContext.MapType = [:]
        values["userStory"] = userStory.dictionary
        
        let commentList = userStory.loadCommentDetailsForMustahce(currentUser(request, response: response)!)
        values["commentList"] = commentList
        values["identifier"] = identifier 
        return values
        
    }
    
    func update(identifier: String, request: WebRequest, response: WebResponse) {
      
        let id = Int(identifier)!
        
        // Handle new post request
        if let title = request.param("title"), body = request.param("body"), userStory =  getUserStoryWithIdentifier(id) {
            
            // Update post properties
            userStory.title = title
            userStory.story = body
            
            // Save Article
            do {
                try DatabaseManager().updateObject(userStory, updateValues: userStory.dictionary)
                response.redirectTo("/\(modelName)s/\(identifier)")
                response.redirectTo(userStory)
            } catch {
                print(error)
            }
        }
        
     
        response.requestCompletedCallback()
    }
    
 
    func edit(identifier: String, request: WebRequest, response: WebResponse) throws -> MustacheEvaluationContext.MapType {

      
        guard let userStory = getUserStoryWithIdentifier(Int(identifier)!) else {
            return MustacheEvaluationContext.MapType()
        }
        
        let values = ["userStory": userStory.dictionary] as  MustacheEvaluationContext.MapType
        return values
 
    }
 
    func newComment(request: WebRequest, response: WebResponse,identifier: String) {
        
        print("New Comment")
        guard var userStory = getUserStoryWithIdentifier(Int(identifier)!) else {
            return response.redirectTo("/")
        }
        
        if let comment = request.param("comment"), user = currentUser(request, response: response) {
            
            // Post comment
            let newComment = Comment(comment: comment, user: user)
            userStory.addComment(newComment)
            
            
            
            response.redirectTo(userStory)
            
        }
        response.requestCompletedCallback()
        
    }
    
    func new(request: WebRequest, response: WebResponse) {
        
        // Handle new post request
		if let title = request.param("title"), body = request.param("story"), priority = request.param("storyPriority"), component = request.param("component"), typeRaw = request.param("type") {
		
            let userStoryPriority = UserStoryPriority(rawValue: Int(priority)!)!
			let type = StoryType(rawValue: Int(typeRaw)!)!
            // Valid Article
            let newUserStory = UserStory(title: title, story: body, priority: userStoryPriority, component: component, type: type)
			
			let curProject = currentProject(request, response: response)	//calculate ranking index
			
			let amountOfStory = curProject?.userStories.count
			
			newUserStory.rankingIndex = amountOfStory!+1
			
			// Save Article
            do {

                if let project = currentProject(request, response: response) {
                    try project.addUserStory(newUserStory)
                }
                
                response.redirectTo("/userstories")
            } catch {
                
            }
        }
        
        response.requestCompletedCallback()
    }
	
	
    
    func create(request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType
    {
        return [:]
    }
    
    func delete( request: WebRequest, response: WebResponse,identifier: String) {
        
        let id = Int(identifier)!
        let db = try! DatabaseManager()
        if let userStory: UserStory = getUserStoryWithIdentifier(id) {
            try! db.deleteObject(userStory)
        }
		
		
        
        response.redirectTo("/userstories")
        response.requestCompletedCallback()
    }
    
    func deleteComment(request: WebRequest, response: WebResponse, identifier: String) {
        // 0: userstory identifier, 1: Comment position
        let informationGet = identifier.componentsSeparatedByString("_")
        
        let id = Int(informationGet[0])!
        
        let deleteIndex = Int(informationGet[1])
        
        let db = try! DatabaseManager()
        
        guard let userstory = db.executeFetchRequest(UserStory.self, predicate: ["identifier": id]).first else {
            return
        }
        
        userstory.comments.removeAtIndex(deleteIndex!)
        
        db.updateObject(userstory)
        
        response.redirectTo("/userstories/\(id)")
        response.requestCompletedCallback()
    }
    
    func updateComment(request: WebRequest, response: WebResponse, identifier: String) {
        // 0: userstory identifier, 1: New comment, 2: index of old comment
        let informationGet = identifier.componentsSeparatedByString("_")
        
        let id = Int(informationGet[0])!
        
        let newComment = informationGet[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        let indexOfOldComment = Int(informationGet[2])
        
        let db = try! DatabaseManager()
        
        guard let userstory = db.executeFetchRequest(UserStory.self, predicate: ["identifier": id]).first else{
            return
        }
        
        userstory.comments[indexOfOldComment!].comment = newComment
        
        db.updateObject(userstory)
        
        response.redirectTo("/userstories/\(id)")
        response.requestCompletedCallback()
        
    }


    
    
}