import UIKit
import RealmSwift

class DashboardViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var addTaskView: UIView!
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    @IBOutlet weak var addTaskButton: UIButton!
    
    var effect:UIVisualEffect!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    @IBOutlet weak var taskName: UITextField!
    
    @IBOutlet weak var timeSpentTodayLabel: UILabel!
    
    var tasks: Results<Task>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        effect = visualEffectView.effect
        visualEffectView.effect = nil

        addTaskView.layer.cornerRadius = 5
        addTaskButton.layer.cornerRadius = 5
    
        self.taskName.delegate = self
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

    
    @IBAction func addTask(_ sender: UIButton) {
        animateViewIn(targetView: addTaskView)
    }
    @IBAction func dismissAddTaskView(_ sender: UIButton) {
        let taskToAdd: Task = Task()
        taskToAdd.setValsTo(date: datePicker.date, time: timePicker.countDownDuration, name: taskName.text!)
        taskToAdd.save()
        animateViewOut(targetView: addTaskView)
    }
    
    @IBAction func cancelAddTask(_ sender: UIButton) {
        animateViewOut(targetView: addTaskView)
    }
    
    func getTimeSpentToday() -> Double {
        do {
            let realm = try Realm()
            let tasksToday = realm.objects(Task.self).filter("timeIntervalOfDay == %@", Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)
            // gets a month's worth of data
            return tasksToday.sum(ofProperty: "time")
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    func getTasksFromDatabase() -> Results<Task> {
        do {
            let realm = try Realm()
            
            // gets a month's worth of data
            return realm.objects(Task.self)
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
