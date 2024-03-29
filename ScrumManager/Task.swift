//
//  Task.swift
//  ScrumManager
//
//  Created by Ben Johnson on 4/05/2016.
//  Copyright © 2016 Benjamin Johnson. All rights reserved.
//

import Foundation
import MongoDB
import PerfectLib

final class Task: Object, DBManagedObject, DictionarySerializable, CustomDictionaryConvertible, Commentable {
    
    var title: String
    
    var description: String
    
    var comments: [Comment] = []
    
    var estimates: NSTimeInterval = 0          //in hours
    
    var priority: UserStoryPriority
    
    var status: TaskStatus = .Unassigned
    
    var workDone : NSTimeInterval = 0          // in seconds
    
    var identifier: Int = 0
    
    var userID: String?  // User who is assigned to task
        
    var UserStoryID: String = "" // belong to which UserStoryID

   // lazy var user: User? = try! DatabaseManager().getObjectWithID(User.self, objectID: self.userID ?? "")
    
    convenience init(bson: BSON) {
        
        let json = try! (JSONDecoder().decode(bson.asString) as! JSONDictionaryType)
        
        let dictionary = json.dictionary
        
        self.init(dictionary: dictionary)
    }
    
    init?(identifier: String) {
        
        title = ""
        description = ""
        priority = .High
        
        super.init()
        
        return nil
    }
    
    init(title: String, description: String, priority: UserStoryPriority ) {
        self.title = title
        self.description = description
        self.priority = priority
    }
    
    convenience init(dictionary: [String: Any]) {
        
        let taskBody = dictionary["title"] as! String
        let taskDesc = dictionary["description"] as! String
        let rawPriority = dictionary["priority"] as! Int
        let priority = UserStoryPriority(rawValue: rawPriority)!
        
        self.init(title: taskBody, description: taskDesc, priority: priority )
        
        self.userID = (dictionary["userID"] as? String) ?? ""
        
        self.identifier = dictionary["identifier"] as! Int
        
        let rawStatus = dictionary["status"] as! Int
        
        self.status = TaskStatus(rawValue: rawStatus)!
        
        let id = (dictionary["_id"] as? JSONDictionaryType)?["$oid"] as? String
        
        let workDoneInt = dictionary["workDone"] as? Int ?? 0
		
		self.workDone = NSTimeInterval(workDoneInt)
        
        let estimateInt = (dictionary["estimates"] as? Int) ?? 0
		
		self.estimates = NSTimeInterval(estimateInt)
		
		self.UserStoryID = dictionary["UserStoryID"] as? String ?? ""

		
        self._objectID = id
        
        // Load Comments 
        self.comments = loadCommentsFromDictionary(dictionary)

    }
  
   
}

extension Task {
    
    static var collectionName: String = "task"
	
	var keyValues:[String: Any] {
		return [
			"title" : title,
			"description" : description,
			"estimates" : estimates,
			"priority" : priority,
			"status" : status,
			"workDone" : workDone,
			"identifier" : identifier,
			"userID" : userID ?? "",
			"UserStoryID" : UserStoryID,
			"comments": comments.map({ (comment) -> [String: Any] in
				return comment.dictionary
			}),
			"urlPath": pathURL
			
		]
		
	}
	
	
	var dictionary: [String: Any] {
		return [
			"title" : title,
			"description" : description,
			"estimates" : estimates/360,
			"priority" : priority,
			"status" : status,
			"workDone" : FormatterCache.shared.componentsFormatter.stringFromTimeInterval(workDone)!,
			"identifier" : identifier,
			"userID" : userID ?? "",
			"UserStoryID" : UserStoryID,
			"comments": comments.map({ (comment) -> [String: Any] in
				return comment.dictionary
			}),
			"urlPath": pathURL
		]
	}

	
    static var ignoredProperties: [String] {
		
        return ["user",  "comments"]
		
    }
    
    
    var user: User? {
        get {
			if let userID = userID {
                return try! DatabaseManager().getObjectWithID(User.self, objectID: userID)
			} else{
				return nil
			}
		}
        
        set {
            userID = (newValue?._objectID)
            status = .InProgress
        }
    }
	
	var userStory: UserStory? {
		return try! DatabaseManager().getObjectWithID(UserStory.self, objectID: UserStoryID)
	}

	
	
	
    func assignUser(newUser: User) {
        if isAssigned(newUser) {
            return
        }
        
        user = newUser
        
        // Update task
        let db = try! DatabaseManager()
        db.updateObject(self)
        
        // Update User
        newUser.addTask(self)
        db.updateObject(newUser)
    }
    
    func unassignUser(newUser: User) {
        if !isAssigned(newUser) {
            return
        }
        
        user = nil
        // Update task
        let db = try! DatabaseManager()
        db.updateObject(self)
        
        // Update User
        newUser.removeTask(self)
        db.updateObject(newUser)
        
    }
    
    
    func isAssigned(newUser: User) -> Bool {
        if  newUser._objectID == userID {
            return true
        } else {
            return false
        }
      
    }
        
    
    func simulateTaskProgress(startDate: NSDate = NSDate()) {
        
        
        
        let estimatedDuration = estimates
        
        // Work out how many progress updates
        let updates = (estimatedDuration / (60 * 60)) + 1
        
        
        
    }
    
	
	func updateWorkDone(duration:NSTimeInterval){
		workDone += duration
	}
}

extension Task: Routable {
    
    var pathURL: String { return "/tasks/\(identifier)" }
    
    var editURL: String { return "/tasks/\(identifier)/edit" }
    
    var destoryURL: String { return "/tasks/\(identifier)/destory" }

}






