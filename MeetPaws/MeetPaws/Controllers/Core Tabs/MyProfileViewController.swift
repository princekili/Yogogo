//
//  ProfileViewController.swift
//  MeetPaws
//
//  Created by prince on 2020/12/2.
//

import UIKit
import Firebase

class MyProfileViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let userManager = UserManager.shared
    
    var myPosts: [Post] = []
    
    var post: Post?
    
    var isLoadingPost = false
    
    let refreshControl = UIRefreshControl()
    
    let segueId = "SegueMyProfileToFollowers"
    
    var followType: FollowType = .followers

    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
        setupRefresher()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadAndReloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SegueMyPostVC" {
            guard let myPostVC = segue.destination as? MyPostViewController else { return }
            myPostVC.post = post
            
        } else if segue.identifier == segueId {
            guard let followersVC = segue.destination as? FollowersViewController else { return }
            guard let myself = userManager.currentUser else { return }
            followersVC.listOwner = myself
            followersVC.followType = followType
        }
    }
    
    // MARK: -
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self

        // Header for tabs
        // It's necessary for programming UI
        collectionView.register(MyProfileTabsCollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: MyProfileTabsCollectionReusableView.identifier)
    }
    
    private func setupNavigationBar() {
        navigationItem.backButtonTitle = ""
        
        // Check isPushFromOtherVC
        if let rootVC = navigationController?.rootViewController {
            let isPushFromOtherVC = (rootVC is FeedViewController) || (rootVC is MapsViewController) || (rootVC is SearchViewController)
            
            switch isPushFromOtherVC {
            case true:
                navigationItem.leftBarButtonItem = nil
                navigationItem.backButtonTitle = ""
            case false:
                break
            }
        }
    }
    
    private func setupRefresher() {
        collectionView.refreshControl = refreshControl
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.tintColor = UIColor.lightGray
        refreshControl.addTarget(self,
                                 action: #selector(loadMyPosts),
                                 for: UIControl.Event.valueChanged
        )
    }
    
    private func loadAndReloadData() {
        loadMyPosts()
        collectionView.reloadData()
    }
}

// MARK: - load My Posts

extension MyProfileViewController {
    
    @objc private func loadMyPosts() {
        
        guard let userId = UserManager.shared.currentUser?.userId else { return }
        userManager.getCurrentUserInfo(userId: userId) { [weak self] (user) in
            
            self?.navigationItem.title = user.username
            
            var postIds = user.posts
            postIds = postIds.filter { $0 != "" }
            
            var myPosts: [Post] = []
            
            for postId in postIds {
                
                self?.isLoadingPost = true
                
                PostManager.shared.observeUserPost(postId: postId) { [weak self] (newPost) in
                    
                    // Add the array to the beginning of the posts arrays
                    myPosts.append(newPost)
                    
                    myPosts.sort(by: { $0.timestamp > $1.timestamp })
                    
                    // Save to local PostManager
                    PostManager.shared.postsOfCurrentUser = myPosts
                    
                    self?.myPosts = myPosts
                    
                    self?.isLoadingPost = false
                    
                    if ((self?.refreshControl.isRefreshing) != nil) == true {
                        
                        // Delay 0.5 second before ending the refreshing in order to make the animation look better
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                            self?.refreshControl.endRefreshing()
                            self?.collectionView.reloadData()
                        })
                        
                    } else {
                        self?.collectionView.reloadData()
                    }
                }
            }
        }
    }
}

extension MyProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if section == 0 {
            return 0
        }
        return myPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MyPostCollectionViewCell.identifier,
                                                            for: indexPath) as? MyPostCollectionViewCell
        else {
            return UICollectionViewCell()
        }
        
        let post = myPosts[indexPath.item]
        cell.setup(with: post)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let size = (view.width - 2)/3
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        post = myPosts[indexPath.item]
        
        performSegue(withIdentifier: "SegueMyPostVC", sender: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // Header only
        guard kind == UICollectionView.elementKindSectionHeader else {
            // No footer
            return UICollectionReusableView()
        }
        
        if indexPath.section == 1 {
            // tabs header
            guard let headerForTabs = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MyProfileTabsCollectionReusableView.identifier, for: indexPath) as? MyProfileTabsCollectionReusableView else { return UICollectionReusableView() }
            
            headerForTabs.delegate = self
            return headerForTabs
        }
        
        guard let headerForInfo = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MyProfileHeaderCollectionReusableView.identifier, for: indexPath) as? MyProfileHeaderCollectionReusableView else { return UICollectionReusableView() }
        
        headerForInfo.setup()
        headerForInfo.delegateForButtons = self
        return headerForInfo
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            return CGSize(width: collectionView.width, height: 350)
        }
        // Size of section tabs
//        return CGSize(width: collectionView.width, height: 50)
        // MARK: - Hide tabs for now
        return CGSize(width: collectionView.width, height: 0)
    }
}

// MARK: - MyProfileTabsCollectionReusableViewDelegate

extension MyProfileViewController: MyProfileTabsCollectionReusableViewDelegate {
    
    func gridButtonDidTap() {
        // Reload collection view
    }
    
    func listButtonDidTap() {
        // Reload collection view
    }
}

// MARK: - MyProfileHeaderCollectionReusableViewDelegate

extension MyProfileViewController: MyProfileHeaderCollectionReusableViewDelegate {
    
    func postsButtonDidTap(_ header: UICollectionReusableView) {
        // scroll to the posts
        let indexPath = IndexPath(row: 0, section: 1)
        collectionView.scrollToItem(at: indexPath, at: .top, animated: true)
    }
    
    func followersButtonDidTap() {
        followType = .followers
        performSegue(withIdentifier: segueId, sender: nil)
    }
    
    func followingButtonDidTap() {
        followType = .following
        performSegue(withIdentifier: segueId, sender: nil)
    }
}
