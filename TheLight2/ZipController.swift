//
//  ZipController.swift
//  TheLight2
//
//  Created by Peter Balsamo on 10/24/17.
//  Copyright © 2017 Peter Balsamo. All rights reserved.
//

import UIKit
import Parse
import Firebase

class ZipController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    // MARK: NavigationController Hidden
    var lastContentOffset: CGFloat = 0.0
    
    let searchScope = ["city","zip","active"]
    //firebase
    var ziplist = [ZipModel]()
    var defaults = UserDefaults.standard
    //parse
    var _feedItems = NSMutableArray()
    var _feedheadItems = NSMutableArray()
    var filteredString = NSMutableArray()
    
    var isFormStat = false
    var pasteBoard = UIPasteboard.general
    
    var searchController: UISearchController!
    var resultsController: UITableViewController!
    var foundUsers:[String] = []
    
    lazy var titleButton: UIButton = {
        let button = UIButton()
        button.frame = CGRect.init(x: 0, y: 0, width: 100, height: 32)
        button.setTitle("Zip Codes", for: .normal)
        button.titleLabel?.font = Font.navlabel
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = Color.Table.navColor
        refreshControl.tintColor = .white
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: attributes)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.extendedLayoutIncludesOpaqueBars = true
        
        setupNavigationButtons()
        loadData()
        setupTableView()
        self.navigationItem.titleView = self.titleButton
        self.tableView!.addSubview(self.refreshControl)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        //TabBar Hidden
        self.tabBarController?.tabBar.isHidden = false
        
        // MARK: NavigationController Hidden
        NotificationCenter.default.addObserver(self, selector: #selector(AdController.hideBar(notification:)), name: NSNotification.Name("hide"), object: nil)
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = Color.Table.navColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        //TabBar Hidden
        self.tabBarController?.tabBar.isHidden = true
        //UIApplication.shared.isStatusBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func setupNavigationButtons() {
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newData))
        let searchBtn = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchButton))
        navigationItem.rightBarButtonItems = [addBtn,searchBtn]
    }
    
    func setupTableView() {
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 60
        self.tableView.backgroundColor = UIColor(white:0.90, alpha:1.0)
        self.tableView.tableFooterView = UIView(frame: .zero)
        // MARK: - TableHeader
        self.tableView?.register(HeaderViewCell.self, forCellReuseIdentifier: "Header")
        //self.automaticallyAdjustsScrollViewInsets = false //fix
        
        resultsController = UITableViewController(style: .plain)
        resultsController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserFoundCell")
        resultsController.tableView.dataSource = self
        resultsController.tableView.delegate = self
    }
    
    // MARK: - NavigationController Hidden
    
    @objc func hideBar(notification: NSNotification)  {
        let state = notification.object as! Bool
        self.navigationController?.setNavigationBarHidden(state, animated: true)
        UIView.animate(withDuration: 0.2, animations: {
            self.tabBarController?.hideTabBarAnimated(hide: state) //added
        }, completion: nil)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (self.lastContentOffset > scrollView.contentOffset.y) {
            NotificationCenter.default.post(name: NSNotification.Name("hide"), object: false)
        } else {
            NotificationCenter.default.post(name: NSNotification.Name("hide"), object: true)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.lastContentOffset = scrollView.contentOffset.y;
    }
    
    // MARK: - Refresh
    
    @objc func refreshData(_ sender: AnyObject) {
        ziplist.removeAll() //fix
        loadData()
        self.refreshControl.endRefreshing()
    }
    
    // MARK: - Button
    
    @objc func newData() {
        isFormStat = true
        self.performSegue(withIdentifier: "zipDetailSegue", sender: self)
    }
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == self.tableView {
            if (defaults.bool(forKey: "parsedataKey")) {
                return _feedItems.count
            } else {
                //firebase
                return ziplist.count
            }
        }
        return foundUsers.count
        //return filteredString.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cellIdentifier: String!
        
        if tableView == self.tableView {
            cellIdentifier = "Cell"
        } else{
            cellIdentifier = "UserFoundCell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! CustomTableCell
        cell.selectionStyle = .none
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            cell.ziptitleLabel!.font = Font.celltitle22m
        } else {
            cell.ziptitleLabel!.font = Font.celltitle20l
        }
        
        if (tableView == self.tableView) {
            
            if (defaults.bool(forKey: "parsedataKey")) {
                
                cell.ziptitleLabel!.text = String(format: "%@, %@", ((_feedItems[indexPath.row] as AnyObject).value(forKey: "City") as? String)!,
                                                     ((_feedItems[indexPath.row] as AnyObject).value(forKey: "State") as? String)!).removeWhiteSpace()
                //cell.ziptitleLabel!.text = (_feedItems[indexPath.row] as AnyObject).value(forKey: "City") as? String
            } else {
                //firebase
                cell.zippost = ziplist[indexPath.row]
            }
        } else {
            cell.ziptitleLabel!.text = (filteredString[indexPath.row] as AnyObject).value(forKey: "City") as? String
        }
        
        cell.customImagelabel.text = "Zip"
        cell.customImagelabel.tag = indexPath.row
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if UI_USER_INTERFACE_IDIOM() == .phone {
            return 85.0
        } else {
            return 0.0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if(section == 0) {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "Header") as? HeaderViewCell else { fatalError("Unexpected Index Path") }
            
            if (defaults.bool(forKey: "parsedataKey")) {
                cell.myLabel1.text = String(format: "%@%d", "Zip's\n", _feedItems.count)
                cell.myLabel2.text = String(format: "%@%d", "Active\n", _feedheadItems.count)
                cell.myLabel3.text = String(format: "%@%d", "Event\n", 0)
            } else {
                cell.myLabel1.text = String(format: "%@%d", "Zips\n", ziplist.count)
                cell.myLabel2.text = String(format: "%@%d", "Active\n", 0)
                cell.myLabel3.text = String(format: "%@%d", "Event\n", 0)
                
            }
            cell.separatorView1.backgroundColor = Color.Table.labelColor
            cell.separatorView2.backgroundColor = Color.Table.labelColor
            cell.separatorView3.backgroundColor = Color.Table.labelColor
            cell.contentView.backgroundColor = Color.Table.navColor
            self.tableView!.tableHeaderView = nil //cell.header
            
            return cell.contentView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0) // very light gray
        } else {
            cell.backgroundColor = UIColor.white
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            var deleteStr : String?
            if (defaults.bool(forKey: "parsedataKey")) {
                deleteStr = ((self._feedItems.object(at: indexPath.row) as AnyObject).value(forKey: "objectId") as? String)!
                _feedItems.removeObject(at: indexPath.row)
            } else {
                //firebase
                deleteStr = ziplist[indexPath.row].zipNo!
                self.ziplist.remove(at: indexPath.row)
            }
            self.deleteData(name: deleteStr!)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    // MARK: - Content Menu
    
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    private func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: AnyObject?) -> Bool {
        
        if (action == #selector(NSObject.copy)) {
            return true
        }
        return false
    }
    
    private func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: AnyObject?) {
        
        let cell = tableView.cellForRow(at: indexPath)
        pasteBoard.string = cell!.textLabel?.text
    }
    
    // MARK: - Parse
    
    func loadData() {
        
        if (defaults.bool(forKey: "parsedataKey")) {
            
            let query = PFQuery(className:"Zip")
            query.limit = 1000
            query.order(byAscending: "City")
            query.cachePolicy = .cacheThenNetwork
            query.findObjectsInBackground { objects, error in
                if error == nil {
                    let temp: NSArray = objects! as NSArray
                    self._feedItems = temp.mutableCopy() as! NSMutableArray
                    self.tableView!.reloadData()
                } else {
                    print("Error")
                }
            }
            /*
            let query1 = PFQuery(className:"Zip")
            query1.whereKey("Active", equalTo:"Active")
            query1.cachePolicy = .cacheThenNetwork
            query1.order(byDescending: "createdAt")
            query1.findObjectsInBackground { objects, error in
                if error == nil {
                    let temp: NSArray = objects! as NSArray
                    self._feedheadItems = temp.mutableCopy() as! NSMutableArray
                    self.tableView!.reloadData()
                } else {
                    print("Error")
                }
            } */
        } else {
            //firebase
            let ref = Database.database().reference().child("Zip")
            ref.observe(.childAdded , with:{ (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: Any] else {return}
                let zipTxt = ZipModel(dictionary: dictionary)
                self.ziplist.append(zipTxt)
                
                DispatchQueue.main.async(execute: {
                    self.tableView?.reloadData()
                })
            })
        }
    }
    
    func deleteData(name: String) {
        
        let alertController = UIAlertController(title: "Delete", message: "Confirm Delete", preferredStyle: .alert)
        let destroyAction = UIAlertAction(title: "Delete!", style: .destructive) { (action) in
            
            if (self.defaults.bool(forKey: "parsedataKey")) {
                
                let query = PFQuery(className:"Zip")
                query.whereKey("objectId", equalTo: name)
                query.findObjectsInBackground(block: { objects, error in
                    if error == nil {
                        for object in objects! {
                            object.deleteInBackground()
                        }
                    }
                })
            } else {
                //firebase
                Database.database().reference().child("Zip").child(name).removeValue(completionBlock: { (error, ref) in
                    if error != nil {
                        print("Failed to delete message:", error!)
                        return
                    }
                })
            }
            let successNotificationFeedbackGenerator = UINotificationFeedbackGenerator()
            successNotificationFeedbackGenerator.notificationOccurred(.success)
            self.refreshData(self)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.refreshData(self)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(destroyAction)
        self.present(alertController, animated: true) {
        }
    }
    
    // MARK: - Segues
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (tableView == self.tableView) {
            isFormStat = false
            self.performSegue(withIdentifier: "zipDetailSegue", sender: self)
        } else {
            //if tableView == resultsController.tableView {
            //userDetails = foundUsers[indexPath.row]
            //self.performSegueWithIdentifier("PushDetailsVC", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "zipDetailSegue" {
            
            let VC = (segue.destination as! UINavigationController).topViewController as! NewEditData
            VC.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            VC.navigationItem.leftItemsSupplementBackButton = true
            
            VC.formController = "Zip"
            if (isFormStat == true) {
                VC.formStatus = "New"
            } else {
                VC.formStatus = "Edit"
                let myIndexPath = self.tableView!.indexPathForSelectedRow!.row
                
                if (defaults.bool(forKey: "parsedataKey")) {
                    
                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .none
                    
                    var Zip = (_feedItems[myIndexPath] as AnyObject).value(forKey: "zipCode") as? String
                    if Zip == nil { Zip = "0" }
                    let myZip =  numberFormatter.number(from: Zip! as String)

                    VC.objectId = (_feedItems[myIndexPath] as AnyObject).value(forKey: "objectId") as? String
                    //VC.frm11 = (_feedItems[myIndexPath] as AnyObject).value(forKey: "Active") as? String
                    VC.frm12 = (_feedItems[myIndexPath] as AnyObject).value(forKey: "State") as? String
                    VC.frm13 = (_feedItems[myIndexPath] as AnyObject).value(forKey: "City") as? String
                    VC.frm14 = myZip as? Int
                    VC.frm15 = (_feedItems[myIndexPath] as AnyObject).value(forKey: "ZipNo") as? String
                } else {
                    //firebase
                    VC.objectId = ziplist[myIndexPath].zipId
                    VC.frm11 = ziplist[myIndexPath].active
                    VC.frm12 = ziplist[myIndexPath].state
                    VC.frm13 = ziplist[myIndexPath].city
                    VC.frm14 = Int(ziplist[myIndexPath].zip)
                    VC.frm15 = ziplist[myIndexPath].zipNo
                }
            }
        }
    }
    
}
//-----------------------end------------------------------

// MARK: - UISearchBar Delegate
extension ZipController: UISearchBarDelegate {
    
    @objc func searchButton(_ sender: AnyObject) {
        searchController = UISearchController(searchResultsController: resultsController)
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        searchController.searchBar.scopeButtonTitles = searchScope
        searchController.searchBar.barTintColor = Color.Table.navColor
        tableView!.tableFooterView = UIView(frame: .zero)
        self.present(searchController, animated: true)
    }
}

extension ZipController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
}
