//
//  UserProfileController.swift
//  TheLight2
//
//  Created by Peter Balsamo on 6/21/17.
//  Copyright © 2017 Peter Balsamo. All rights reserved.
//

import UIKit
import Parse
import Firebase
import MapKit
import CoreLocation
import MobileCoreServices //kUTTypeImage
import MessageUI

class UserProfileController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    let cellId = "cellId"
    //let mapCellId = "mapCellId"
    var defaults = UserDefaults.standard
    
    //firebase
    var userlist = [UserModel]()
    var users: UserModel?
    var posts = [NewsModel]()
    
    //parse
    var _feedItems = NSMutableArray()
    var user : PFUser?
    var userquery : PFObject?
    
    //var filteredString = NSMutableArray()
    var followingNumber: Int?
    var status : String?
    var objectId : String?
    var username : String?
    var create : String?
    var email : String?
    var phone : String?
    
    var userimage : UIImage?
    var pickImage : UIImage?
    var pictureData : Data?
    
    var imagePicker: UIImagePickerController!
    var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    
    var emailTitle :NSString?
    var messageBody:NSString?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userMapItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(userMapButton))
        navigationItem.setRightBarButton(userMapItem, animated: true)
        
        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(setbackButton))
        navigationItem.setLeftBarButton(doneBarButtonItem, animated: true)
        
        collectionView?.backgroundColor = .white
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerID")
        collectionView?.register(UserProfilePhotoCell.self, forCellWithReuseIdentifier: cellId)
        //collectionView?.register(UserProfileMapCell.self, forCellWithReuseIdentifier: mapCellId)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fetchPhotoImages()
        fetchUserImage()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        users = nil
    }
    
    // MARK: - Button
    
    @objc func setbackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - LoadData
    
    fileprivate func fetchUserImage() {
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.fetchUserWithUID(uid: uid) { (user) in
            self.users = user
            self.navigationItem.title = self.users?.username
            self.collectionView?.reloadData()
        }
    }
    
    fileprivate func fetchPhotoImages() { 
        
        if (defaults.bool(forKey: "parsedataKey")) {
            
            let query = PFUser.query()
            query!.order(byDescending: "createdAt")
            query!.cachePolicy = .cacheThenNetwork
            query!.findObjectsInBackground { objects, error in
                if error == nil {
                    let temp: NSArray = objects! as NSArray
                    self._feedItems = temp.mutableCopy() as! NSMutableArray
                    self.collectionView!.reloadData()
                } else {
                    print("Crap Error")
                }
            }
        } else {
            //firebase
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let ref = Database.database().reference()
            ref.child("News") //.child(uid)
                .queryOrdered(byChild: "uid")
                .queryEqual(toValue: uid)
                .observe(.childAdded , with:{ (snapshot) in
                    
                    guard let dictionary = snapshot.value as? [String: Any] else {return}
                    let post = NewsModel(dictionary: dictionary)
                    //self.posts.insert(post, at: 0)
                    self.posts.append(post)
                    
                    DispatchQueue.main.async(execute: {
                        self.collectionView?.reloadData()
                    })
                }) { (err) in
                    print("Failed to fetch users for search:", err)
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if (defaults.bool(forKey: "parsedataKey")) {
            return self._feedItems.count
        } else {
            return posts.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let identifier: String
        identifier = cellId
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! UserProfilePhotoCell
        
        cell.post = posts[indexPath.item]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerID", for: indexPath) as! UserProfileHeader
        
        header.user = self.users
        header.editProfileBtn.addTarget(self, action: #selector(EditProfileButton), for: .touchUpInside)
        let followNum = followingNumber ?? 0
        header.updateValues(posts: posts.count , follower: followNum, following: followNum)
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 180)
    }
    
    // MARK: - Button
    
    @objc func userMapButton(sender: AnyObject) {
        
        let loginController = UserViewController()
        let navController = UINavigationController(rootViewController: loginController)
        self.present(navController, animated: true, completion:nil)
    }
    
    @objc func EditProfileButton() {
        
        let loginController = UserDetailController()
        let navController = UINavigationController(rootViewController: loginController)
        self.present(navController, animated: true, completion:nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if let VC = segue.destination as? UserDetailController {
            
            if (defaults.bool(forKey: "parsedataKey")) {
                /*
                updated = ((self._feedItems[(indexPath.row)] as AnyObject).value(forKey: "createdAt") as? Date)!
                VC!.objectId = (self._feedItems[(indexPath.row)] as AnyObject).value(forKey: "objectId") as? String
                VC!.username = (self._feedItems[(indexPath.row)] as AnyObject).value(forKey: "username") as? String
                VC!.email = (self._feedItems[(indexPath.row)] as AnyObject).value(forKey: "email") as? String
                VC!.phone = (self._feedItems[(indexPath.row)] as AnyObject).value(forKey: "phone") as? String
                VC!.userimage = self.selectedImage
                */
            } else {
                //firebase
                //updated = users?.creationDate
                VC.username = users?.username
                VC.email = users?.email
                VC.phone = users?.phone
                //VC!.userimage = self.selectedImage
            }
            
        }
    }
        
    
}
