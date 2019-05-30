//
//  StatisticController.swift
//  mySQLswift
//
//  Created by Peter Balsamo on 1/10/16.
//  Copyright © 2016 Peter Balsamo. All rights reserved.
//

import UIKit
import Parse

class StatisticVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UISplitViewControllerDelegate {

    @IBOutlet weak var scrollWall: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    // MARK: NavigationController Hidden
    var lastContentOffset: CGFloat = 0.0
    
    private var searchController: UISearchController!
    private var resultsController: UITableViewController!
    private var filteredTitles = [String]()

    var _feedCustItems = NSMutableArray()
    var _feedLeadItems = NSMutableArray()
    
    var segmentedControl : UISegmentedControl!
    let defaults = UserDefaults.standard
    
    var dayYQL: NSArray!
    var textYQL: NSArray!
    
    var symYQL: NSArray!
    var tradeYQL: NSArray!
    var changeYQL: NSArray!

    var label1 : UILabel!
    var label2 : UILabel!
    var myLabel3 : UILabel!
    
    var tempYQL: String!
    var weathYQL: String!
    var riseYQL: String!
    var setYQL: String!
    var humYQL: String!
    var cityYQL: String!
    var updateYQL: String!
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = .red //Color.Lead.navColor
        refreshControl.tintColor = .white
        let attributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: attributes)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: - SplitView
        self.extendedLayoutIncludesOpaqueBars = true //fix - remove bottom bar'
        //fixed - remove bottom bar
        //self.splitViewController?.delegate = self
        //self.splitViewController!.preferredDisplayMode = .allVisible
        //navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        //navigationItem.leftItemsSupplementBackButton = true
        
        setupNavigation()
        setupSearch()
        setupTableView()
        self.scrollWall!.addSubview(self.refreshControl)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //TabBar Hidden
        self.tabBarController?.tabBar.isHidden = false
        
        // MARK: NavigationController Hidden
        NotificationCenter.default.addObserver(self, selector: #selector(StatisticVC.hideBar(notification:)), name: NSNotification.Name("hide"), object: nil)
        
        //Fix Grey Bar on Bpttom Bar
        if UIDevice.current.userInterfaceIdiom == .phone {
            if let con = self.splitViewController {
                //con.preferredDisplayMode = .allVisible //not fixed
                con.preferredDisplayMode = .primaryOverlay //fixed
            }
        }
        
        refreshData(self) //dont move
        setupNewsNavigationItems()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        //TabBar Hidden
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupSearch() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        self.definesPresentationContext = true
        
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            tableView?.tableHeaderView = searchController.searchBar
        }
    }
 
    fileprivate func setupNavigation() {
        if UI_USER_INTERFACE_IDIOM() == .pad {
            title = "TheLight Software - Statistics"
        } else {
            title = "Statistics"
        }
        UINavigationBar.appearance().largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white, NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: 26)]
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    func setupTableView() {
        self.tableView!.delegate = self
        self.tableView!.dataSource = self
        //self.tableView!.estimatedRowHeight = 44
        //self.tableView!.rowHeight = UITableViewAutomaticDimension
        self.tableView!.backgroundColor = Color.LGrayColor
        
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
    
    @objc func refreshData(_ sender:AnyObject) {

        self.YahooFinanceLoad()
        self.tableView!.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    
    // MARK: - Table View
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (section == 0) {
            return 10
        } else if (section == 1) {
            return 7
        } else if (section == 2) {
            return 5
        } else if (section == 3) {
            return 8
        } else if (section == 4) {
            return 8
        } else {
            if (section == 3) {
                return _feedLeadItems.count
            } else if (section == 4) {
                return _feedCustItems.count
            }
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let CellIdentifier: String = "Cell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as UITableViewCell! else { fatalError("Unexpected Index Path") }

        
        if UI_USER_INTERFACE_IDIOM() == .pad {
            cell.textLabel!.font = Font.Stat.celltitlePad
            cell.detailTextLabel!.font = Font.Stat.celltitlePad
            label1 = UILabel(frame: CGRect(x: tableView.frame.width-195, y: 5, width: 100, height: 25))
            label2 = UILabel(frame: CGRect(x: tableView.frame.width-80, y: 5, width: 70, height: 25))
            label1.font = Font.Stat.celltitlePad
            label2.font = Font.Stat.celltitlePad
        } else {
            cell.textLabel!.font = Font.celltitle16r
            cell.detailTextLabel!.font = Font.celltitle16r
            label1 = UILabel(frame: CGRect(x: tableView.frame.width-160, y: 5, width: 77, height: 25))
            label2 = UILabel(frame: CGRect(x: tableView.frame.width-70, y: 5, width: 65, height: 25))
            label1.font = Font.celltitle16r
            label2.font = Font.celltitle18m
        }
        
        cell.selectionStyle = .none
        cell.accessoryType = .none
        cell.textLabel!.textColor = .black
        cell.detailTextLabel!.textColor = .black
        label1.textColor = .black
        label1.textAlignment = .right
        label2.textColor = .white
        label2.textAlignment = .right

        if (indexPath.section == 0) {
            
            cell.detailTextLabel!.text = ""
            
            if (indexPath.row == 0) {
                
                cell.textLabel!.text = "\(symYQL?[0] ?? "na")"
                label2.text = "\(changeYQL?[0] ?? "0")"
                label1.text = "\(tradeYQL?[0] ?? "")"
                if (label2.text?.contains("-"))! {
                    label2.backgroundColor = .red
                } else {
                    label2.backgroundColor = Color.DGreenColor
                }
                cell.contentView.addSubview(label1)
                cell.contentView.addSubview(label2)
                
                return cell
                
            } else if (indexPath.row == 1) {
                
                cell.textLabel!.text = "\(symYQL?[1] ?? "na")"
                label2.text = "\(changeYQL?[1] ?? "0")"
                label1.text = "\(tradeYQL?[1] ?? "")"
                if (label2.text?.contains("-"))! {
                    label2.backgroundColor = .red
                } else {
                    label2.backgroundColor = Color.DGreenColor
                }
                cell.contentView.addSubview(label1)
                cell.contentView.addSubview(label2)
                
                return cell
                
            } else if (indexPath.row == 2) {
                
                cell.textLabel!.text = "\(symYQL?[2] ?? "na")"
                label2.text = "\(changeYQL?[2] ?? "0")"
                label1.text = "\(tradeYQL?[2] ?? "")"
                if (label2.text?.contains("-"))! {
                    label2.backgroundColor = .red
                } else {
                    label2.backgroundColor = Color.DGreenColor
                }
                cell.contentView.addSubview(label1)
                cell.contentView.addSubview(label2)
                
                return cell
                
            } else if (indexPath.row == 3) {
                
                cell.textLabel!.text = "\(symYQL?[3] ?? "na")"
                label2.text = "\(changeYQL?[3] ?? "0")"
                label1.text = "\(tradeYQL?[3] ?? "")"
                if (label2.text?.contains("-"))! {
                    label2.backgroundColor = .red
                } else {
                    label2.backgroundColor = Color.DGreenColor
                }
                cell.contentView.addSubview(label1)
                cell.contentView.addSubview(label2)
                
                return cell
                
            } else if (indexPath.row == 4) {
                
                cell.textLabel!.text = "\(symYQL?[4] ?? "na")"
                label2.text = "\(changeYQL?[4] ?? "0")"
                label1.text = "\(tradeYQL?[4] ?? "")"
                if (label2.text?.contains("-"))! {
                    label2.backgroundColor = .red
                } else {
                    label2.backgroundColor = Color.DGreenColor
                }
                cell.contentView.addSubview(label1)
                cell.contentView.addSubview(label2)
                
                return cell
                
            } else if (indexPath.row == 5) {
                
                cell.textLabel!.text = "\(symYQL?[5] ?? "na")"
                label2.text = "\(changeYQL?[5] ?? "0")"
                label1.text = "\(tradeYQL?[5] ?? "")"
                if (label2.text?.contains("-"))! {
                    label2.backgroundColor = .red
                } else {
                    label2.backgroundColor = Color.DGreenColor
                }
                cell.contentView.addSubview(label1)
                cell.contentView.addSubview(label2)
                
                return cell
                
            } else if (indexPath.row == 6) {
                
                cell.textLabel!.text = "\(symYQL?[6] ?? "na")"
                label2.text = "\(changeYQL?[6] ?? "0")"
                label1.text = "\(tradeYQL?[6] ?? "")"
                if (label2.text?.contains("-"))! {
                    label2.backgroundColor = .red
                } else {
                    label2.backgroundColor = Color.DGreenColor
                }
                cell.contentView.addSubview(label1)
                cell.contentView.addSubview(label2)
                
                return cell
                
            } else if (indexPath.row == 7) {
                
                cell.textLabel!.text = "\(symYQL?[7] ?? "na")"
                label2.text = "\(changeYQL?[7] ?? "0")"
                label1.text = "\(tradeYQL?[7] ?? "")"
                if (label2.text?.contains("-"))! {
                    label2.backgroundColor = .red
                } else {
                    label2.backgroundColor = Color.DGreenColor
                }
                cell.contentView.addSubview(label1)
                cell.contentView.addSubview(label2)
                
                return cell
                
            } else if (indexPath.row == 8) {
                
                cell.textLabel!.text = "\(symYQL?[8] ?? "na")"
                label2.text = "\(changeYQL?[8] ?? "0")"
                label1.text = "\(tradeYQL?[8] ?? "")"
                if (label2.text?.contains("-"))! {
                    label2.backgroundColor = .red
                } else {
                    label2.backgroundColor = Color.DGreenColor
                }
                cell.contentView.addSubview(label1)
                cell.contentView.addSubview(label2)
                
                return cell
                
            } else if (indexPath.row == 9) {
                
                cell.textLabel!.text = "\(symYQL?[9] ?? "na")"
                label2.text = "\(changeYQL?[9] ?? "0")"
                label1.text = "\(tradeYQL?[9] ?? "")"
                if (label2.text?.contains("-"))! {
                    label2.backgroundColor = .red
                } else {
                    label2.backgroundColor = Color.DGreenColor
                }
                cell.contentView.addSubview(label1)
                cell.contentView.addSubview(label2)
                
                return cell
            }
            
        } else if (indexPath.section == 1) {
            
            if (indexPath.row == 0) {
                if (tempYQL != nil) {
                    cell.detailTextLabel!.text = "\(tempYQL!)"
                } else {
                    cell.detailTextLabel!.text = "Not Available"
                }
                cell.textLabel!.text = "Todays Temperature"
                return cell
                
            } else if (indexPath.row == 1) {
                if (weathYQL != nil) {
                    cell.detailTextLabel!.text = "\(weathYQL!)"
                } else {
                    cell.detailTextLabel!.text = "Not Available"
                }
                cell.textLabel!.text = "Todays Weather"
                return cell
                
            } else if (indexPath.row == 2) {
                if (riseYQL != nil) {
                    cell.detailTextLabel!.text = "\(riseYQL!)"
                } else {
                    cell.detailTextLabel!.text = "Not Available"
                }
                cell.textLabel!.text = "Sunrise"
                return cell
                
            } else if (indexPath.row == 3) {
                if (setYQL != nil) {
                    cell.detailTextLabel!.text = "\(setYQL!)"
                } else {
                    cell.detailTextLabel!.text = "Not Available"
                }
                cell.textLabel!.text = "Sunset"
                return cell
            } else if (indexPath.row == 4) {
                if (humYQL != nil) {
                    cell.detailTextLabel!.text = "\(humYQL!)"
                } else {
                    cell.detailTextLabel!.text = "Not Available"
                }
                cell.textLabel!.text = "Humidity"
                return cell
            } else if (indexPath.row == 5) {
                if (cityYQL != nil) {
                    cell.detailTextLabel!.text = "\(cityYQL!)"
                } else {
                    cell.detailTextLabel!.text = "Not Available"
                }
                cell.textLabel!.text = "City"
                return cell
            } else if (indexPath.row == 6) {
                if (updateYQL != nil) {
                    cell.detailTextLabel!.text = "\(updateYQL!)"
                } else {
                    cell.detailTextLabel!.text = "Not Available"
                }
                cell.textLabel!.text = "Last Update"
                return cell
            }
            
        } else if (indexPath.section == 2) {
            
            if (indexPath.row == 0) {
                if (dayYQL != nil) && (textYQL != nil) {
                    cell.textLabel!.text = "\(dayYQL[0])"
                    cell.detailTextLabel!.text = "\(textYQL[0])"
                } else {
                    cell.textLabel!.text = "Day1"
                    cell.detailTextLabel!.text = "Not Available"
                }
                return cell
                
            } else if (indexPath.row == 1) {
                if (dayYQL != nil) && (textYQL != nil) {
                    cell.textLabel!.text = "\(dayYQL[1])"
                    cell.detailTextLabel!.text = "\(textYQL[1])"
                } else {
                    cell.textLabel!.text = "Day2"
                    cell.detailTextLabel!.text = "Not Available"
                }
                return cell
                
            } else if (indexPath.row == 2) {
                if (dayYQL != nil) && (textYQL != nil) {
                    cell.textLabel!.text = "\(dayYQL[2])"
                    cell.detailTextLabel!.text = "\(textYQL[2])"
                } else {
                    cell.textLabel!.text = "Day3"
                    cell.detailTextLabel!.text = "Not Available"
                }
                return cell
                
            } else if (indexPath.row == 3) {
                if (dayYQL != nil) && (textYQL != nil) {
                    cell.textLabel!.text = "\(dayYQL[3])"
                    cell.detailTextLabel!.text = "\(textYQL[3])"
                } else {
                    cell.textLabel!.text = "Day4"
                    cell.detailTextLabel!.text = "Not Available"
                }
                return cell
            } else if (indexPath.row == 4) {
                if (dayYQL != nil) && (textYQL != nil) {
                    cell.textLabel!.text = "\(dayYQL[4])"
                    cell.detailTextLabel!.text = "\(textYQL[4])"
                } else {
                    cell.textLabel!.text = "Day5"
                    cell.detailTextLabel!.text = "Not Available"
                }
                return cell
            }
            
        } else if (indexPath.section == 3) {
            
            if (indexPath.row == 0) {
                
                cell.textLabel!.text = "Leads Today"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
                
            } else if (indexPath.row == 1) {
                
                cell.textLabel!.text = "Appointment's Today"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
                
            } else if (indexPath.row == 2) {
                
                cell.textLabel!.text = "Appointment's Tomorrow"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
                
            } else if (indexPath.row == 3) {
                
                cell.textLabel!.text = "Leads Active"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
            } else if (indexPath.row == 4) {
                
                cell.textLabel!.text = "Leads Year"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
            } else if (indexPath.row == 5) {
                
                cell.textLabel!.text = "Leads Avg"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
            } else if (indexPath.row == 6) {
                
                cell.textLabel!.text = "Leads High"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
            } else if (indexPath.row == 7) {
                
                cell.textLabel!.text = "Leads Low"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
            }
            
        } else if (indexPath.section == 4) {
            
            if (indexPath.row == 0) {
                
                cell.textLabel!.text = "Customers Today"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
                
            } else if (indexPath.row == 1) {
                
                cell.textLabel!.text = "Customers Yesterday"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
                
            } else if (indexPath.row == 2) {
                
                cell.textLabel!.text = "Windows Sold"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
                
            } else if (indexPath.row == 3) {
                
                cell.textLabel!.text = "Customers Active"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
            } else if (indexPath.row == 4) {
                
                cell.textLabel!.text = "Customers Year"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
            } else if (indexPath.row == 5) {
                
                cell.textLabel!.text = "Customers Avg"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
            } else if (indexPath.row == 6) {
                
                cell.textLabel!.text = "Customers High"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
            } else if (indexPath.row == 7) {
                
                cell.textLabel!.text = "Customers Low"
                //cell.detailTextLabel!.text = w1results valueForKeyPath:"query.results.channel.item.condition"] objectForKey:"temp"
                
                return cell
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if (section == 0) {
            return 135
        } else if (section == 1) {
            return 5
        } else if (section == 2) {
            return 5
        } else if (section == 3) {
            return 5
        } else if (section == 4) {
            return 5
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if (section == 0) {
            let vw = UIView()
            //vw.frame = CGRectMake(0 , 0, tableView.frame.width, 175)
            if UI_USER_INTERFACE_IDIOM() == .pad {
                vw.backgroundColor = .black
            } else {
                vw.backgroundColor = Color.Stat.navColor
            }
            //tableView.tableHeaderView = vw
            
            segmentedControl = UISegmentedControl (items: ["WEEKLY", "MONTHLY", "YEARLY"])
            segmentedControl.frame = CGRect(x: tableView.frame.width/2-125, y: 15, width: 250, height: 30)
            segmentedControl.backgroundColor = .red
            segmentedControl.tintColor = .white
            segmentedControl.selectedSegmentIndex = 1
            segmentedControl.addTarget(self, action: #selector(segmentedControlAction), for: .valueChanged)
            vw.addSubview(segmentedControl)
            
            /*
            let myLabel1 = UILabel(frame: CGRect(x: tableView.frame.width/2-45, y: 3, width: 90, height: 45))
            myLabel1.textColor = .white
            myLabel1.textAlignment = .center
            myLabel1.text = "Statistics"
            myLabel1.font = UIFont (name: "Avenir-Book", size: 21)
            vw.addSubview(myLabel1) */
            
            let myLabel2 = UILabel(frame: CGRect(x: tableView.frame.width/2-25, y: 45, width: 50, height: 45))
            myLabel2.textColor = .green
            myLabel2.textAlignment = .center
            myLabel2.text = "SALES"
            myLabel2.font = UIFont (name: "Avenir-Black", size: 16)
            vw.addSubview(myLabel2)
            
            let separatorLineView1 = UIView(frame: CGRect(x: tableView.frame.width/2-30, y: 80, width: 60, height: 1.9))
            separatorLineView1.backgroundColor = .white
            vw.addSubview(separatorLineView1)
            
            myLabel3 = UILabel(frame: CGRect(x: tableView.frame.width/2-70, y: 85, width: 140, height: 45))
            myLabel3.textColor = .white
            myLabel3.textAlignment = .center
            myLabel3.text = "$200,000"
            myLabel3.font = UIFont (name: "Avenir-Black", size: 30)
            vw.addSubview(myLabel3)
            
            return vw
        }
        return nil
    }
    
    // MARK: - SegmentedControl
    
    @objc func segmentedControlAction(_ sender: UISegmentedControl) {
        
        if(segmentedControl.selectedSegmentIndex == 0)
        {
            myLabel3.text = "$100,000"
        }
        else if(segmentedControl.selectedSegmentIndex == 1)
        {
            myLabel3.text = "$200,000"
        }
        else if(segmentedControl.selectedSegmentIndex == 2)
        {
            myLabel3.text = "$300,000"
        }
    }
    
    // MARK: - YahooFinance
    
    func YahooFinanceLoad() {
        guard ProcessInfo.processInfo.isLowPowerModeEnabled == false else { return }
        //weather
        //let results = YQL.query(statement: "select * from weather.forecast where woeid=2446726")
        let results = YQL.query(statement: String(format: "%@%@", "select * from weather.forecast where woeid=", self.defaults.string(forKey: "weatherKey")!))
        
        let queryResults = results?.value(forKeyPath: "query.results.channel") as? NSDictionary
        if queryResults != nil {
            
            let arr = queryResults!.value(forKeyPath: "item.condition") as? NSDictionary
            tempYQL = arr!.value(forKey: "temp") as? String
            weathYQL = arr!.value(forKey: "text") as? String
            let arr1 = queryResults!.value(forKeyPath: "astronomy") as? NSDictionary
            riseYQL = arr1!.value(forKey: "sunrise") as? String
            setYQL = arr1!.value(forKey: "sunset") as? String
            let arr2 = queryResults!.value(forKeyPath: "atmosphere") as? NSDictionary
            humYQL = arr2!.value(forKey: "humidity") as? String
            let arr3 = queryResults!.value(forKeyPath: "location") as? NSDictionary
            cityYQL = arr3!.value(forKey: "city") as? String
            updateYQL = queryResults!.value(forKey: "lastBuildDate") as? String
            
            //5 day Forcast
            dayYQL = queryResults!.value(forKeyPath: "item.forecast.day") as? NSArray
            textYQL = queryResults!.value(forKeyPath: "item.forecast.text") as? NSArray
        }
        //stocks
        let stockresults = YQL.query(statement: "select * from yahoo.finance.quote where symbol in (\"^IXIC\",\"SPY\",\"FB\",\"VCSY\",\"GPRO\",\"VXX\",\"UPL\",\"SWKS\",\"AAPL\",\"^XOI\")")
        //let stockresults = YQL.query(statement: "select * from yahoo.finance.quote where symbol in (\"FB\",\"FB\",\"FB\",\"FB\",\"FB\",\"FB\",\"FB\",\"FB\",\"FB\",\"FB\")")
        
        let querystockResults = stockresults?.value(forKeyPath: "query.results") as? NSDictionary
        if querystockResults != nil {
            
            symYQL = querystockResults!.value(forKeyPath: "quote.symbol") as? NSArray
            tradeYQL = querystockResults!.value(forKeyPath: "quote.LastTradePriceOnly") as? NSArray
            changeYQL = querystockResults!.value(forKeyPath: "quote.Change") as? NSArray
        }
    }
}
//-----------------------end------------------------------

extension StatisticVC: UISearchResultsUpdating {
    
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
