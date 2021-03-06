//
//  MenuController.swift
//  SlideOutMenu
//
//  Created by ivica petrsoric on 14/10/2018.
//  Copyright © 2018 ivica petrsoric. All rights reserved.
//

import UIKit

struct MenuItem {
    let icon: UIImage
    let title: String
}

extension MenuController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let slidingController = UIApplication.shared.keyWindow?.rootViewController as? BaseSlidingController
        slidingController?.didSelectMenuItem(indexPath: indexPath)
    }
}

class MenuController: UITableViewController {
    
    let menuItems = [
        MenuItem(icon: #imageLiteral(resourceName: "thumbUp"), title: "Unclassified"),
        MenuItem(icon: #imageLiteral(resourceName: "car"), title: "All Drives"),
        MenuItem(icon: #imageLiteral(resourceName: "display30copy"), title: "Monthly  Summaries"),
        MenuItem(icon: #imageLiteral(resourceName: "settings"), title: "Account Settings"),
        MenuItem(icon: #imageLiteral(resourceName: "feedback"), title: "Drive  Detection"),
        MenuItem(icon: #imageLiteral(resourceName: "help"), title: "Help"),
        ]
    
    private let cellID = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let customHeaderView = CustomMenuHeaderView()
        return customHeaderView
    }
    
//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 200
//    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 80
//    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MenuItemCell(style: .default, reuseIdentifier: cellID)
        let menuItem = menuItems[indexPath.row]
        cell.iconImageView.image = menuItem.icon
        cell.titleLabel.text = menuItem.title
//        cell.textLabel?.text = menuItem.title
//        cell.imageView?.image = menuItem.icon
        return cell
    }
    
}
