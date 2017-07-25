import Foundation
import UIKit
import RealmSwift

class DataBaseViewController: UITableViewController {
    
    var sectionNames: [String]!
    var rowDict: [String: [Task]] = [String : [Task]]()
    var currentRows: [String?]!
    var expansionCellCounter = 0
    
    override func viewDidLoad() {
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewDidAppear(_ animated: Bool) {
        sectionNames = getSectionNames()
        populateDict()
        currentRows = sectionNames
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentRows != nil {
            return (currentRows?.count)!
        } else {
            return 0
        }
    }
 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (currentRows?[indexPath.row]) != nil {
            return 65
        } else {
            return 50
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        
        else {
            
        }
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
    
    private func expandCell(tableView: UITableView, index: Int) {
        expansionCellCounter = 0
        // Expand Cell (add ExpansionCells)
        if let tasks = rowDict[(currentRows?[index]!)!] {
            for i in 1...tasks.count {
                currentRows?.insert(nil, at: index + i)
                tableView.insertRows(at: [NSIndexPath(row: index + i, section:  0) as IndexPath], with: .top)
            }
        }
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
    
}
