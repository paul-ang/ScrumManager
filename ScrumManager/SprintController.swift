//
//  SprintController.swift
//  ScrumManager
//
//  Created by Pyi Thein Maung on 3/05/2016.
//  Copyright © 2016 Benjamin Johnson. All rights reserved.
//
import PerfectLib


 class SprintController: AuthController  {
 
    let modelName : String  = "sprint"
    
    let modelPluralName : String  = "sprints"
    
    let pageTitle: String = "Sprints"
    
    var projectID : String = ""
    
    var newURL: String = ""
    
    var userRolesWithModifiyPermission: [UserRole] = [.ScrumMaster, .Admin]
    
    //create new sprint
    func new(request: WebRequest, response: WebResponse) {
        if let title = request.param("title"), rawDuration = request.param("duration"), userStoryIDs = request.params("userStories"), duration = Double(rawDuration) {
            print("new is called")
                        
            let sprint = Sprint(title: title, duration: (duration*360))
            print("\(sprint)")
            print("\(request.param("title"))")
            print("\(projectID)")

            let databaseManager = try! DatabaseManager()
            
            guard let tmpProject = currentProject(request, response: response) else {
                response.requestCompletedCallback()
                return
            }
            
                sprint._objectID = databaseManager.generateUniqueIdentifier()
                
                let sprintIndex = databaseManager.countForFetchRequest(Sprint)

                sprint.identifier = sprintIndex
                sprint.userStoryIDs = userStoryIDs
            do{
                try databaseManager.insertObject(sprint)
                tmpProject.addSprint(sprint)
                databaseManager.updateObject(tmpProject)
                
                print("inserted \(sprint)")
                response.redirectTo(sprint)
                
            }catch{
                print("failed to create sprint")
            }
        }
        response.requestCompletedCallback()
    }
    
    func availableActionsForControllerObjects(request: WebRequest, response: WebResponse) -> [Action] {
        guard let user = currentUser(request, response: response) else {
            return []
        }
        
        switch user.role {
        case .Admin,.ScrumMaster:
            return [addAction]
        default:
            return []
        }
    }
    
    func create(request: WebRequest, response: WebResponse) throws ->  MustacheEvaluationContext.MapType
    {
        
		if let projectIdentifier = request.param("projectID"){
		projectID = projectIdentifier
        let db = try! DatabaseManager()
		let targetProject = db.getObjectWithID(Project.self, objectID: projectID)
			
        let userStories = targetProject!.userStories
			
        var counter = 0
        let userStoriesJSON = userStories.map { (userStory) -> [String: Any] in
            var userStoryDict = userStory.dictionary
            userStoryDict["index"] = counter
            counter += 1
            
            return userStoryDict
        }
        
        
        let values :MustacheEvaluationContext.MapType = ["userStories": userStoriesJSON]
        return values
		}else{
			return [:]
		}
		
    }
    
    func show(identifier: String, request: WebRequest, response: WebResponse) throws -> MustacheEvaluationContext.MapType {
        
		let id=Int(identifier)!
        let tempSprint:Sprint? = getSprintWithID(id)
        
        guard let sprint = tempSprint else {
            return MustacheEvaluationContext.MapType()
        }
        
        var values: MustacheEvaluationContext.MapType = [:]
        
        values["sprint"] = sprint.dictionary
        // For deletion and editing 
        let user = currentUser(request, response: response)
        
        let commentList : [[String:Any]] = sprint.loadCommentDetailsForMustahce(user!)
        
        values["commentList"] = commentList
        
        let chosenUserStory = sprint.userStories
		
		let storyJSON = chosenUserStory.map { (userstory) -> [String:Any] in
			
			return userstory.dictionary
			
		}
		
		let taskJSON = sprint.tasks.map { (task) -> [String:Any] in
			var dic =  task.dictionary
			
			if let story = task.userStory{
				dic["storyName"] = story.title
				
			}else{
				dic["storyName"] = "None"
			}
			
			
			
			if let user = task.user{
				dic["user"] = user.name
				dic["buttonAM"] = "Unassign"
			}else{
				dic["user"] = "None"
				dic["buttonAM"] = "Assign"
			}
		
			
			
			return dic
		
		}
		
		
		
        let workDurations = sprint.burndownReports.map { (report) -> NSTimeInterval in
            return report.dailyWorkDuration
        }
        // Generate Burndown chart
        let burndownChart = BurndownChart(workDurations: workDurations, totalWorkRemaining: NSTimeInterval(60 * 60 * 24 * 3), dueDate: NSDate().dateByAddingTimeInterval(NSTimeInterval(60 * 60 * 24 * 5)))
        
        values["burndownChart"] = burndownChart.dictionary
		values["userStory"] =  storyJSON
		values["tasks"] = taskJSON
        values["identifier"] = identifier
			
        
             let currentLoginUser = currentUser(request, response: response)
        
        if modelPluralName == "sprints" && currentLoginUser?.role == .Admin{
            let editURL = "/\(modelPluralName)/\(identifier)/edit"
            let editAction = Action(url: editURL, icon: "", name: "Edit", isDestructive: false)
            values["actions"] = editAction
        }
        
        return values
        
    }
    
    func list(request: WebRequest, response: WebResponse) throws -> MustacheEvaluationContext.MapType {
        guard let project = currentProject(request, response: response) else {
            return [:]
        }
        
        let sprints = project.sprints
        var counter = 0
        let sprintJSONs = sprints.map { (sprint) -> [String:Any] in
            var sprintDictionary = sprint.dictionary
            sprintDictionary["index"] = counter
            counter += 1
            return sprintDictionary
        }
        
        let values : MustacheEvaluationContext.MapType = ["sprints":sprintJSONs]
        
        newURL = "/sprints/new?projectID=\(project._objectID!)"

        
        return values
        
    }
    


    
    func getSprintWithID(identifier: Int) -> Sprint? {
        let db = try! DatabaseManager()
        guard let sprint = db.executeFetchRequest(Sprint.self, predicate: ["identifier": identifier]).first else {
            return nil
        }
        
        return sprint
    }
    
    func newComment(request: WebRequest, response: WebResponse,identifier: String) {
        
        print("New Comment")
        
        guard var sprint = getSprintWithID(Int(identifier)!) else {
            return response.redirectTo("/")
        }
        
        if let comment = request.param("comment"), user = currentUser(request, response: response) {
            
            // Post comment
            let newComment = Comment(comment: comment, user: user)
            sprint.addComment(newComment)
            response.redirectTo(sprint)
            
        }
        
        response.requestCompletedCallback()
        
    }

 
    func delete(identifier: String,request: WebRequest, response: WebResponse) {
        
        let db = try! DatabaseManager()
        if let sprint = db.getObject(Sprint.self, primaryKeyValue: Int(identifier)!){
            try! db.deleteObject(sprint)
        }
        response.requestCompletedCallback()
        
    }
    
 
    //selected user stories = getUserstorywithID
    func getUserStoryWithIdentifier(identifier: Int) -> UserStory? {
        let db = try! DatabaseManager()
        guard let userStory = db.executeFetchRequest(UserStory.self, predicate: ["identifier": identifier]).first else {
            return nil
        }
 
        return userStory
    }
    
    
    func edit(identifier: String, request: WebRequest, response: WebResponse) throws -> MustacheEvaluationContext.MapType {
        

        
			guard let sprint = getSprintWithID(Int(identifier)!) else {
				return MustacheEvaluationContext.MapType()
			}
			
				
			let values = ["sprint": sprint.dictionary] as MustacheEvaluationContext.MapType
			return values

    }
    


    
    func update(identifier: String,request: WebRequest, response: WebResponse) {
        
        if let newTitle = request.param("title"), newBody = request.param("body"), rawDuration = request.param("duration"), duration = Double(rawDuration), newUserStoryIDs = request.params("userStories") {
            
            let databaseManager = try! DatabaseManager()
            
            guard let oldSprint = databaseManager.executeFetchRequest(Sprint.self, predicate :["identifier": Int(identifier)!]).first else{
                response.requestCompletedCallback()
                return
            }
            
            oldSprint.title = newTitle
            oldSprint.duration = duration
            oldSprint.userStoryIDs = newUserStoryIDs
            
            databaseManager.updateObject(oldSprint, updateValues: oldSprint.dictionary)
            response.redirectTo(oldSprint)
        }else{
            response.requestCompletedCallback()
        }
    }

    func beforeAction(request: WebRequest, response: WebResponse) -> MustacheEvaluationContext.MapType {
        return [:]
    }
	
	func obtainTasks(request: WebRequest, response: WebResponse, identifier:String) -> String{
	
		let take1 = request.param("test1")!
		print(take1)
		print(identifier)
		let project = currentProject(request, response: response)
		
//		let encodedTest = try! JSON().encode((project?.dictionary)!)
		//let encodedTest = ["test" : "hello world"] as MustacheEvaluationContext.MapType
		return "ABLE TO RETURN VALUE"
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
        
        sprint.comments[indexOfOldComment!].comment = newComment
        
        db.updateObject(sprint)
        
        response.redirectTo("/sprints/\(id)")
        response.requestCompletedCallback()
        
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

        sprint.comments.removeAtIndex(deleteIndex!)
        
        db.updateObject(sprint)
        
        response.redirectTo("/sprints/\(id)")
        response.requestCompletedCallback()
    }
    
    func editSprintDetails(request: WebRequest, response: WebResponse, identifier: String) {
        if let title = request.param("title"),rawDuration = request.param("duration"), duration = Double(rawDuration){
            let id = Int(identifier)!
            let db = try! DatabaseManager()
            guard let sprint = db.executeFetchRequest(Sprint.self, predicate: ["identifier": id]).first else {
                return
            }
            sprint.title = title
            sprint.duration = duration*360
            db.updateObject(sprint)
            response.redirectTo("/sprints/\(identifier)")
            response.requestCompletedCallback()
        }
    }
    
    func finishSprint(request: WebRequest, response: WebResponse, identifier: String) {
        let id = Int(identifier)!
        let db = try! DatabaseManager()
        
        guard let sprint = db.executeFetchRequest(Sprint.self, predicate: ["identifier": id]).first else {
            return
        }
        
        sprint.status = systemWideStatus.Completed
        
        db.updateObject(sprint)
        
        response.redirectTo("/sprints")
        response.requestCompletedCallback()
    
    }

    func availableActionsForObjectWithIdentifier(identifier: String, request: WebRequest, response: WebResponse) -> [Action] {
        
        
        let finishURL = "/\(modelPluralName)/\(identifier)/finish"
        let editURL = "/\(modelPluralName)/\(identifier)/edit"
        
        let finishAction = Action(url: finishURL, icon: "", name: "Finish Sprint", isDestructive: false)
        let editAction = Action(url: editURL, icon: "", name: "Edit", isDestructive: false)
        
        guard let user = currentUser(request, response: response) else {
            return []
        }
        
        if user.role == .Admin {
            return [editAction, finishAction]
        } else if user.role == .ScrumMaster {
            
            if let project = DatabaseManager.sharedManager.executeFetchRequest(Project.self, predicate: ["identifier": Int(identifier)!]).first where project.scrumMasterID! == user._objectID!   {
                
                return [editAction, finishAction]
            }
        }
        
        
        return []
    }
    
    func controllerActions() -> [String: ControllerAction] {
        
        var modelActions:[String: ControllerAction] = [:]
        
        modelActions["comments"] = ControllerAction() {(request, response, identifier) in self.newComment(request, response:response, identifier:identifier)}
        
        modelActions["obtain"] = ControllerAction() {(request,response, identifier) in self.obtainTasks(request, response: response, identifier: identifier)}
        
        modelActions["updatecomment"] = ControllerAction() {(request, resp,identifier) in self.updateComment(request, response: resp, identifier: identifier)}
        
        modelActions["deletecomment"] = ControllerAction() {(request, resp,identifier) in self.deleteComment(request, response: resp, identifier: identifier)}
        
        modelActions["editsprintdetails"] = ControllerAction() {(request, resp,identifier) in self.editSprintDetails(request, response: resp, identifier: identifier)}
        
        modelActions["finish"] = ControllerAction() {(request, resp,identifier) in self.finishSprint(request, response: resp, identifier: identifier)}
        
        return modelActions
    }


    
    
 }