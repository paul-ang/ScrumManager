//
//  Sprint.swift
//  ScrumManager
//
//  Created by Ben Johnson on 20/04/2016.
//  Copyright © 2016 Benjamin Johnson. All rights reserved.
//

import Foundation
import PerfectLib
import MongoDB


final class Sprint: Object, DBManagedObject, Commentable {
    
    var comments: [Comment] = []
    
    var userStoryIDs: [String] = []
    
    var tasks : [Task] = []
    
    var title: String
    
    var body: String
    
    var reviewReport: SprintReviewReport?
    
    var duration: NSTimeInterval
    
    var identifier: Int = 0
    
    init(body: String, title: String, duration: Double) {
        self.title = title
        self.body = body
        self.duration = duration
    }
    
    
    convenience init(dictionary: [String : Any]) {
        let title = dictionary["title"] as! String
        
        let id = (dictionary["_id"] as? JSONDictionaryType)?["$oid"] as? String
        
        let body = dictionary["body"] as! String
        
        let duration = Double(dictionary["duration"] as? Int ?? 0)
        
        let identifier = dictionary["identifier"] as! Int
        
        self.init(body: body, title: title, duration: duration)
        self._objectID = id
        self.identifier = identifier
        self.comments = loadCommentsFromDictionary(dictionary)
        
        // Load User Stories
        self.userStoryIDs = (dictionary["userStoryIDs"] as? JSONArrayType)?.stringArray ?? []
        
        
        if let reviewReport = (dictionary["reviewReport"] as? JSONDictionaryType)?.dictionary {
            self.reviewReport = SprintReviewReport(dictionary: reviewReport)
        }
        
        if let tasks = dictionary["tasks"] as? [Task] {
            self.tasks = tasks
        }
        
        
    }
    
    convenience init(bson: BSON) {
        
        let json = try! (JSONDecoder().decode(bson.asString) as! JSONDictionaryType)
        
        let dictionary = json.dictionary
        
        self.init(dictionary: dictionary)
        
        
        /*
         // Load Tasks
         if let taskArray = (dictionary["tasks"] as? JSONArrayType)?.array {
         
         tasks = taskArray.map({ (taskDictionary) -> Task in
         let taskDict = taskDictionary as! JSONDictionaryType
         return Task(dictionary: taskDict.dictionary)
         })
         }
         */
        
    }
    
}

extension Sprint {
    
    var userStories: [UserStory] {
        // Query Database
        return try! DatabaseManager().getObjectsWithIDs(UserStory.self, objectIDs: userStoryIDs)
    }
    
    var keyValues:[String: Any] {
        
        return [
            "title": title,
            "body": body,
            "userStoryIDs" : userStoryIDs,
            "comments": comments.map({ (comment) -> [String: Any] in
                return comment.dictionary
            }),
            "urlPath": pathURL,
            "identifier": identifier,
            "duration": duration
        ]
        
    }
    
    var dictionary: [String: Any] {
        var dict = keyValues
        
       // dict["userStories"] = userStories.map({ (userStory) -> [String: Any] in
         //   return userStory.dictionary
       // })
 
        let tasks = try! DatabaseManager().executeFetchRequest(Task.self)
        
        dict["tasks"] = tasks.map({ (task) -> [String: Any] in
            return task.dictionary
        })
        
        return dict
    }
    
    var totalAmountOfWork: NSTimeInterval {
        
        var amountOfWork: NSTimeInterval = 0
        
        for userStory in userStories {
            amountOfWork += userStory.estimatedDuration ?? 0
        }
        
        return amountOfWork
    }
    
}

extension Sprint : Routable {
    
    static var collectionName: String = "sprint"
    
    var pathURL : String { return "/sprints/\(identifier)" }
    
    var reportURL : String { return "/sprints/\(identifier)/report" }
    
    var editURL : String { return "/sprints/\(identifier)/edit" }

    
    //  var userStories: [UserStory] { return try! DatabaseManager().getObjectsWithIDs(UserStory.self, objectIDs: self.userStoryIDs) }
    
  //  static var ignoredProperties: [String] {
    //    return ["comments"] //["urlPath"]
    //}
    
    
}