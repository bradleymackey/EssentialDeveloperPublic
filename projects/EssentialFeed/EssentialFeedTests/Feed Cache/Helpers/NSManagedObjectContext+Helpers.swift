//
//  NSManagedObjectContext+Helpers.swift
//  EssentialFeedTests
//
//  Created by Bradley Mackey on 06/08/2022.
//

import CoreData

extension NSManagedObjectContext {
    func allExistingObjects() throws -> [NSManagedObject] {
        guard let model = persistentStoreCoordinator?.managedObjectModel else {
            return []
        }
        
        return try model
            .entities
            .compactMap { $0.name }
            .reduce([NSManagedObject](), { acc, entity in
                let request = NSFetchRequest<NSManagedObject>(entityName: entity)
                return try acc + fetch(request)
            })
    }
}
