//
//  ToolsMenu.swift
//  MeetPaws
//
//  Created by prince on 2020/12/21.
//
//  When a user presses on a message for a while, this ToolsMenu will appear.

import UIKit

class ToolsMenu: UIScrollView {

    var chatVC: ChatViewController!
    
    var message: Messages!
    
    var selectedCell: ChatCell!
    
    var keyWindow: UIWindow!
    
    var messageFrame: CGRect!
    
    var cellFrame: CGRect!
    
    let blurView = UIVisualEffectView()
    
    var messageView: MessageView!
    
    let toolsView = UIView()
    
    var xValue: CGFloat!
    
    var scrollYValue: CGFloat!
    
    var noScroll: Bool!
    
    // MARK: -
    
    init(_ message: Messages, _ selectedCell: ChatCell, _ chatVC: ChatViewController) {
        super.init(frame: .zero)
        self.chatVC = chatVC
        self.message = message
        self.selectedCell = selectedCell
        keyWindow = UIApplication.shared.windows[0]
        messageFrame = selectedCell.messageBackground.superview?.convert(selectedCell.messageBackground.frame, to: nil)
        cellFrame = chatVC.collectionView.convert(selectedCell.frame, to: chatVC.collectionView.superview)
        setupScrollView()
        setupBlurView()
        prepareMenuFrame()
        setupToolsView()
        setupMessageView()
        toolMessageAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - To Fix
    
    private func prepareMenuFrame() {
        xValue = messageFrame.origin.x
        if !selectedCell.isIncoming, messageFrame.width < 190 {
            xValue = messageFrame.minX - 150
            let width = messageFrame.width
            if  width < 190, width > 120 {
                xValue = messageFrame.origin.x - 90
            }
        }
        scrollYValue = cellFrame.maxY + 8
        noScroll = contentSize.height == chatVC.view.frame.height
        if !noScroll {
            scrollYValue = messageFrame.height
            messageFrame.origin.y = frame.minY - 8
            setContentOffset(CGPoint(x: 0, y: max(contentSize.height - bounds.size.height, 0) ), animated: true)
        }
    }
    
    // MARK: -
    
    private func setupScrollView() {
        keyWindow.addSubview(self)
        frame = chatVC.view.frame
        var sHeight: CGFloat
        backgroundColor = .clear
        if messageFrame.height < chatVC.view.frame.height - 220 {
            sHeight = chatVC.view.frame.height
        } else {
            sHeight = messageFrame.height + 230
        }
        contentSize = CGSize(width: chatVC.view.frame.width, height: sHeight)
    }
    
    // MARK: -
    
    private func setupMessageView() {
        messageView = MessageView(frame: messageFrame, cell: selectedCell, message: message, userName: chatVC.user.fullName)
        addSubview(messageView)
    }
    
    // MARK: -
    
    private func setupBlurView() {
        blurView.effect = UIBlurEffect(style: .dark)
        let size = contentSize
        blurView.frame = CGRect(x: 0, y: -400, width: size.width, height: size.height + 1000)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(blurViewTapped))
        blurView.addGestureRecognizer(tapGesture)
        addSubview(blurView)
    }
    
    // MARK: -
    
    private func setupToolsView() {
        if message.mediaUrl != nil || message.audioUrl != nil {
            toolsView.frame = CGRect(x: xValue, y: scrollYValue, width: 200, height: 150)
        } else {
            toolsView.frame = CGRect(x: xValue, y: scrollYValue, width: 200, height: 200)
        }
        toolsView.backgroundColor = .white
        toolsView.layer.cornerRadius = 16
        toolsView.layer.masksToBounds = true
        addSubview(toolsView)
        toolsView.addSubview(ToolsTB(style: .plain, sView: self))
    }
    
    // MARK: -
    
    private func toolMessageAppearance() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            if self.toolsView.frame.maxY > self.keyWindow.frame.maxY && self.noScroll {
                self.toolsView.frame.origin.y = self.keyWindow.frame.maxY - 220
                self.messageView.frame.origin.y = self.toolsView.frame.minY - self.messageFrame.height - 8
            } else if self.messageView.frame.minY < 100 && self.noScroll {
                self.messageView.frame.origin.y = self.keyWindow.frame.minY + 40
                self.toolsView.frame.origin.y = self.messageView.frame.maxY + 8
            }
        })
    }
    
    // MARK: -
    
    @objc private func blurViewTapped() {
         handleViewDismiss()
    }

    // MARK: -
    
    func handleViewDismiss(isDeleted: Bool? = nil, isReply: Bool? = nil, isForward: Bool? = nil) {
        if isDeleted == nil {
            messageView.removeFromSuperview()
            toolsView.removeFromSuperview()
            chatVC.view.addSubview(toolsView)
            chatVC.view.addSubview(messageView)
            chatVC.view.insertSubview(chatVC.messageContainer, aboveSubview: messageView)
        }
        let width = messageFrame.width
        let height = messageFrame.size.height
        let xValue = messageFrame.origin.x
        let yValue = cellFrame.origin.y
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            if isDeleted == nil {
                self.messageView.frame = CGRect(x: xValue, y: yValue, width: width, height: height)
                self.toolsView.frame = CGRect(x: xValue, y: yValue, width: width, height: height)
                self.toolsView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                self.toolsView.layoutIfNeeded()
                self.toolsView.layer.add(self.animateToolsView(fValue: 1, tValue: 0), forKey: "Changes Opacity")
            }
            self.removeFromSuperview()
        }) { (true) in
            self.chatVC.collectionView.isUserInteractionEnabled = true
            self.chatVC.view.insertSubview(self.chatVC.messageContainer, aboveSubview: self.chatVC.collectionView)
            self.selectedCell.isHidden = false
            self.messageView.removeFromSuperview()
            self.toolsView.removeFromSuperview()
            self.chatVC.collectionView.isLongPress = false
            if isReply != nil {
                self.chatVC.responseButtonPressed(self.message)
            }
            if isForward != nil {
                self.chatVC.forwardButtonPressed(self.message)
            }
        }
    }

    // MARK: -
    
    private func animateToolsView(fValue: CGFloat, tValue: CGFloat) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = fValue
        animation.toValue = tValue
        animation.duration = 0.25
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        return animation
    }
}
