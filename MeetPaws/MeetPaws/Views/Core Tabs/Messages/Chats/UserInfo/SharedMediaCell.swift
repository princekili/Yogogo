//
//  SharedMediaCell.swift
//  MeetPaws
//
//  Created by prince on 2020/12/20.
//

import UIKit

class SharedMediaCell: UICollectionViewCell {
    
    var sharedMediaVC = SharedMediaVC()
    
    let imageView = UIImageView()
    
    let playButton = UIButton(type: .system)
    
    var message: Messages!
    
    // MARK: -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
        setupPlayButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    private func setupImageView() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTappedHandler(tap:)))
        imageView.addGestureRecognizer(tap)
        let constraints = [
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: -
    
    @objc private func imageTappedHandler(tap: UITapGestureRecognizer) {
        guard message.videoUrl == nil else { return }
        guard let imageView = tap.view as? UIImageView else { return }
        sharedMediaVC.zoomImageHandler(imageView, message)
    }
    
    // MARK: -
    
    private func setupPlayButton() {
        addSubview(playButton)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        let constraints = [
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 35),
            playButton.heightAnchor.constraint(equalToConstant: 35)
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
