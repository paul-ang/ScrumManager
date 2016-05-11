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
    
    var taskIDs: [String] = []
    
    var userStoryIDs: [String] = []
    
    var title: String
    
    var body: String
    
    var duration: String
    
    var identifier: Int = 0
    
    init(body: String, title: String, duration: String) {
        self.title = title
        self.body = body
        self.duration = duration
    }
    
    
    convenience init(dictionary: [String : Any]) {
        let title = dictionary["title"] as! String
        
        let id = (dictionary["_id"] as? JSONDictionaryType)?["$oid"] as? String
        
        let body = dictionary["body"] as! String
        
        let duration = dictionary["duration"] as! String
        
        let identifier = dictionary["identifier"] as! Int
        
        
        self.init(body: body, title: title, duration: duration)
        self._objectID = id
        self.identifier = identifier
        self.comments = loadCommentsFromDictionary(dictionary)
       
        // Load User Stories
      let userStoryIdentifier = dictionary["userstory"] as? [String] ?? []
        userStoryIDs = userStoryIdentifier
        print("\(userStoryIDs)")
       let taskIdentifiers = dictionary["task"] as? [String] ?? []
        taskIDs = taskIdentifiers
        print("\(taskIDs)")
 

        
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
    
    init?(identifier: String) {
        
        title = ""
        body = ""
        duration = ""
        super.init()
        
        return nil
    }
}

extension Sprint {
    
    var userStories: [UserStory] {
        // Query Database
        return try! DatabaseManager().getObjectsWithIDs(UserStory.self, objectIDs: userStoryIDs)
    }
    
    
    
    
}

extension Sprint : Routable {
    
    static var collectionName: String = "sprint"

    var pathURL : String { return "/sprints/\(identifier)" }
    var editURL : String { return "/sprints/\(identifier)/edit" }
    
    var tasks: [Task] { return try! DatabaseManager().getObjectsWithIDs(Task.self, objectIDs: self.taskIDs) }

  //  var userStories: [UserStory] { return try! DatabaseManager().getObjectsWithIDs(UserStory.self, objectIDs: self.userStoryIDs) }
    
    static var ignoredProperties: [String] {
        return ["comments"] //["urlPath"]
    }
    
    var dictionary: [String: Any] {
        var dict = keyValues
        dict["userStories"] = userStories.map({ (userStory) -> [String: Any] in
            return userStory.dictionary
        })
        
        
        return dict
        
        
    }
    
    
}