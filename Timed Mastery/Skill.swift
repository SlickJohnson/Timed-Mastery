import Foundation
import RealmSwift

public class Skill: Object {
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
    
    func getAggregateData() -> Skill {
        do {
            let realm = try Realm()
            let requestedSkills = realm.objects(Skill.self).filter("name == %@ && timeIntervalOfDay >= %@", name, (timeIntervalOfDay - (24*60*60*30.44)))
    
            let skillsOnDay = List<Skill>()
            
            for skill in requestedSkills {
                if (Calendar.current.isDate(skill.date, inSameDayAs: date))
                {
                    skillsOnDay.append(skill)
                }
            }
            let aggregateData = Skill()
            aggregateData.setValsTo(date: date, time: skillsOnDay.sum(ofProperty: "time"), name: name)
            
            return aggregateData
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
}

