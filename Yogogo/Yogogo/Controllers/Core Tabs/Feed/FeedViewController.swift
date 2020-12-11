//
//  FeedViewController.swift
//  Yogogo
//
//  Created by prince on 2020/11/30.
//

import UIKit
import Firebase

class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var postFeed: [Post] = []
    
    var isLoadingPost = false
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigation()
        setupRefresher()
    }
 
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
        loadRecentPosts()
        getUserInfo()
    }
    
    private func getUserInfo() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        UserManager.shared.getUserInfo(userId: userId) { (user) in
            print("------  Get the currentUser info successfully in FeedVC ------")
            print(user)
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func setupNavigation() {
//        navigationController?.navigationBar.barTintColor = .white
        navigationItem.backBarButtonItem?.tintColor = .label
        navigationItem.backButtonTitle = ""
    }
    
    private func setupRefresher() {
        tableView.refreshControl = refreshControl
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.tintColor = UIColor.lightGray
        refreshControl.addTarget(self,
                                 action: #selector(loadRecentPosts),
                                 for: UIControl.Event.valueChanged
        )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == StoryboardId.cameraVC.rawValue {
            let storyboard = UIStoryboard(name: StoryboardName.camera.rawValue, bundle: nil)
            guard let cameraVC = storyboard.instantiateViewController(identifier: StoryboardId.cameraVC.rawValue) as? CameraViewController else { return }
            cameraVC.delegate = self
        }
    }
}

// MARK: - Managing Post Download and Display

extension FeedViewController: LoadRecentPostsDelegate {
    
    func loadRecentPost() {
        loadRecentPosts()
    }
    
    @objc private func loadRecentPosts() {
        
        print("------ Loading Recent Posts... ------")
        
        isLoadingPost = true
        
        PostManager.shared.getRecentPosts(start: postFeed.first?.timestamp, limit: 10) { (newPosts) in
            
            if newPosts.count > 0 {
                // Add the array to the beginning of the posts arrays
                self.postFeed.insert(contentsOf: newPosts, at: 0)
            }
            
            self.isLoadingPost = false
            
            if self.refreshControl.isRefreshing {
                
                // Delay 0.5 second before ending the refreshing in order to make the animation look better
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                    self.refreshControl.endRefreshing()
                    self.displayNewPosts(newPosts: newPosts)
                })
                
            } else {
                self.displayNewPosts(newPosts: newPosts)
            }
        }
    }

    private func displayNewPosts(newPosts posts: [Post]) {
        
        // Make sure we got some new posts to display
        guard posts.count > 0 else {
            return
        }
        
        // Display the posts by inserting them to the table view
        var indexPaths: [IndexPath] = []
        
        self.tableView.beginUpdates()
        
        for num in 0...(posts.count - 1) {
            let indexPath = IndexPath(row: num, section: 0)
            indexPaths.append(indexPath)
        }
        self.tableView.insertRows(at: indexPaths, with: .fade)
        self.tableView.endUpdates()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension FeedViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postFeed.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FeedTableViewCell.identifier, for: indexPath) as? FeedTableViewCell else { return UITableViewCell() }
        
        let currentPost = postFeed[indexPath.row]
        cell.setup(post: currentPost)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        // We want to trigger the loading when the user reaches the last two rows
        guard !isLoadingPost, postFeed.count - indexPath.row == 2 else {
            return
        }
        
        isLoadingPost = true
        
        guard let lastPostTimestamp = postFeed.last?.timestamp else {
            isLoadingPost = false
            return
        }
        
        print("------ Loading Old Posts... ------")
        
        PostManager.shared.getOldPosts(start: lastPostTimestamp, limit: 10) { (oldPosts) in
            
            // Add old posts to existing arrays and table view
            var indexPaths: [IndexPath] = []
            
            self.tableView.beginUpdates()
            
            for oldPost in oldPosts {
                self.postFeed.append(oldPost)
                let indexPath = IndexPath(row: self.postFeed.count - 1, section: 0)
                indexPaths.append(indexPath)
            }
            self.tableView.insertRows(at: indexPaths, with: .fade)
            self.tableView.endUpdates()
            
            self.isLoadingPost = false
        }
    }
}
