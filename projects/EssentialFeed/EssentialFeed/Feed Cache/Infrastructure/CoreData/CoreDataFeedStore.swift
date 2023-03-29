//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Bradley Mackey on 28/05/2022.
//

import CoreData

public final class CoreDataFeedStore {
    public static let modelName = "FeedStore"
    public static let model = NSManagedObjectModel.with(name: modelName, in: Bundle(for: CoreDataFeedStore.self))
    
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: CoreDataFeedStore.modelName, url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }
    
    func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform {
            action(context)
        }
    }
}

extension Result where Failure == Error {
    /// An initializer that can perform cleanup after a failure.
    init(catching: () throws -> Success, afterFailure: () -> Void) {
        do {
            let result = try catching()
            self = .success(result)
        } catch {
            afterFailure()
            self = .failure(error)
        }
    }
}
