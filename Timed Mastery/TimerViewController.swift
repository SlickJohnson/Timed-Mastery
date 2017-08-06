import UIKit

class TimerViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var secondsLabel: UILabel!
    
    @IBOutlet weak var playButton: MovableButton!
    @IBOutlet weak var saveButton: MovableButton!
    @IBOutlet weak var stopButton: MovableButton!
    
    @IBOutlet weak var skillName: RequiredTextField!
    
    var timer = Timer()
    var secCounter = 0.0
    var minCounter = 0
    var hrCounter = 0
    
    var isRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hourLabel.text = "\(String(format: "%02d", hrCounter))"
        minuteLabel.text = "\(String(format: "%02d", minCounter))"
        secondsLabel.text = "\(String(format: "%04.1f", secCounter))"
        
        skillName.frame.size.height = 44
        
        // Change button appearance
        
        saveButton.isEnabled = false
        stopButton.isEnabled = false
        
        // Play/Pause button
        var origImage = UIImage(named: "Circle_Play_Button_Filled-500px")
        var tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        playButton.setImage(tintedImage, for: .normal)
        playButton.tintColor = UIColor(red: 43/255, green: 62/255, blue: 81/255, alpha: 1.0)
        
        playButton.backgroundColor = .clear
        
        origImage = UIImage(named: "Pause-100")
        tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        playButton.setImage(tintedImage, for: .selected)
        
        // Stop button
        origImage = UIImage(named: "Cancel Filled-500")
        tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        stopButton.setImage(tintedImage, for: .normal)
        
        stopButton.tintColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1.0)
        stopButton.backgroundColor = .clear
        
        // Save button
        origImage = UIImage(named: "Plus Filled-500")
        tintedImage = origImage?.withRenderingMode(.alwaysTemplate)
        saveButton.setImage(tintedImage, for: .normal)
        
        saveButton.tintColor = UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0)
        saveButton.backgroundColor = .clear
        
        //        NotificationCenter.default.addObserver(self, selector: #selector(TimerViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(TimerViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.skillName.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func resetButton(_ sender: UIButton) {
        animateButton(animation: "stop")
        
        timer.invalidate()
        isRunning = false
        
        self.view.endEditing(true)
        
        let refreshAlert = UIAlertController(title: "Delete Skill?", message: "This will reset the timer.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action: UIAlertAction!) in
            self.animateButton(animation: "delete")
            self.skillName.text = ""
            
            self.hrCounter = 0
            self.minCounter = 0
            self.secCounter = 0.0
            
            self.hourLabel.text = "\(String(format: "%02d", self.hrCounter))"
            self.minuteLabel.text = "\(String(format: "%02d", self.minCounter))"
            self.secondsLabel.text = "\(String(format: "%04.1f", self.secCounter))"
            
            self.saveButton.isEnabled = false
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
            self.animateButton(animation: "reset")
        }))
        
        present(refreshAlert, animated: true, completion: nil)
    }
    
    @IBAction func playButton(_ sender: UIButton) {
        if !isRunning {
            animateButton(animation: "play")
            
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(TimerViewController.updateTimer), userInfo: nil, repeats: true)
            
            isRunning = true
        } else {
            animateButton(animation: "pause")
            
            saveButton.isEnabled = true
            
            timer.invalidate()
            isRunning = false
            self.view.endEditing(true)
        }
        self.view.endEditing(true)
    }
    
    @IBAction func saveButton(_ sender: UIButton) {
        
        if self.skillName.text! != "" {
            animateButton(animation: "save")
            let skill = Skill()
            
            skill.time = ((Double(self.minCounter)*3600) + Double(self.minCounter)*60) + self.secCounter;
            
            skill.name = self.skillName.text!
            
            self.skillName.text = ""
            
            skill.save()
            
            timer.invalidate()
            isRunning = false
            
            playButton.isEnabled = true
            
            
            self.hrCounter = 0
            self.minCounter = 0
            self.secCounter = 0.0
            
            self.hourLabel.text = "\(String(format: "%02d", self.hrCounter))"
            self.minuteLabel.text = "\(String(format: "%02d", self.minCounter))"
            self.secondsLabel.text = "\(String(format: "%04.1f", secCounter))"
            
            self.view.endEditing(true)
        } else {
            skillName.shake()
        }
        
    }
    
    func animateButton(animation: String) {
        switch animation {
            
        case "play":
            // Play -> Pause
            self.playButton.isSelected = true
            
            // Return button to normal size and return other buttons to orignal position
            saveButton.moveButton(fromValue: 0, toValue: 20)
            stopButton.moveButton(fromValue: 0, toValue: -20)
            playButton.scaleButton(fromValue: 1, toValue: 2)
            
            stopButton.isEnabled = false
            saveButton.isEnabled = false
            
        case "pause":
            // Pause -> Play
            self.playButton.isSelected = false
            
            saveButton.moveButton(fromValue: 20, toValue: 0)
            stopButton.moveButton(fromValue: -20, toValue: 0)
            playButton.scaleButton(fromValue: 2, toValue: 1, duration: 0.2)
            
            stopButton.isEnabled = true
            saveButton.isEnabled = true
            
        case "stop":
            self.playButton.isSelected = false
            
            saveButton.moveButton(fromValue: 0, toValue: 20)
            playButton.moveButton(fromValue: 0, toValue: 20)
            stopButton.scaleButton(fromValue: 1, toValue: 2)
            
        case "reset":
            saveButton.moveButton(fromValue: 20, toValue: 0)
            playButton.moveButton(fromValue: 20, toValue: 0)
            stopButton.scaleButton(fromValue: 2, toValue: 1, duration: 0.2)
            
        case "delete":
            saveButton.moveButton(fromValue: 20, toValue: 0)
            playButton.moveButton(fromValue: 20, toValue: 0)
            stopButton.scaleButton(fromValue: 4, toValue: 1)

        case "save":
            stopButton.moveButton(fromValue: -20, toValue: 0)
            playButton.moveButton(fromValue: -20, toValue: 0)
            saveButton.scaleButton(fromValue: 4, toValue: 1)
            
            saveButton.isEnabled = false
            stopButton.isEnabled = false
            
        default:
            print("ERROR: Not an animation")
        }
    }
    func updateTimer() {
        secCounter += 0.1
        
        if secCounter >= 60 {
            secCounter = 0.0
            minCounter += 1
        }
        
        if minCounter >= 60 {
            minCounter = 0
            hrCounter += 1
        }
        
        hourLabel.text = "\(String(format: "%02d", hrCounter))"
        minuteLabel.text = "\(String(format: "%02d", minCounter))"
        secondsLabel.text = "\(String(format: "%04.1f", secCounter))"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //    func keyboardWillShow(notification: NSNotification) {
    //        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
    //            if self.view.frame.origin.y == 0{
    //                self.view.frame.origin.y -= keyboardSize.height
    //            }
    //        }
    //    }
    //
    //    func keyboardWillHide(notification: NSNotification) {
    //        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
    //            if self.view.frame.origin.y != 0{
    //                self.view.frame.origin.y += keyboardSize.height
    //            }
    //        }
    //    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
