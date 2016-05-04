//
//  Project.swift
//  ScrumManager
//
//  Created by Ben Johnson on 17/03/2016.
//  Copyright © 2016 Benjamin Johnson. All rights reserved.
//

import Foundation

enum Priority: Int {
    case Low
    case Medium
    case High
}

typealias TimeInterval = Double

final class Project {
    
    let name: String
    let projectDescription: String


    init(name: String, projectDescription: String) {
        self.name = name
        self.projectDescription = projectDescription
        
    }
}

class ProductBacklog {
    
    var userStories: [UserStory] = []
    
    // Anything required here???
    
    func addUserStory(userStory: UserStory) throws {
        
    }
    
    // If a user story is already in the release backlog, it shouldn't be able to be deleted
    func deleteUserStory(userStory: UserStory) throws {
        
    }
    
}



class Task {
    
    var taskDescription: String
    
    var user: User? = nil
    
    init(taskDescription: String) {
        self.taskDescription = taskDescription
    }
}



struct TimeEstimate {
    
    let timeInterval: TimeInterval
    
    var priority: Priority
    
}



class ReleaseBacklog {
    
    var userStories: [UserStory] = []
    
    func addUserStory(userStory: UserStory) throws {
        
    }
    
    // If a user story is already in the release backlog, it shouldn't be able to be deleted
    func deleteUserStory(userStory: UserStory) throws {
        
    }
    
    
}



