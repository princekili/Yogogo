//
//  AddPostViewController.swift
//  Yogogo
//
//  Created by prince on 2020/11/30.
//

import UIKit
import YPImagePicker
import AVFoundation
import AVKit
import Photos
import FirebaseDatabase

protocol LoadRecentPostsDelegate: AnyObject {
    
    func loadRecentPost()
}

class CameraViewController: UIViewController {
    
    var selectedItems = [YPMediaItem]()
    
    let selectedImageV = UIImageView()
    
    let pickButton = UIButton()
    
    let resultsButton = UIButton()
    
    weak var delegate: LoadRecentPostsDelegate?
    
    @IBOutlet weak var imageButton: UIButton!
    
    @IBOutlet weak var captionTextView: UITextView! {
        didSet {
            captionTextView.placeholder = "Write a caption..."
        }
    }
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showPicker()
        hideButtons()
//        observePosts()
    }
    
    // MARK: - Upload Post
    
    @IBAction func shareButtonDidTap(_ sender: UIBarButtonItem) {
        shareButton.isEnabled = false
        
        guard let image = selectedItems.singlePhoto?.image else {
            dismiss(animated: true, completion: nil)
            print("selectedItems error")
            return
        }
        let caption = captionTextView.text ?? ""
        
        PostManager.shared.uploadPost(image: image, caption: caption) {
            self.delegate?.loadRecentPost()
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: -
    
    @IBAction func cancelButtonDidTap(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func imageButtonDidTap(_ sender: UIButton) {
        showPicker()
    }
    
    private func hideButtons() {
        cancelButton.tintColor = .clear
        shareButton.tintColor = .clear
        imageButton.isHidden = true
        captionTextView.isHidden = true
    }
    
    private func showButtons() {
        cancelButton.tintColor = .label
        shareButton.tintColor = .systemBlue
        imageButton.isHidden = false
        captionTextView.isHidden = false
    }
    
    // MARK: - Show next Controller
    
    func showNextController() {
        if let nextC = self.storyboard?.instantiateViewController(identifier: "SubmitPostTVC") {
            nextC.modalTransitionStyle = .crossDissolve
            present(nextC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Configuration
    @objc func showPicker() {
        var config = YPImagePickerConfiguration()
        
        /* Set this to true if you want to force the  library output to be a squared image. Defaults to false */
        //         config.library.onlySquare = true
        /* Set this to true if you want to force the camera output to be a squared image. Defaults to true */
        // config.onlySquareImagesFromCamera = false
        /* Ex: cappedTo:1024 will make sure images from the library or the camera will be
         resized to fit in a 1024x1024 box. Defaults to original image size. */
        config.targetImageSize = .cappedTo(size: 1024)
        /* Choose what media types are available in the library. Defaults to `.photo` */
        config.library.mediaType = .photo
        config.library.itemOverlayType = .grid
        /* Enables selecting the front camera by default, useful for avatars. Defaults to false */
        // config.usesFrontCamera = true
        /* Adds a Filter step in the photo taking process. Defaults to true */
        // config.showsFilters = false
        /* Manage filters by yourself */
        //        config.filters = [YPFilter(name: "Mono", coreImageFilterName: "CIPhotoEffectMono"),
        //                          YPFilter(name: "Normal", coreImageFilterName: "")]
        //        config.filters.remove(at: 1)
        //        config.filters.insert(YPFilter(name: "Blur", coreImageFilterName: "CIBoxBlur"), at: 1)
        /* Enables you to opt out from saving new (or old but filtered) images to the
         user's photo library. Defaults to true. */
        config.shouldSaveNewPicturesToAlbum = true
        
        /* Choose the videoCompression. Defaults to AVAssetExportPresetHighestQuality */
        config.video.compression = AVAssetExportPresetMediumQuality
        
        /* Defines the name of the album when saving pictures in the user's photo library.
         In general that would be your App name. Defaults to "DefaultYPImagePickerAlbumName" */
        // config.albumName = "ThisIsMyAlbum"
        /* Defines which screen is shown at launch. Video mode will only work if `showsVideo = true`.
         Default value is `.photo` */
        config.startOnScreen = .library
        
        /* Defines which screens are shown at launch, and their order.
         Default value is `[.library, .photo]` */
        config.screens = [.library, .photo]
        
        /* Can forbid the items with very big height with this property */
        //        config.library.minWidthForItem = UIScreen.main.bounds.width * 0.8
        /* Defines the time limit for recording videos.
         Default is 30 seconds. */
        config.video.recordingTimeLimit = 15.0
        /* Defines the time limit for videos from the library.
         Defaults to 60 seconds. */
        config.video.libraryTimeLimit = 15.0
        
        /* Adds a Crop step in the photo taking process, after filters. Defaults to .none */
//        config.showsCrop = .rectangle(ratio: (16/9))
//        config.showsCrop = .rectangle(ratio: 1)
        config.showsCrop = .none
        
        /* Defines the overlay view for the camera. Defaults to UIView(). */
        // let overlayView = UIView()
        // overlayView.backgroundColor = .red
        // overlayView.alpha = 0.3
        // config.overlayView = overlayView
        /* Customize wordings */
        config.wordings.libraryTitle = "Library"
        
        /* Defines if the status bar should be hidden when showing the picker. Default is true */
        config.hidesStatusBar = false
        
        /* Defines if the bottom bar should be hidden when showing the picker. Default is false */
        config.hidesBottomBar = false

        config.maxCameraZoomFactor = 3.0
        config.library.maxNumberOfItems = 1
        config.gallery.hidesRemoveButton = false
        
        /* Disable scroll to change between mode */
        // config.isScrollToChangeModesEnabled = false
        //        config.library.minNumberOfItems = 2
        /* Skip selection gallery after multiple selections */
        // config.library.skipSelectionsGallery = true
        /* Here we use a per picker configuration. Configuration is always shared.
         That means than when you create one picker with configuration, than you can create other picker with just
         let picker = YPImagePicker() and the configuration will be the same as the first picker. */
        
        /* Only show library pictures from the last 3 days */
        //let threDaysTimeInterval: TimeInterval = 3 * 60 * 60 * 24
        //let fromDate = Date().addingTimeInterval(-threDaysTimeInterval)
        //let toDate = Date()
        //let options = PHFetchOptions()
        // options.predicate = NSPredicate(format: "creationDate > %@ && creationDate < %@", fromDate as CVarArg, toDate as CVarArg)
        //
        //Just a way to set order
        //let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        //options.sortDescriptors = [sortDescriptor]
        //
        //config.library.options = options
        config.library.preselectedItems = selectedItems
        
        // Customise fonts
        //config.fonts.menuItemFont = UIFont.systemFont(ofSize: 22.0, weight: .semibold)
        //config.fonts.pickerTitleFont = UIFont.systemFont(ofSize: 22.0, weight: .black)
        //config.fonts.rightBarButtonFont = UIFont.systemFont(ofSize: 22.0, weight: .bold)
        //config.fonts.navigationBarTitleFont = UIFont.systemFont(ofSize: 22.0, weight: .heavy)
        //config.fonts.leftBarButtonFont = UIFont.systemFont(ofSize: 22.0, weight: .heavy)
        let picker = YPImagePicker(configuration: config)
        
        picker.imagePickerDelegate = self
        
        /* Change configuration directly */
        // YPImagePickerConfiguration.shared.wordings.libraryTitle = "Gallery2"
        
        // MARK: - Multiple media implementation
        
//        picker.didFinishPicking { [unowned picker] items, cancelled in
//
//            if cancelled {
//                print("Picker was canceled")
//                picker.dismiss(animated: true, completion: nil)
//                self.navigationController?.popViewController(animated: false)
//                return
//            }
//            _ = items.map { print("🧀 \($0)") }
//
//            self.selectedItems = items
//            if let firstItem = items.first {
//                switch firstItem {
//
//                case .photo(let photo):
//                    self.selectedImageV.image = photo.image
//                    picker.dismiss(animated: true, completion: nil)
//                    self.navigationController?.popViewController(animated: false)
//
//                case .video(let video):
//                    self.selectedImageV.image = video.thumbnail
//
//                    let assetURL = video.url
//                    let playerVC = AVPlayerViewController()
//                    let player = AVPlayer(playerItem: AVPlayerItem(url: assetURL))
//                    playerVC.player = player
//
//                    picker.dismiss(animated: true, completion: { [weak self] in
//                        self?.present(playerVC, animated: true, completion: nil)
//                        self?.navigationController?.popViewController(animated: false)
//                        print("😀 \(String(describing: self?.resolutionForLocalVideo(url: assetURL)!))")
//                    })
//                }
//            }
//        }
        
        // MARK: - Single Photo implementation
        
//        picker.didFinishPicking { [unowned picker] items, _ in
//            self.selectedItems = items
//            self.selectedImageV.image = items.singlePhoto?.image
//            picker.dismiss(animated: true, completion: nil)
//        }
        
        // MARK: didFinishPicking
        
        picker.didFinishPicking { [unowned picker] items, cancelled in
            
            if cancelled {
                print("Picker was canceled")
                self.hideButtons()
                picker.dismiss(animated: true, completion: nil)
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            self.selectedItems = items
            self.imageButton.setImage(items.singlePhoto?.image, for: .normal)
            
            self.showButtons()
            
            picker.dismiss(animated: true, completion: nil)
        }
        
        /* Single Video implementation. */
        //picker.didFinishPicking { [unowned picker] items, cancelled in
        //    if cancelled { picker.dismiss(animated: true, completion: nil); return }
        //
        //    self.selectedItems = items
        //    self.selectedImageV.image = items.singleVideo?.thumbnail
        //
        //    let assetURL = items.singleVideo!.url
        //    let playerVC = AVPlayerViewController()
        //    let player = AVPlayer(playerItem: AVPlayerItem(url:assetURL))
        //    playerVC.player = player
        //
        //    picker.dismiss(animated: true, completion: { [weak self] in
        //        self?.present(playerVC, animated: true, completion: nil)
        //        print("\(String(describing: self?.resolutionForLocalVideo(url: assetURL)!))")
        //    })
        //}
        present(picker, animated: true, completion: nil)
    }
}

// Support methods
extension CameraViewController {
    
    // MARK: - Observe Posts
    
    func observePosts() {
        let ref = PostManager.shared.postDbRef
        ref.observeSingleEvent(of: .value) { (snapshot) in
            
            print("------ Total number of posts: \(snapshot.childrenCount) ------")
            
            guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else {
                print("------ There's no post. ------")
                return
            }
            
            for item in allObjects {
                let postInfo = item.value as? [String: Any] ?? [:]
                
                print("-------")
                print("Post ID: \(item.key)")
                print("userId: \(postInfo["userId"] ?? "")")
                print("username: \(postInfo["username"] ?? "")")
                print("Image URL: \(postInfo["imageFileURL"] ?? "")")
                print("userDidLike: \(postInfo["userDidLike"] ?? "")")
                print("caption: \(postInfo["caption"] ?? "")")
                print("Timestamp: \(postInfo["timestamp"] ?? "")")
            }
        }
    }
    
    // MARK: - Default
    
    /* Gives a resolution for the video by URL */
    func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
}

// YPImagePickerDelegate
extension CameraViewController: YPImagePickerDelegate {
    func noPhotos() {}
    
    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
        return true // indexPath.row != 2
    }
}

// MARK: - Characters limit

extension CameraViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // get the current text, or use an empty string if that failed
        let currentText = textView.text ?? ""
        
        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        // add their new text to the existing text
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        // make sure the result is under __ characters
        return updatedText.count <= 500
    }
}
