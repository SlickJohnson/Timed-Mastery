import Foundation
import UIKit
import RealmSwift

class HistoryViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // Tableview
    @IBOutlet weak var tableView: UITableView!
    var sectionNames: [String]!
    var rowDict: [String: [Skill]] = [String : [Skill]]()
    var currentRows: [String?]!
    
    // Editview
    @IBOutlet var editSkillView: UIView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var skillName: RequiredTextField!
    var effect:UIVisualEffect!
    
    var isEditingSkill: Bool!
    var editedSkillRef: Skill?
    
    override func viewDidLoad() {
        tableView.rowHeight = UITableViewAutomaticDimension
        
        effect = visualEffectView.effect
        visualEffectView.effect = nil
        
        editSkillView.layer.cornerRadius = 5
        
        self.skillName.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadData()
        tableView.allowsSelectionDuringEditing = true
        tableView.isEditing = false
        isEditingSkill = false
        visualEffectView.isUserInteractionEnabled = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentRows != nil {
            return (currentRows?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Row is DefaultCell
        if let rowData = currentRows?[indexPath.row] {
            let defaultCell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath) as! DefaultCell
            defaultCell.skillLabel.text = "\(rowData)"
            defaultCell.totalTime.text = "\(formatTime(time:getTotalSkillTime(nameOfSkill: rowData)))"
            defaultCell.selectionStyle = .none
            return defaultCell
        }
            // Row is ExpansionCell
        else {
            if let rowData = currentRows?[getParentCellIndex(expansionIndex: indexPath.row)] {
                
                // Create an ExpansionCell
                let expansionCell = tableView.dequeueReusableCell(withIdentifier: "ExpansionCell", for: indexPath) as! ExpansionCell
                // Set the cell's data
                let cellIndex = indexPath.row - getParentCellIndex(expansionIndex: indexPath.row) - 1
                
                let skill = rowDict[rowData]?[cellIndex]
                let time = formatTime(time: skill!.time)
                let date = formatDate(date: skill!.timeIntervalOfDay)
                
                expansionCell.skillDataLabel.text = "\(date) : \(time)"
                expansionCell.selectionStyle = .none
                return expansionCell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (currentRows?[indexPath.row]) != nil {
            return 65
        } else {
            return 50
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (currentRows?[indexPath.row]) != nil {
            // If user clicked last cell, do not try to access cell+1 (out of range)
            if (indexPath.row + 1 >= (currentRows?.count)!) {
                expandCell(tableView: tableView, index: indexPath.row)
            }
            else {
                // If next cell is not nil, then cell is not expanded
                if (currentRows?[indexPath.row + 1] != nil) {
                    expandCell(tableView: tableView, index: indexPath.row)
                    // Close Cell (remove ExpansionCells)
                } else {
                    contractCell(tablewView: tableView, index: indexPath.row)
                }
            }
        }
            // expansion cell was tapped
        else {
            if tableView.isEditing {
                let parentCellIndex = getParentCellIndex(expansionIndex: indexPath.row)
                let sectionName = currentRows[parentCellIndex]!
                
                let cellIndex = indexPath.row - getParentCellIndex(expansionIndex: indexPath.row) - 1
                let cellSkill = rowDict[sectionName]?[cellIndex]
                
                skillName.text? = cellSkill!.name
                datePicker.date = cellSkill!.date
                timePicker.countDownDuration = cellSkill!.time
                
                animateViewIn(targetView: editSkillView)
                isEditingSkill = true
                editedSkillRef = cellSkill
            }
        }
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if (currentRows?[indexPath.row]) != nil {
                // Delete seciton cells
                let refreshAlert = UIAlertController(title: "Are you sure you want to delete \((currentRows?[indexPath.row])!) and all its data?", message: "This is irreversible (unless you have awesome memory!)", preferredStyle: UIAlertControllerStyle.alert)
                
                refreshAlert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action: UIAlertAction!) in
                    
                    let sectionName = self.currentRows[indexPath.row]
                    let skillsToDelete = self.rowDict[sectionName!]
                    
                    if self.getNumberOfSubCells(parentIndex: indexPath.row) > 0 {
                        self.contractCell(tablewView: tableView, index: indexPath.row)
                    }
                    let realm = try! Realm()
                    try! realm.write {
                        for skill in skillsToDelete! {
                            realm.delete(skill)
                        }
                    }
                    self.rowDict[sectionName!] = nil
                    self.currentRows.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .middle)
                    self.sectionNames.remove(at: indexPath.row)
                }))
                
                refreshAlert.addAction(UIAlertAction(title: "NO!", style: .default, handler: { (action: UIAlertAction!) in
                    //                    self.animateButton(animation: "reset")
                }))
                
                present(refreshAlert, animated: true, completion: nil)
            }
            else {
                // Delete expansion cells
                let parentCellIndex = getParentCellIndex(expansionIndex: indexPath.row)
                let sectionName = currentRows[parentCellIndex]!
                
                let cellIndex = indexPath.row - getParentCellIndex(expansionIndex: indexPath.row) - 1
                let cellSkill = rowDict[sectionName]?[cellIndex]
                
                let realm = try! Realm()
                try! realm.write {
                    realm.delete(cellSkill!)
                }
                rowDict[(currentRows?[parentCellIndex])!]?.remove(at: cellIndex)
                currentRows.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                // Remove seciton cell once all related skills have been removed
                if getNumberOfSubCells(parentIndex: parentCellIndex) == 0 {
                    currentRows.remove(at: parentCellIndex)
                    sectionNames.remove(at: sectionNames.index(of: sectionName)!)
                    tableView.deleteRows(at: [NSIndexPath(row: parentCellIndex, section: 0) as IndexPath], with: .middle)
                }
            }
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    private func loadData() {
        sectionNames = getSectionNames()
        populateDict()
        currentRows = sectionNames
        tableView.reloadData()
    }
    
    private func getData() -> [Skill] {
        do {
            let realm = try Realm()
            
            // gets a month's worth of data
            return Array(realm.objects(Skill.self))
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    private func getSkillsByName(nameOfSkills: String) -> [Skill] {
        do {
            let realm = try Realm()
            return Array(realm.objects(Skill.self).filter("name == %@", nameOfSkills).sorted(byKeyPath: "date").reversed())
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    private func getNumberOfSubCells(parentIndex: Int) -> Int{
        var parentCell: String?
        var selectedIndex = parentIndex
        var numberOfSubCells = 0
        
        while (parentCell == nil && selectedIndex < currentRows!.count - 1) {
            selectedIndex += 1
            parentCell = currentRows?[selectedIndex]
            if (parentCell != nil) {
                return numberOfSubCells
            }
            numberOfSubCells += 1
        }
        
        return numberOfSubCells
    }
    
    private func getTotalSkillTime(nameOfSkill: String) -> Double {
        do {
            let realm = try Realm()
            
            return realm.objects(Skill.self).filter("name == %@", nameOfSkill).sum(ofProperty: "time")
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    private func populateDict() {
        for skillName in sectionNames {
            rowDict[skillName] = getSkillsByName(nameOfSkills: skillName)
        }
    }
    
    func getSectionNames() -> [String] {
        do {
            let realm = try Realm()
            
            // non-repeating list of skill names
            return Array(Set(realm.objects(Skill.self).value(forKey: "name") as! [String]).sorted())
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    private func formatTime(time: Double) -> String {
        if time < 59 {
            return String(format:"%.0f Sec.", time)
        } else if time < 3599 {
            return String(format:"%.0f Min.", time/60)
        } else {
            return String(format:"%.2f Hrs.", time/3600)
        }
    }
    
    private func formatDate(date: TimeInterval) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale (identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("EdMMMyyy")
        //        if (value == Calendar.current.startOfDay(for: Date()).timeIntervalSince1970 {
        //            return "Today"
        //        }
        return dateFormatter.string(from: Date(timeIntervalSince1970: date))
    }
    
    private func getParentCellIndex(expansionIndex: Int) -> Int{
        
        var selectedCell: String?
        var selectedIndex = expansionIndex
        
        while (selectedCell == nil && selectedIndex >= 0) {
            selectedIndex -= 1
            selectedCell = currentRows?[selectedIndex]
        }
        
        return selectedIndex
    }
    
    private func expandCell(tableView: UITableView, index: Int) {
        
        // Expand Cell (add ExpansionCells)
        if let skills = rowDict[(currentRows?[index]!)!] {
            for i in 1...skills.count {
                currentRows?.insert(nil, at: index + i)
                tableView.insertRows(at: [NSIndexPath(row: index + i, section:  0) as IndexPath], with: .top)
            }
        }
    }
    @IBAction func editMode(_ sender: UIButton) {
        tableView.isEditing = !tableView.isEditing
    }
    
    
    private func contractCell(tablewView: UITableView, index: Int) {
        // Contract Cell (remove ExpansionCells)
        if let skills = rowDict[(currentRows?[index]!)!]  {
            for _ in 1...skills.count {
                currentRows?.remove(at: index+1)
                tableView.deleteRows(at: [NSIndexPath(row: index + 1, section: 0) as IndexPath], with: .top)
            }
        }
    }
    
    //MARK: Edit Skill view
    func animateViewIn(targetView: UIView) {
        visualEffectView.isUserInteractionEnabled = true
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
        visualEffectView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.3, animations: {
            targetView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            targetView.alpha = 0
            
            self.visualEffectView.effect = nil
        }) { (success: Bool) in
            targetView.removeFromSuperview()
        }
    }
    
    @IBAction func addSkill(_ sender: UIButton) {
        animateViewIn(targetView: editSkillView)
    }
    
    @IBAction func confirmEditSkillView(_ sender: UIButton) {
        // Edit existing skill
        if isEditingSkill {
            if skillName.text != "" {
            let realm = try! Realm()
            try! realm.write {
                editedSkillRef?.name = skillName.text!
                editedSkillRef?.date = datePicker.date
                editedSkillRef?.time = timePicker.countDownDuration
            }
            animateViewOut(targetView: editSkillView)
            loadData()
            isEditingSkill = false
            } else {
                skillName.shake()
            }
        }
        // Add new skill
        else {
            if skillName.text != "" {
                let skillToAdd: Skill = Skill()
                skillToAdd.setValsTo(date: datePicker.date, time: timePicker.countDownDuration, name: skillName.text!)
                skillToAdd.save()
                animateViewOut(targetView: editSkillView)
                loadData()
            } else {
                skillName.shake()
            }
        }
    }
    
    @IBAction func cancelEditSkillView(_ sender: UIButton) {
        animateViewOut(targetView: editSkillView)
        isEditingSkill = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
