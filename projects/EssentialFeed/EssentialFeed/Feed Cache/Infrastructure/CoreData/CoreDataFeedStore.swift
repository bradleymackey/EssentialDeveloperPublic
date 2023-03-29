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
    
    enum StoreError: Error {
        case modelNotFound
        case failedToLoadPersistentContainer(Error)
    }
    
    public init(storeURL: URL) throws {
        guard let model = CoreDataFeedStore.model else {
            throw StoreError.modelNotFound
        }
        do {
            container = try NSPersistentContainer.load(name: CoreDataFeedStore.modelName, model: model, url: storeURL)
            context = container.newBackgroundContext()
        } catch {
            throw StoreError.failedToLoadPersistentContainer(error)
        }
    }
    
    func performSync<R>(_ action: (NSManagedObjectContext) -> Result<R, Error>) throws -> R {
        let context = self.context
        var result: Result<R, Error>!
        context.performAndWait {
            result = action(context)
        }
        return try result.get()
    }
    
    private func cleanUpReferencesToPersistentStores() {
        context.performAndWait {
            let coordinator = self.container.persistentStoreCoordinator
            try? coordinator.persistentStores.forEach(coordinator.remove)
        }
    }
    
    deinit {
        cleanUpReferencesToPersistentStores()
    }
    
    func performAsync(_ action: @escaping (NSManagedObjectContext) -> Void) {
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
