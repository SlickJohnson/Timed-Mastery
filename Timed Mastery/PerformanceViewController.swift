import UIKit
import Charts
import Foundation
import RealmSwift

class PerformanceViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate{
    
    // chartView vars
    @IBOutlet weak var lineChartView: LineChartView!
    
    @IBOutlet weak var textField: UITextField!
    
    weak var axisFormatDelegate: IAxisValueFormatter?
    
    var uniqueSkillNames: Set<String> = Set<String>()
    
    let secondsInDay: Double = 24*60*60
    var todayInSeconds: TimeInterval = TimeInterval()
    
    // tableview vars (drop down list)
    var dropDownListVals: [String]!
    let cellReuseIdentifier = "cell"
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: chartView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        textField.delegate = self
        axisFormatDelegate = self
        
        tableView.isHidden = true
        tableView.layer.cornerRadius = 5
        
        textField.addTarget(self, action: #selector(textFieldActive), for: UIControlEvents.touchDown)
        
        updateChart()
        updateDropDownList()
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateChart()
        updateDropDownList()
    }
    
    public func updateChart() {
        todayInSeconds = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        lineChartView.noDataText = "You need to provide data for the chart, mate."
        lineChartView.chartDescription?.text = "1 Week History"
        
        var dataEntries: [ChartDataEntry] = []
        var chartDataSets: [LineChartDataSet] = []
        
        // check if user has searched for skills
        if textField.text == "" {
            uniqueSkillNames = getAllSkillNames()
        } else {
            uniqueSkillNames = Set(textField.text!.components(separatedBy: "+"))
        }
        
        var i = 0
        
        // loop through all skill names found in database -- i.e., 'running' 'jogging' 'programming'
        for uniqueSkillName in uniqueSkillNames {
            
            // get all skills with matching name
            let matchingSkills = getSkillsFromDatabase(skillName: uniqueSkillName)
            let uniqueSkills: List<Skill> = List<Skill>()
            var add = true
            
            // create a non-repeating (date) list of skills
            for matchingSkill in matchingSkills {
                for uniqueSkill in uniqueSkills {
                    if (Calendar.current.isDate(uniqueSkill.date, inSameDayAs:matchingSkill.date)) {
                        add = false
                    }
                }
                if (add) {uniqueSkills.append(matchingSkill)}
            }
            
            // add data points to show 1 week history
            for day in stride(from: todayInSeconds - secondsInDay*6, to: todayInSeconds + secondsInDay, by: secondsInDay) {
                var skill: Skill? = nil
                
                for uniqueSkill in uniqueSkills {
                    if uniqueSkill.timeIntervalOfDay == day {
                        skill = uniqueSkill
                    }
                }
                
                var dataEntry = ChartDataEntry()
                
                if (skill == nil) {
                    // no data for this date so Y value is set to 0
                    dataEntry = ChartDataEntry(x: Double(day), y: 0.0)
                } else {
                    dataEntry = ChartDataEntry(x: Double(day), y: skill!.getAggregateData().time)
                }
                
                dataEntries.append(dataEntry)
            }
            
            chartDataSets.append(LineChartDataSet(values: dataEntries, label: uniqueSkillName))
            
            // give each chart a random pastel color
            let chartDataSetColor = UIColor(hue: 3.6 * CGFloat(Float(arc4random()) / Float(UINT32_MAX)), saturation: CGFloat(0.45 + 0.10 * Float(arc4random()) / Float(UINT32_MAX)), brightness: CGFloat(0.73 + 0.10 * Float(arc4random()) / Float(UINT32_MAX)), alpha: 1.0)
            
            chartDataSets[i].colors = [chartDataSetColor]
            chartDataSets[i].highlightColor = chartDataSetColor
            chartDataSets[i].circleColors = [chartDataSetColor]
            chartDataSets[i].valueColors = [chartDataSetColor]
            
            chartDataSets[i].drawCircleHoleEnabled = false
            chartDataSets[i].lineWidth = 3
            
            dataEntries.removeAll()
            i += 1
        }
        let charData = LineChartData(dataSets: chartDataSets)
        
        // customize chart view
        lineChartView.data = charData
        lineChartView.setScaleEnabled(false)
        
        lineChartView.legend.form = .circle
        lineChartView.legend.textColor = #colorLiteral(red: 0.1678812504, green: 0.2416117489, blue: 0.316118896, alpha: 1)
        
        lineChartView.rightAxis.enabled = false
        lineChartView.leftAxis.labelTextColor = #colorLiteral(red: 0.1678812504, green: 0.2416117489, blue: 0.316118896, alpha: 1)
        
        let limitLine = ChartLimitLine(limit: 10.0, label: "Target") // Temporary. Must be moved ASAP
        lineChartView.rightAxis.addLimitLine(limitLine)
        limitLine.lineColor = UIColor(red: 255/255, green: 83/255, blue: 13/255, alpha: 1.0)
        
        lineChartView.xAxis.setLabelCount(4, force: true)
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.xAxis.avoidFirstLastClippingEnabled = true
        lineChartView.xAxis.labelTextColor = #colorLiteral(red: 0.1678812504, green: 0.2416117489, blue: 0.316118896, alpha: 1)
        
        lineChartView.animate(xAxisDuration: 1, yAxisDuration: 1, easingOption: .easeInOutBack)
        
        // format all values
        lineChartView.xAxis.valueFormatter = axisFormatDelegate
        lineChartView.leftAxis.valueFormatter = axisFormatDelegate
    }
    
    func getAllSkillNames() -> Set<String> {
        do {
            let realm = try Realm()
            
            // non-repeating list of skill names
            return Set((realm.objects(Skill.self).value(forKey: "name") as! [String]).sorted())
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    func getSkillsFromDatabase(skillName: String) -> Results<Skill> {
        do {
            let realm = try Realm()
            
            // get a month's worth of data
            return realm.objects(Skill.self).filter("name == %@ && timeIntervalOfDay >= %@", skillName, Calendar.current.startOfDay(for: Date()).timeIntervalSince1970 - (24*60*60*30.44))
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    // MARK: dropDownList
    
    @IBAction func textFieldChanged(_ sender: AnyObject) {
        tableView.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        heightConstraint.constant = tableView.contentSize.height
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // manage keyboard and tableView visibility
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch:UITouch = touches.first else {
            return;
        }
        if touch.view != tableView
        {
            textField.endEditing(true)
            tableView.isHidden = true
        }
    }
    
    // toggle the tableView visibility when click on textField
    func textFieldActive() {
        tableView.isHidden = !tableView.isHidden
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateChart()
        updateDropDownList()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dropDownListVals.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell!
        
        cell.textLabel?.text = dropDownListVals[indexPath.row]
        cell.textLabel?.font = textField.font
        
        cell.layer.backgroundColor = UIColor.clear.cgColor
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        textField.text = textField.text != "" ? "\(textField.text!)+\(dropDownListVals[indexPath.row])" : dropDownListVals[indexPath.row]
        updateDropDownList()
        tableView.isHidden = true
        textField.endEditing(true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func updateDropDownList() {
        dropDownListVals = Array(getAllSkillNames())
        let skillNamesInSearchBar = textField.text?.components(separatedBy: "+")
        
        for skillName in dropDownListVals {
            if skillNamesInSearchBar!.contains(skillName) {
                dropDownListVals.remove(at: dropDownListVals.index(of: skillName)!)
            }
        }
        tableView.reloadData()
    }
}

// MARK: axisFormatDelegate
extension PerformanceViewController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        
        if axis is XAxis {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale (identifier: "en_US")
            dateFormatter.setLocalizedDateFormatFromTemplate("Ed")
            
            if (value == todayInSeconds) {
                return "Today"
            }
            
            return dateFormatter.string(from: Date(timeIntervalSince1970: value))
        }
        
        if axis is YAxis {
            if value < 59 {
                return String(format:"%.0fs", value)
            } else if value < 3599 {
                return String(format:"%.0fm", value/60)
            } else {
                return String(format:"%.2fh", value/3600)
            }
        }
        return ""
    }
    
}
