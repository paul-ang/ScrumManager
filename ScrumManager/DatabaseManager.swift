//
//  DatabaseManager.swift
//  SwiftBlog
//
//  Created by Benjamin Johnson on 9/02/2016.
//  Copyright © 2016 Benjamin Johnson. All rights reserved.
//

import PerfectLib
import MongoDB

protocol PrimaryKey {}

extension Int: PrimaryKey {}
extension String: PrimaryKey {}

class DatabaseManager {

    let mongo: MongoClient
    
    static let databaseName = "scrummanager"
    
    static let mongoURI = "mongodb://localhost"
    
    static let sharedManager = try! DatabaseManager()
    

    private var database: MongoDatabase {
        return mongo.getDatabase(DatabaseManager.databaseName)
    }
    
    func objects(type: DBManagedObject.Type) -> MongoCollection {
        return database.getCollection(type)
    }
    
    init() throws {
       
            mongo =  try! MongoClient(uri: DatabaseManager.mongoURI)
            let status = mongo.serverStatus()
        
            switch status {
            
            case .Error(let domain, let code, let message):
                assert(false, "Error connecting to mongo: \(domain) \(code) \(message). Did you start MongoDB with mongod in terminal?")
            
            case .ReplyDoc(let doc):
                print("Status doc: \(doc)")
                assert(true)
            
            default:
                assert(false, "Strange reply type \(status)")
            }
 
      
    }
    
    func updateObject(object: DBManagedObject, updateValues: [String: Any]) {
        if let identifierDictionary = object.identifierDictionary {
            let query: [String: Any] = ["_id": identifierDictionary]
            update(object.dynamicType, predicate: query, update: updateValues)

        }
    }
    
    func updateObject(object: DBManagedObject) {
        updateObject(object, updateValues: object.keyValues)
    }
    
    func update(objectCollection: DBManagedObject.Type, predicate: [String: Any], update: [String: Any]) {
        let collection = database.getCollection(objectCollection)
        let updateBSON = try! BSON(dictionary: ["$set":update] as [String: Any])
        let resut = collection.update(updateBSON, selector: try! BSON(dictionary: predicate))
       //let resut =  collection.update(try! BSON(), selector: updateBSON)
        print(resut)
    }
    
    func executeFetchRequest<Collection: DBManagedObject>(collection: Collection.Type, predicate: [String: Any] = [:]) -> [Collection] {
        let collectionBSON = database.getCollection(collection).find(predicate);
        var objects: [Collection] = []
        while let objectBSON = collectionBSON?.next() {
            let object = Collection(bson: objectBSON)
            objects.append(object)
        }
        
        collectionBSON?.close()
        return objects
    }
    
    func countForFetchRequest(collection: DBManagedObject.Type, predicate: [String: Any] = [:]) -> Int {
        
        let result = database.getCollection(collection).count(try! BSON(dictionary: predicate))
        let count: Int
        switch result {
        case .ReplyInt(let resultCount):
            count = resultCount
        default:
            count = -1
        }
        
        return count
    }
    
    func getObjectWithID<Collection: DBManagedObject>(collection: Collection.Type, objectID: String) -> Collection? {
        
        guard  objectID.length > 0 else  {
            return nil
        }
        
        let identifierDictionary = ["$oid": objectID] as Dictionary<JSONKey, JSONValue>
        
        let query: [String: JSONValue] = ["_id": identifierDictionary]
        let jsonEncode = try! JSONEncoder().encode(query)
        
        let cursor = database.getCollection(collection).find(try! BSON(json: jsonEncode))
        defer {
            cursor?.close()
        }
        
        if let bson = cursor?.next() {
            return Collection(bson: bson)

        } else {
            return nil
        }
    }
    
    func getObjectsWithIDs<Collection: DBManagedObject>(collection: Collection.Type, objectIDs: [String]) -> [Collection] {

        var objectIdentifiers = objectIDs.map { (objectID) -> Dictionary<JSONKey, JSONValue> in
            return ["$oid": objectID] as Dictionary<JSONKey, JSONValue>
        }
        
        let query: [String: JSONValue] = ["_id": ["$in": objectIdentifiers] as [String: Any]]
        let jsonEncode = try! JSON().encode(query)
        
        let cursor = database.getCollection(collection).find(try! BSON(json: jsonEncode))
        defer {
            cursor?.close()
        }
        var collections: [Collection] = []
        
        while let bson = cursor?.next() {
            collections.append(Collection(bson: bson))
        }
        
        return collections
    }
    
    func getObject<Collection: DBManagedObject>(collection: Collection.Type, primaryKeyValue: Int) -> Collection? {
        
        guard let primaryKeyName = collection.primaryKey else {
            fatalError("No primary key set for \(collection)")
        }
        
        // Create Query
        let query = [primaryKeyName: primaryKeyValue]
        
        let cusor = database.getCollection(collection).find(try! BSON(dictionary: query), fields: nil, flags: MongoQueryFlag(rawValue: 0), skip: 0, limit: 1, batchSize: 0)
        
        defer {
            cusor?.close()
        }
        
        if let bson = cusor?.next() {
            return Collection(bson: bson)
        }
    
        return nil
    }
    
    func insertObject(object: DBManagedObject) throws {
        if let obj = object as? Object where obj._objectID == nil {
            obj._objectID = database.generateObjectID()
        }
        
			try! database.insert(object)
    }
    
    func insertTask(task: Task) throws {
        
        // Set Identifier
        let taskCount = self.countForFetchRequest(Task)
        guard taskCount > -1 else {
            throw CreateUserError.DatabaseError
        }
        task.identifier = taskCount

        try insertObject(task)
    }
    
    func deleteObject(object: DBManagedObject) throws {
        //try! databas
        if let identifierDictionary = object.identifierDictionary {
            let query: [String: JSONValue] = ["_id": identifierDictionary]
            let jsonEncode = try JSONEncoder().encode(query)
            
            database.getCollection(object.dynamicType).remove(try! BSON(json: jsonEncode), flag: MongoRemoveFlag.SingleRemove)
        }
    }
    
    func deleteObjects(objects: [DBManagedObject]) throws {
        
        for object in objects {
            try deleteObject(object)
        }
    }
    
    func deleteObjectsWithPredicate(collection: DBManagedObject.Type, predicate: [String: Any] = [:]) {
        database.getCollection(collection).remove(try! BSON(dictionary: predicate))
    }
    
    func generateUniqueIdentifier() -> String {
        return database.generateObjectID()
    }
}

class Object {
    var _objectID: String? = nil
}



