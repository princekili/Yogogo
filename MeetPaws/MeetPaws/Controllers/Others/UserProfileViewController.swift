//
//  UserProfileViewController.swift
//  MeetPaws
//
//  Created by prince on 2020/12/14.
//

import UIKit
import Firebase

class UserProfileViewController: UIViewController {
    
    var userPosts: [Post] = []
    
    var post: Post?
    
    var user: User?
    
    var isLoadingPost = false
    
    let refreshControl = UIRefreshControl()
    
    let userManager = UserManager.shared
    
    let segueId = "SegueUserProfileToFollowers"
    
    var followType: FollowType = .followers
    
    var blockHandler: (() -> Void)?
    
    // MARK: - @IBOutlet
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - @IBAction
    
    @IBAction func moreActionsButtonDidTap(_ sender: UIBarButtonItem) {
        guard let user = self.user else { return }
        presentAlert(with: user.userId)
    }
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        filterBlockedFollowers()
        filterBlockedFollowing()
        setupNavigationBar()
        setupCollectionView()
        setupRefresher()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadAndReloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "SegueUserPostVC" {
            guard let myPostVC = segue.destination as? MyPostViewController else { return }
            myPostVC.post = post
            
        } else if segue.identifier == segueId {
            guard let followersVC = segue.destination as? FollowersViewController else { return }
            guard let user = user else { return }
            followersVC.listOwner = user
            followersVC.followType = followType
        }
    }
    
    // MARK: -
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self

        // Header for tabs
        // It's necessary for programming UI
        collectionView.register(UserProfileTabsCollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: UserProfileTabsCollectionReusableView.identifier)
    }
    
    private func setupNavigationBar() {
        navigationItem.backButtonTitle = ""
        
        guard let user = self.user else { return }
        navigationItem.title = user.username
    }
    
    private func setupRefresher() {
        collectionView.refreshControl = refreshControl
        refreshControl.backgroundColor = UIColor.clear
        refreshControl.tintColor = UIColor.lightGray
        refreshControl.addTarget(self,
                                 action: #selector(loadUserPosts),
                                 for: UIControl.Event.valueChanged
        )
    }
    
    private func loadAndReloadData() {
        loadUserPosts()
        collectionView.reloadData()
    }
    
    private func observeUser() {
        guard let user = self.user else { return }
        FollowManager.shared.observeUser(of: user.userId) { [weak self] (user) in
            self?.user = user
        }
    }
    
    // MARK: - Block alert
    
    private func presentAlert(with userId: String) {
        
        // UIAlertController
        let moreActionsAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // UIAlertAction
        let blockAction = UIAlertAction(title: "Block", style: .destructive) { [weak self] _ in
            self?.confirmBlockUserAlert(with: userId)
        }
        moreActionsAlertController.addAction(blockAction)
        
        let reportAction = UIAlertAction(title: "Report", style: .destructive) { [weak self] _ in
            self?.confirmReportUserAlert(with: userId)
        }
        moreActionsAlertController.addAction(reportAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            moreActionsAlertController.dismiss(animated: true, completion: nil)
        }
        moreActionsAlertController.addAction(cancelAction)
        
        self.present(moreActionsAlertController, animated: true, completion: nil)
    }
    
    private func confirmBlockUserAlert(with userId: String) {
        
        // UIAlertController
        let title = "Block User?"
        let message = "You won't see each other again after relaunching MeetPaws."
        let confirmAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // UIAlertAction
        let blockAction = UIAlertAction(title: "Block", style: .destructive) { _ in
            guard let user = self.user else {
                WrapperProgressHUD.showFailed(with: "User doesn't exist.")
                return
            }
            UserManager.shared.block(with: user) {
                self.blockHandler?()
                WrapperProgressHUD.showSuccess()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            confirmAlertController.dismiss(animated: true, completion: nil)
        }
        
        // addAction
        confirmAlertController.addAction(blockAction)
        confirmAlertController.addAction(cancelAction)
        
        self.present(confirmAlertController, animated: true, completion: nil)
    }
    
    private func confirmReportUserAlert(with userId: String) {
        
        // UIAlertController
        let title = "Report Inappropriate User?"
        let message = "Your report is anonymous. If someone is in immediate danger, call the local emergency services, don't wait."
        let confirmAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // UIAlertAction
        let reportAction = UIAlertAction(title: "Report", style: .destructive) { _ in
            WrapperProgressHUD.showSuccess()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            confirmAlertController.dismiss(animated: true, completion: nil)
        }
        
        // addAction
        confirmAlertController.addAction(reportAction)
        confirmAlertController.addAction(cancelAction)
        
        self.present(confirmAlertController, animated: true, completion: nil)
    }
    
    // MARK: - Filter blocked followers & following
    
    private func filterBlockedFollowers() {
        // The userId should not be in the ignoreList
        guard let user = self.user else { return }
        if let ignoreList = UserManager.shared.currentUser?.ignoreList {
            for userId in ignoreList {
                self.user?.followers = user.followers.filter { $0 != userId }
            }
        }
    }
    
    private func filterBlockedFollowing() {
        // The userId should not be in the ignoreList
        guard let user = self.user else { return }
        if let ignoreList = UserManager.shared.currentUser?.ignoreList {
            for userId in ignoreList {
                self.user?.following = user.following.filter { $0 != userId }
            }
        }
    }
}

// MARK: - load User Posts

extension UserProfileViewController {
    
    @objc private func loadUserPosts() {
        
        guard let user = self.user else { return }
        var postIds = user.posts
        postIds = postIds.filter { $0 != "" }
        
        var userPosts: [Post] = []
        
        for postId in postIds {
            
            print("------ Loading User Post: \(postId) ------")
            
            self.isLoadingPost = true
            
            PostManager.shared.observeUserPost(postId: postId) { [weak self] (newPost) in
                
                // Add the array to the beginning of the posts arrays
                userPosts.append(newPost)
                userPosts.sort(by: { $0.timestamp > $1.timestamp })
                self?.userPosts = userPosts
                
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

extension UserProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        }
        return userPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: UserPostCollectionViewCell.identifier,
                for: indexPath) as? UserPostCollectionViewCell
        else {
            return UICollectionViewCell()
        }
        
        let post = userPosts[indexPath.item]
        cell.setup(post: post)
        
        // Block the user
        self.blockHandler = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (view.width - 2)/3
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        post = userPosts[indexPath.item]
        
        performSegue(withIdentifier: "SegueUserPostVC", sender: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        // Header only
        guard kind == UICollectionView.elementKindSectionHeader else {
            // No footer
            return UICollectionReusableView()
        }
        
        if indexPath.section == 1 {
            // tabs header
            guard let headerForTabs = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                         withReuseIdentifier: UserProfileTabsCollectionReusableView.identifier,
                                                                         for: indexPath) as? UserProfileTabsCollectionReusableView
            else { return UICollectionReusableView() }
            headerForTabs.delegate = self
            return headerForTabs
        }
        
        guard let headerForInfo = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                     withReuseIdentifier: UserProfileHeaderCollectionReusableView.identifier,
                                                                     for: indexPath) as? UserProfileHeaderCollectionReusableView
        else { return UICollectionReusableView() }
        
        guard let user = self.user else { return UICollectionReusableView() }
        headerForInfo.setup(user: user)
        headerForInfo.delegateOpenUserMessages = self
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

extension UserProfileViewController: UserProfileTabsCollectionReusableViewDelegate {
    
    func gridButtonDidTap() {
        // Reload collection view
    }
    
    func listButtonDidTap() {
        // Reload collection view
    }
}

extension UserProfileViewController: OpenUserMessagesHandlerDelegate {
    
    func openUserMessagesHandler() {
        let chatVC = ChatViewController()
        chatVC.user = user
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

// MARK: - MyProfileHeaderCollectionReusableViewDelegate

extension UserProfileViewController: MyProfileHeaderCollectionReusableViewDelegate {
    
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
