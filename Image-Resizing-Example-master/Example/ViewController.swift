import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    let dataList = ["Core Graphics", "CoreImage", "ImageIO", "UIKit", "vImage", "ImageIO1"]
    
    override func viewDidLoad() {
        self.navigationItem.title = "Resize"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.rowHeight = 60
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = self.dataList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let imageViewController = sb.instantiateViewController(withIdentifier: "ImageViewController")  as! ImageViewController
        imageViewController.resizeType = indexPath.row + 1
        self.navigationController?.pushViewController(imageViewController, animated: true)
    }
}
