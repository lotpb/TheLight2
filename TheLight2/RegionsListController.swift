//
//  RegionsListController.swift
//  Coldest Places On Earth
//
//  Created by Malek T. on 12/4/15.
//  Copyright © 2015 Medigarage Studios LTD. All rights reserved.
//

import UIKit


protocol RegionsProtocol{
    func loadOverlayForRegionWithLatitude(_ latitude:Double, andLongitude longitude:Double)
}


class RegionsListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // Properties
    var regions:[String]!
    var latitudes:[Double]!
    var longitudes:[Double]!

    var delegate:RegionsProtocol!

    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        regions = ["Verkhoyansk (Russia)","Fraser, Colo (United States)","Hell (Norway)","Barrow (Alaska)","Oymyakon (Russia)"]
        latitudes = [67.550592,39.944987,63.445171,71.290556,63.464138]
        longitudes = [133.399340,-105.817232,10.905217,-156.788611,142.773727]
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITableViewDataSource Protocol
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "regionCell")
        cell?.textLabel!.text = regions[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regions.count
    }
    
    //MARK: UITableViewDelegate Protocol
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        navigationController!.popViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
        delegate.loadOverlayForRegionWithLatitude(latitudes[indexPath.row], andLongitude: longitudes[indexPath.row])
    }

}
