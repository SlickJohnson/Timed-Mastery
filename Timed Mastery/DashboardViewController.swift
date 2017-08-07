import UIKit
import RealmSwift

class DashboardViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var addSkillView: UIView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    @IBOutlet weak var skillName: UITextField!
    
    @IBOutlet weak var timeSpentTodayLabel: UILabel!
    
    var skills: Results<Skill>?
    var topThreeSkills: [Skill]?
    
    @IBOutlet weak var firstSkillTime: UILabel!
    @IBOutlet weak var secondSkillTime: UILabel!
    @IBOutlet weak var thirdSkillTime: UILabel!
    
    @IBOutlet weak var firstSkillName: UILabel!
    @IBOutlet weak var secondSkillName: UILabel!
    @IBOutlet weak var thirdSkillName: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.skillName.delegate = self
        updateTimeSpentTodayLabel()
        updateTopThreeLables()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateTimeSpentTodayLabel()
        updateTopThreeLables()
    }
    
    func updateTimeSpentTodayLabel() {
        let timeSpentToday: Double = getTimeSpentToday()
        
        switch (timeSpentToday) {
        case 0..<3600:
            timeSpentTodayLabel.text = String(format:"Time spent today: %.1f minutes", timeSpentToday/60)
        default:
            timeSpentTodayLabel.text = String(format:"Time spent today: %.1f hours", timeSpentToday/3600)
        }
    }
    
    func animateViewIn(targetView: UIView) {
        self.view.addSubview(targetView)
        targetView.center = self.view.center
        
        targetView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        targetView.alpha = 0
        
        UIView.animate(withDuration: 0.4) {
            targetView.alpha = 1
            targetView.transform = CGAffineTransform.identity
        }
    }
    
    func animateViewOut(targetView: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            targetView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            targetView.alpha = 0
            
        }) { (success: Bool) in
            targetView.removeFromSuperview()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func addSkill(_ sender: UIButton) {
        animateViewIn(targetView: addSkillView)
    }
    @IBAction func dismissAddSkillView(_ sender: UIButton) {
        let skillToAdd: Skill = Skill()
        skillToAdd.setValsTo(date: datePicker.date, time: timePicker.countDownDuration, name: skillName.text!)
        skillToAdd.save()
        animateViewOut(targetView: addSkillView)
    }
    
    @IBAction func cancelAddSkill(_ sender: UIButton) {
        animateViewOut(targetView: addSkillView)
    }
    
    func getTimeSpentToday() -> Double {
        do {
            let realm = try Realm()
            let skillsToday = realm.objects(Skill.self).filter("timeIntervalOfDay == %@", Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)
            // gets a month's worth of data
            return skillsToday.sum(ofProperty: "time")
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    func getSkillsFromDatabase() -> Results<Skill> {
        do {
            let realm = try Realm()
            
            // gets a month's worth of data
            return realm.objects(Skill.self).sorted(byKeyPath: "time", ascending: false)
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    func getUniqueSkillsFromDatabase() -> List<Skill> {
        
        let allSkills = getSkillsFromDatabase()
        let uniqueSkills = List<Skill>()
        
        print("allSkills \(allSkills)")
        
        // create a non-repeating (date) list of skills
        for skill in allSkills {
            var add = true
            
            for uniqueSkill in uniqueSkills {
                if (uniqueSkill.name == skill.name) {
                    add = false
                }
            }
            
            if (add) {uniqueSkills.append(skill)}
        }
        print("uniqueSkills \(uniqueSkills)")
        return uniqueSkills
    }
    
    func getTopThreeSkills() -> [Skill] {
        let skills = getUniqueSkillsFromDatabase()
        var topThree = Set<Skill>()
        
        if !skills.isEmpty {
            for i in 0..<(0 ... skills.count).clamp(3) {
                let skill = skills[i].getAggregateData()
                topThree.insert(skill)
            }
        }
        
        return Array(topThree.sorted {
            return $0.time > $1.time
        })
        
    }
    
    func updateTopThreeLables() {
        topThreeSkills = getTopThreeSkills()
        
        firstSkillTime.text = "0"
        firstSkillName.text = "N/A"
        
        secondSkillTime.text = "0"
        secondSkillName.text = "N/A"
        
        thirdSkillTime.text = "0"
        thirdSkillName.text = "N/A"
        
        if !(topThreeSkills?.isEmpty)! {
            var i = 0
            for skill in topThreeSkills! {
                switch i {
                case 0:
                    firstSkillTime.text = formatTime(time: skill.time)
                    firstSkillName.text = skill.name
                case 1:
                    secondSkillTime.text = formatTime(time: skill.time)
                    secondSkillName.text = skill.name
                case 2:
                    thirdSkillTime.text = formatTime(time: skill.time)
                    thirdSkillName.text = skill.name
                default:
                    print("ERROROROOROROR")
                }
                
                i += 1
            }
        }
    }
    
    func formatTime(time: Double) -> String {
        if time < 59 {
            return String(format:"%.0f Sec", time)
        } else if time < 3599 {
            return String(format:"%.0f Min", time/60)
        } else {
            return String(format:"%.2f Hrs", time/3600)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}
