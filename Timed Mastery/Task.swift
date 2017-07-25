import Foundation
import RealmSwift

public class Task: Object {
    dynamic var date: Date = Date()
    dynamic var timeIntervalOfDay: TimeInterval = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
    dynamic var time: Double = Double(0.0)
    dynamic var name: String = String("!NoName!")
    
    func setValsTo(date: Date, time: Double, name:String) {
        self.date = date
        self.time = time
        self.name = name
        self.timeIntervalOfDay = Calendar.current.startOfDay(for: date).timeIntervalSince1970
    }
    
    func save() {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(self)
            }
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    func getAggregateTask() -> Task {
        do {
            let realm = try Realm()
            let requestedTasks = realm.objects(Task.self).filter("name == %@ && timeIntervalOfDay >= %@", name, (timeIntervalOfDay - (24*60*60*30.44)))
    
            let tasksOnDay = List<Task>()
            
            for task in requestedTasks {
                if (Calendar.current.isDate(task.date, inSameDayAs: date))
                {
                    tasksOnDay.append(task)
                }
            }
            let aggregateTask = Task()
            aggregateTask.setValsTo(date: date, time: tasksOnDay.sum(ofProperty: "time"), name: name)
            
            return aggregateTask
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
}

