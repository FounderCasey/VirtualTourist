//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Casey Wilcox on 1/23/17.
//  Copyright © 2017 Casey Wilcox. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Data")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let error = error as NSError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func autoSave(delay: Int) {
        if delay > 0 {
            saveContext()
            let time = DispatchTime.now() + .seconds(delay)
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.autoSave(delay: delay)
            }
        }
    }
    
    class func sharedInstace() -> CoreDataStack {
        struct Singleton {
            static var sharedInstance = CoreDataStack()
        }
        return Singleton.sharedInstance
    }
}
