import UIKit
import Charts
import Foundation
import RealmSwift

class PerformanceViewController: UIViewController, UITextFieldDelegate{
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    @IBOutlet weak var tasksToQuery: UITextField!
    
    weak var axisFormatDelegate: IAxisValueFormatter?
    
    var uniqueTaskNames: Set<String> = Set<String>()
    
    let secondsInDay: Double = 24*60*60
    var todayInSeconds: TimeInterval = TimeInterval()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        axisFormatDelegate = self
        updateChart()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        self.tasksToQuery.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateChart()
    }
    
    public func updateChart() {
        todayInSeconds = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        lineChartView.noDataText = "You need to provide data for the chart, mate."
        lineChartView.chartDescription?.text = "1 Week History"
        
        var dataEntries: [ChartDataEntry] = []
        var chartDataSets: [LineChartDataSet] = []
        
        // check if user has searched for tasks
        if (tasksToQuery.text == "") {
            getAllTaskNames()
        } else {
            uniqueTaskNames = Set(tasksToQuery.text!.components(separatedBy: " "))
        }
        
        var i = 0
        
        // loops through all task names found in database -- i.e., 'running' 'jogging' 'programming'
        for uniqueTaskName in uniqueTaskNames {
            
            // gets all tasks with that name
            let matchingTasks = getTasksFromDatabase(taskName: uniqueTaskName)
            let uniqueTasks: List<Task> = List<Task>()
            var add = true
            
            // a non-repeating task list
            for matchingTask in matchingTasks {
                for uniqueTask in uniqueTasks {
                    if (Calendar.current.isDate(uniqueTask.date, inSameDayAs:matchingTask.date)) {
                        add = false
                    }
                }
                if (add) {uniqueTasks.append(matchingTask)}
            }
            
            // 1 week history
            for day in stride(from: todayInSeconds - secondsInDay*6, to: todayInSeconds + secondsInDay, by: secondsInDay) {
                var task: Task? = nil
                
                for uniqueTask in uniqueTasks {
                    if uniqueTask.timeIntervalOfDay == day {
                        task = uniqueTask
                    }
                }
                
                var dataEntry = ChartDataEntry()
                
                if (task == nil) {
                    dataEntry = ChartDataEntry(x: Double(day), y: 0.0)
                    
                } else {
                    dataEntry = ChartDataEntry(x: Double(day), y: task!.getAggregateTask().time)
                }
                dataEntries.append(dataEntry)
            }
            
            chartDataSets.append(LineChartDataSet(values: dataEntries, label: uniqueTaskName))
            
            
            // assign random pastel colors to the charts
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
        
        // chart beautification
        lineChartView.data = charData
        lineChartView.setScaleEnabled(false)
        
        lineChartView.legend.form = .circle
        lineChartView.legend.textColor = #colorLiteral(red: 0.1678812504, green: 0.2416117489, blue: 0.316118896, alpha: 1)
        
        lineChartView.rightAxis.enabled = false
        lineChartView.leftAxis.labelTextColor = #colorLiteral(red: 0.1678812504, green: 0.2416117489, blue: 0.316118896, alpha: 1)
        
        let limitLine = ChartLimitLine(limit: 10.0, label: "Target")
        lineChartView.rightAxis.addLimitLine(limitLine)
        limitLine.lineColor = UIColor(red: 255/255, green: 83/255, blue: 13/255, alpha: 1.0)
        
        lineChartView.xAxis.setLabelCount(4, force: true)
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.xAxis.avoidFirstLastClippingEnabled = true
        lineChartView.xAxis.labelTextColor = #colorLiteral(red: 0.1678812504, green: 0.2416117489, blue: 0.316118896, alpha: 1)
        
        lineChartView.animate(xAxisDuration: 1, yAxisDuration: 1, easingOption: .easeInOutBack)
        
        // format x and y values
        lineChartView.xAxis.valueFormatter = axisFormatDelegate
        lineChartView.leftAxis.valueFormatter = axisFormatDelegate
    }
    
    func getAllTaskNames() {
        do {
            let realm = try Realm()
            
            // non-repeating list of task names
            uniqueTaskNames = Set(realm.objects(Task.self).value(forKey: "name") as! [String])
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    func getTasksFromDatabase(taskName: String) -> Results<Task> {
        do {
            let realm = try Realm()
            
            // gets a month's worth of data
            return realm.objects(Task.self).filter("name == %@ && timeIntervalOfDay >= %@", taskName, Calendar.current.startOfDay(for: Date()).timeIntervalSince1970 - (24*60*60*30.44))
        } catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        updateChart()
        return false
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
