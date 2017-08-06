import UIKit
import RealmSwift

class DashboardViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var addSkillView: UIView!
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    @IBOutlet weak var addSkillButton: UIButton!
    
    var effect:UIVisualEffect!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    @IBOutlet weak var skillName: UITextField!
    
    @IBOutlet weak var timeSpentTodayLabel: UILabel!
    
    var skills: Results<Skill>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        effect = visualEffectView.effect
        visualEffectView.effect = nil

        addSkillView.layer.cornerRadius = 5
        addSkillButton.layer.cornerRadius = 5
    
        self.skillName.delegate = self
        updateTimeSpentTodayLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateTimeSpentTodayLabel()
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
            self.visualEffectView.effect = self.effect
            targetView.alpha = 1
            targetView.transform = CGAffineTransform.identity
        }
    }
    
    func animateViewOut(targetView: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            targetView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            targetView.alpha = 0
            
            self.visualEffectView.effect = nil
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
            return realm.objects(Skill.self)
        } catch let error as NSError {
            fatalError(error.localizedDescription)
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
