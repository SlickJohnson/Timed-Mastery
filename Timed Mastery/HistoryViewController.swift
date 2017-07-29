import Foundation
import UIKit
import RealmSwift

class HistoryViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    // Tableview
    @IBOutlet weak var tableView: UITableView!
    var sectionNames: [String]!
    var rowDict: [String: [Task]] = [String : [Task]]()
    var currentRows: [String?]!
    
    // Editview
    @IBOutlet var editTaskView: UIView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var taskName: UITextField!
    var effect:UIVisualEffect!

    var isEditingTask: Bool!
    var editedTaskRef: Task?
    
    override func viewDidLoad() {
        tableView.rowHeight = UITableViewAutomaticDimension
        
        effect = visualEffectView.effect
        visualEffectView.effect = nil
        
        editTaskView.layer.cornerRadius = 5
        
        self.taskName.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadData()
        tableView.allowsSelectionDuringEditing = true
        tableView.isEditing = false
        isEditingTask = false
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
            defaultCell.taskLabel.text = "\(rowData)"
            defaultCell.totalTime.text = "\(formatTime(time:getTotalTaskTime(nameOfTask: rowData)))"
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
                
                let task = rowDict[rowData]?[cellIndex]
                let time = formatTime(time: task!.time)
                let date = formatDate(date: task!.timeIntervalOfDay)
                
                expansionCell.taskInformationLabel.text = "\(date) : \(time)"
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
                let cellTask = rowDict[sectionName]?[cellIndex]
                
                taskName.text? = cellTask!.name
                datePicker.date = cellTask!.date
                timePicker.countDownDuration = cellTask!.time
                
                animateViewIn(targetView: editTaskView)
                isEditingTask = true
                editedTaskRef = cellTask
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
                    let tasksToDelete = self.rowDict[sectionName!]
                    
                    if self.getNumberOfSubCells(parentIndex: indexPath.row) > 0 {
                        self.contractCell(tablewView: tableView, index: indexPath.row)
                    }
                    let realm = try! Realm()
                    try! realm.write {
                        for task in tasksToDelete! {
                            realm.delete(task)
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
                let cellTask = rowDict[sectionName]?[cellIndex]
                
                let realm = try! Realm()
                try! realm.write {
                    realm.delete(cellTask!)
                }
                rowDict[(currentRows?[parentCellIndex])!]?.remove(at: cellIndex)
                currentRows.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                // Remove seciton cell once all related tasks have been removed
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
    
    private func getData() -> [Task] {
        do {
            let realm = try Realm()
            
            // gets a month's worth of data
            return Array(realm.objects(Task.self))
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    private func getTasksByName(nameOfTasks: String) -> [Task] {
        do {
            let realm = try Realm()
            return Array(realm.objects(Task.self).filter("name == %@", nameOfTasks).sorted(byKeyPath: "date").reversed())
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
    
    private func getTotalTaskTime(nameOfTask: String) -> Double {
        do {
            let realm = try Realm()
            
            return realm.objects(Task.self).filter("name == %@", nameOfTask).sum(ofProperty: "time")
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    private func populateDict() {
        for taskName in sectionNames {
            rowDict[taskName] = getTasksByName(nameOfTasks: taskName)
        }
    }
    
    func getSectionNames() -> [String] {
        do {
            let realm = try Realm()
            
            // non-repeating list of task names
            return Array(Set(realm.objects(Task.self).value(forKey: "name") as! [String]).sorted())
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
        if let tasks = rowDict[(currentRows?[index]!)!] {
            for i in 1...tasks.count {
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
        if let tasks = rowDict[(currentRows?[index]!)!]  {
            for _ in 1...tasks.count {
                currentRows?.remove(at: index+1)
                tableView.deleteRows(at: [NSIndexPath(row: index + 1, section: 0) as IndexPath], with: .top)
            }
        }
    }
    
    //MARK: Edit Task view
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
    
    @IBAction func addTask(_ sender: UIButton) {
        animateViewIn(targetView: editTaskView)
    }
    
    @IBAction func confirmEditTaskView(_ sender: UIButton) {
        if isEditingTask {
            let realm = try! Realm()
            try! realm.write {
                editedTaskRef?.name = taskName.text!
                editedTaskRef?.date = datePicker.date
                editedTaskRef?.time = timePicker.countDownDuration
            }
            animateViewOut(targetView: editTaskView)
            loadData()
            isEditingTask = false
        }
        else {
            let taskToAdd: Task = Task()
            taskToAdd.setValsTo(date: datePicker.date, time: timePicker.countDownDuration, name: taskName.text!)
            taskToAdd.save()
            animateViewOut(targetView: editTaskView)
            loadData()
        }
    }
    
    @IBAction func cancelEditTaskView(_ sender: UIButton) {
        animateViewOut(targetView: editTaskView)
        isEditingTask = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}
