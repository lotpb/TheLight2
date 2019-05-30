//
//  LookupData.swift
//  mySQLswift
//
//  Created by Peter Balsamo on 1/10/16.
//  Copyright © 2016 Peter Balsamo. All rights reserved.
//

import UIKit
import Parse
import Firebase

protocol LookupDataDelegate: class {
    func cityFromController(_ passedData: String)
    func stateFromController(_ passedData: String)
    func zipFromController(_ passedData: String)
    func salesFromController(_ passedData: String)
    func salesNameFromController(_ passedData: String)
    func jobFromController(_ passedData: String)
    func jobNameFromController(_ passedData: String)
    func productFromController(_ passedData: String)
    func productNameFromController(_ passedData: String)
}

class LookupData: UIViewController {
    
    weak var delegate:LookupDataDelegate?
    
    @IBOutlet weak var tableView: UITableView?
    
    //search
    private var searchController: UISearchController!
    private var resultsController: UITableViewController!
    private var filteredTitles = NSMutableArray()
    var lookupItem : String?
    var isFilltered = false
    //firebase
    var ziplist = [ZipModel]()
    var saleslist = [SalesModel]()
    var joblist = [JobModel]()
    var prodlist = [ProdModel]()
    var adlist = [AdModel]()
    var defaults = UserDefaults.standard
    //parse
    var zipArray = NSMutableArray()
    var salesArray = NSMutableArray()
    var jobArray = NSMutableArray()
    var adproductArray = NSMutableArray()

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = .clear
        refreshControl.tintColor = .black
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        setupTableView()
        navigationItem.title = String(format: "%@ %@", "Lookup", (self.lookupItem)!)
        //UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white, NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: 26)]
        self.navigationItem.largeTitleDisplayMode = .always
        
        // MARK: - New SearchBar
        searchController = UISearchController(searchResultsController: resultsController)
        searchController.searchResultsUpdater = self
        definesPresentationContext = true
        searchController.searchBar.barTintColor = Color.DGrayColor
        tableView!.tableFooterView = UIView(frame: .zero)
        if (defaults.bool(forKey: "parsedataKey")) {
            self.present(searchController, animated: true)
        }
        
        self.tableView!.addSubview(self.refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = Color.DGrayColor
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTableView() {
        self.tableView!.delegate = self
        self.tableView!.dataSource = self
        self.tableView!.backgroundColor = Color.LGrayColor
        
        resultsController = UITableViewController(style: .plain)
        resultsController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UserFoundCell")
        resultsController.tableView.sizeToFit()
        resultsController.tableView.clipsToBounds = true
        resultsController.tableView.dataSource = self
        resultsController.tableView.delegate = self
    }
    
    // MARK: - Refresh
    @objc func refreshData(sender:AnyObject) {
        loadData()
        self.refreshControl.endRefreshing()
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
                    self.zipArray = temp.mutableCopy() as! NSMutableArray
                    self.tableView!.reloadData()
                } else {
                    print("Error")
                }
            }
            
            let query1 = PFQuery(className:"Salesman")
            query1.limit = 1000
            query1.order(byAscending: "Salesman")
            query1.cachePolicy = .cacheThenNetwork
            query1.findObjectsInBackground { objects, error in
                if error == nil {
                    let temp: NSArray = objects! as NSArray
                    self.salesArray = temp.mutableCopy() as! NSMutableArray
                    self.tableView!.reloadData()
                } else {
                    print("Error")
                }
            }
            
            let query2 = PFQuery(className:"Job")
            query2.limit = 1000
            query2.order(byAscending: "Description")
            query2.cachePolicy = .cacheThenNetwork
            query2.findObjectsInBackground { objects, error in
                if error == nil {
                    let temp: NSArray = objects! as NSArray
                    self.jobArray = temp.mutableCopy() as! NSMutableArray
                    self.tableView!.reloadData()
                } else {
                    print("Error")
                }
            }
        } else {
            //firebase
            FirebaseRef.databaseRoot.child("Zip").observe(.childAdded , with:{ (snapshot) in
                guard let dictionary = snapshot.value as? [String: Any] else {return}
                let zipTxt = ZipModel(dictionary: dictionary)
                self.ziplist.append(zipTxt)
                
                DispatchQueue.main.async(execute: {
                    self.tableView?.reloadData()
                })
            })
            
            FirebaseRef.databaseRoot.child("Salesman").observe(.childAdded , with:{ (snapshot) in
                guard let dictionary = snapshot.value as? [String: Any] else {return}
                let salesTxt = SalesModel(dictionary: dictionary)
                self.saleslist.append(salesTxt)
                
                DispatchQueue.main.async(execute: {
                    self.tableView?.reloadData()
                })
            })
            
            FirebaseRef.databaseRoot.child("Job").observe(.childAdded , with:{ (snapshot) in
                guard let dictionary = snapshot.value as? [String: Any] else {return}
                let jobTxt = JobModel(dictionary: dictionary)
                self.joblist.append(jobTxt)
                
                DispatchQueue.main.async(execute: {
                    self.tableView?.reloadData()
                })
            })
        }
        
        if (lookupItem == "Product") {
            
            if (defaults.bool(forKey: "parsedataKey")) {
                
                let query3 = PFQuery(className:"Product")
                query3.limit = 1000
                query3.order(byDescending: "Products")
                query3.cachePolicy = .cacheThenNetwork
                query3.findObjectsInBackground { objects, error in
                    if error == nil {
                        let temp: NSArray = objects! as NSArray
                        self.adproductArray = temp.mutableCopy() as! NSMutableArray
                        self.tableView!.reloadData()
                    } else {
                        print("Error")
                    }
                }
            } else {
                //firebase
                FirebaseRef.databaseRoot.child("Product").observe(.childAdded , with:{ (snapshot) in
                    guard let dictionary = snapshot.value as? [String: Any] else {return}
                    let prodTxt = ProdModel(dictionary: dictionary)
                    self.prodlist.append(prodTxt)
                    
                    DispatchQueue.main.async(execute: {
                        self.tableView?.reloadData()
                    })
                })
            }
            
        } else {
            
            if (defaults.bool(forKey: "parsedataKey")) {
                
                let query4 = PFQuery(className:"Advertising")
                query4.limit = 1000
                query4.order(byDescending: "Advertiser")
                query4.cachePolicy = .cacheThenNetwork
                query4.findObjectsInBackground { objects, error in
                    if error == nil {
                        let temp: NSArray = objects! as NSArray
                        self.adproductArray = temp.mutableCopy() as! NSMutableArray
                        self.tableView!.reloadData()
                    } else {
                        print("Error")
                    }
                }
            } else {
                //firebase
                FirebaseRef.databaseRoot.child("Advertising").observe(.childAdded , with:{ (snapshot) in
                    guard let dictionary = snapshot.value as? [String: Any] else {return}
                    let adTxt = AdModel(dictionary: dictionary)
                    self.adlist.append(adTxt)
                    
                    DispatchQueue.main.async(execute: {
                        self.tableView?.reloadData()
                    })
                })
            }
        }
    }
    
    // MARK: - Segues
    func passDataBack() {
        let indexPath = (self.tableView!.indexPathForSelectedRow! as NSIndexPath).row
        if (!isFilltered) {
            if (lookupItem == "City") {
                
                if (defaults.bool(forKey: "parsedataKey")) {
                    self.delegate? .cityFromController(((zipArray.object(at: indexPath) as AnyObject).value(forKey: "City") as? String)!)
                    self.delegate? .stateFromController(((zipArray[indexPath] as AnyObject).value(forKey: "State") as? String)!)
                    self.delegate? .zipFromController(((zipArray[indexPath] as AnyObject).value(forKey: "zipCode") as? String)!)
                } else {
                    //firebase
                    self.delegate? .cityFromController(ziplist[indexPath].city)
                    self.delegate? .stateFromController(ziplist[indexPath].state)
                    self.delegate? .zipFromController(ziplist[indexPath].zip)
                }
                
            } else if (lookupItem == "Salesman") {
                
                if (defaults.bool(forKey: "parsedataKey")) {
                    self.delegate? .salesFromController(((salesArray.object(at: indexPath) as AnyObject).value(forKey: "SalesNo") as? String)!)
                    self.delegate? .salesNameFromController(((salesArray[indexPath] as AnyObject).value(forKey: "Salesman") as? String)!)
                } else {
                    //firebase
                    self.delegate? .salesFromController(saleslist[indexPath].salesNo!)
                    self.delegate? .salesNameFromController(saleslist[indexPath].salesman)
                }
                
            } else if (lookupItem == "Job") {
                
                if (defaults.bool(forKey: "parsedataKey")) {
                    self.delegate? .jobFromController(((jobArray[indexPath] as AnyObject).value(forKey: "JobNo") as? String)!)
                    self.delegate? .jobNameFromController(((jobArray.object(at: indexPath) as AnyObject).value(forKey: "Description") as? String)!)
                } else {
                    //firebase
                    self.delegate? .jobFromController(joblist[indexPath].jobNo!)
                    self.delegate? .jobNameFromController(joblist[indexPath].description)
                }
                
            } else if (lookupItem == "Product") {
                
                if (defaults.bool(forKey: "parsedataKey")) {
                    self.delegate? .productFromController(((adproductArray[indexPath] as AnyObject).value(forKey: "ProductNo") as? String)!)
                    self.delegate? .productNameFromController(((adproductArray[indexPath] as AnyObject).value(forKey: "Products") as? String)!)
                } else {
                    //firebase
                    self.delegate? .productFromController(prodlist[indexPath].productNo!)
                    self.delegate? .productNameFromController(prodlist[indexPath].products)
                }
            } else {
                
                if (defaults.bool(forKey: "parsedataKey")) {
                    self.delegate? .productFromController(((adproductArray[indexPath] as AnyObject).value(forKey: "AdNo") as? String)!)
                    self.delegate? .productNameFromController(((adproductArray[indexPath] as AnyObject).value(forKey: "Advertiser") as? String)!)
                } else {
                    //firebase
                    self.delegate? .productFromController(adlist[indexPath].adNo!)
                    self.delegate? .productNameFromController(adlist[indexPath].advertiser)
                }
            }
            
        } else {
            
            if (lookupItem == "City") {
                self.delegate? .cityFromController((((filteredTitles.object(at: indexPath) as! NSObject).value(forKey: "City") as? String)! as NSString) as String)
                self.delegate? .stateFromController((((filteredTitles[indexPath] as! NSObject).value(forKey: "State") as? String)! as NSString) as String)
                self.delegate? .zipFromController(((filteredTitles[indexPath] as! NSObject).value(forKey: "zipCode") as? String)!)
                
            } else if (lookupItem == "Salesman") {
                self.delegate? .salesFromController(((filteredTitles.object(at: indexPath) as AnyObject).value(forKey: "SalesNo") as? String)!)
                self.delegate? .salesNameFromController(((filteredTitles[indexPath] as AnyObject).value(forKey: "Salesman") as? String)!)
                
            } else if (lookupItem == "Job") {
                self.delegate? .jobFromController(((filteredTitles[indexPath] as AnyObject).value(forKey: "JobNo") as? String)!)
                self.delegate? .jobNameFromController(((filteredTitles.object(at: indexPath) as AnyObject).value(forKey: "Description") as? String)!)
                
            } else if (lookupItem == "Product") {
                self.delegate? .productFromController(((filteredTitles[indexPath] as AnyObject).value(forKey: "ProductNo") as? String)!)
                self.delegate? .productNameFromController(((filteredTitles[indexPath] as AnyObject).value(forKey: "Products") as? String)!)
            } else {
                self.delegate? .productFromController(((filteredTitles[indexPath] as AnyObject).value(forKey: "AdNo") as? String)!)
                self.delegate? .productNameFromController(((filteredTitles[indexPath] as AnyObject).value(forKey: "Advertiser") as? String)!)
            }
        }
        let _ = navigationController?.popViewController(animated: true)
    }
}
//-----------------------end------------------------------
extension LookupData: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (!isFilltered) {
            if (lookupItem == "City") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    zipArray.object(at: indexPath.row)
                } else {
                    //firebase
                    //ziplist(indexPath.row)
                }
            } else if (lookupItem == "Salesman") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    salesArray.object(at: indexPath.row)
                } else {
                    //firebase
                }
            } else if (lookupItem == "Job") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    jobArray.object(at: indexPath.row)
                } else {
                    //firebase
                }
            } else if (lookupItem == "Product") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    adproductArray.object(at: indexPath.row)
                } else {
                    //firebase
                }
            } else if (lookupItem == "Advertiser") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    adproductArray.object(at: indexPath.row)
                } else {
                    //firebase
                }
            }
        } else {
            filteredTitles.object(at: indexPath.row)
        }
        passDataBack()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            
            if (lookupItem == "City") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    return zipArray.count
                } else {
                    //firebase
                    return ziplist.count
                }
            } else if (lookupItem == "Salesman") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    return salesArray.count
                } else {
                    //firebase
                    return saleslist.count
                }
            } else if (lookupItem == "Job") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    return jobArray.count
                } else {
                    //firebase
                    return joblist.count
                }
            } else if (lookupItem == "Product") || (lookupItem == "Advertiser") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    return adproductArray.count
                } else {
                    //firebase
                    return adlist.count
                }
            }
        } else {
            //return foundUsers.count
            return filteredTitles.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cellIdentifier: String!
        
        if tableView == self.tableView {
            cellIdentifier = "Cell"
        } else {
            cellIdentifier = "UserFoundCell"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        cell.selectionStyle = .none
        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            cell.textLabel!.font = Font.celltitle20l
        } else {
            cell.textLabel!.font = Font.celltitle20l
        }
        
        if (tableView == self.tableView) {
            
            if (lookupItem == "City") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    cell.textLabel!.text = ((zipArray[indexPath.row] as AnyObject).value(forKey: "City") as? String)!
                } else {
                    //firebase
                    cell.textLabel!.text = ziplist[indexPath.row].city
                }
            } else if (lookupItem == "Salesman") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    cell.textLabel!.text = ((salesArray[indexPath.row] as AnyObject).value(forKey: "Salesman") as? String)!
                } else {
                    //firebase
                    cell.textLabel!.text = saleslist[indexPath.row].salesman
                }
            } else if (lookupItem == "Job") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    cell.textLabel!.text = ((jobArray[indexPath.row] as AnyObject).value(forKey: "Description") as? String)!
                } else {
                    //firebase
                    cell.textLabel!.text = joblist[indexPath.row].description
                }
            } else if (lookupItem == "Product") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    cell.textLabel!.text = ((adproductArray[indexPath.row] as AnyObject).value(forKey: "Products") as? String)!
                } else {
                    //firebase
                    cell.textLabel!.text = prodlist[indexPath.row].products
                }
            } else if (lookupItem == "Advertiser") {
                if (defaults.bool(forKey: "parsedataKey")) {
                    cell.textLabel!.text = ((adproductArray[indexPath.row] as AnyObject).value(forKey: "Advertiser") as? String)!
                } else {
                    //firebase
                    cell.textLabel!.text = adlist[indexPath.row].advertiser
                }
            }
        } else {
            if (lookupItem == "City") {
                //cell.textLabel!.text = foundUsers[indexPath.row]
                cell.textLabel!.text = ((filteredTitles[indexPath.row] as AnyObject).value(forKey: "City") as? String)!
            } else if (lookupItem == "Salesman") {
                cell.textLabel!.text = ((filteredTitles[indexPath.row] as AnyObject).value(forKey: "Salesman") as? String)!
            } else if (lookupItem == "Job") {
                cell.textLabel!.text = ((filteredTitles[indexPath.row] as AnyObject).value(forKey: "Description") as? String)!
            } else if (lookupItem == "Product") {
                cell.textLabel!.text = ((filteredTitles[indexPath.row] as AnyObject).value(forKey: "Products") as? String)!
            } else if (lookupItem == "Advertiser") {
                cell.textLabel!.text = ((filteredTitles[indexPath.row] as AnyObject).value(forKey: "Advertiser") as? String)!
            }
        }
        //cell.textLabel!.text = cityName
        return cell
    }
}

extension LookupData: UITableViewDelegate {
    
}

extension LookupData: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        if text.isEmpty {
            //filteredTitles = leadlist.
        } else {
            //filteredTitles = leadlist.filter { $0.contains(text) }
        }
        tableView?.reloadData()
    }
}




