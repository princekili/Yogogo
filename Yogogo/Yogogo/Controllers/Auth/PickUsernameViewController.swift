//
//  PickUsernameViewController.swift
//  Yogogo
//
//  Created by prince on 2020/12/8.
//

import UIKit

class PickUsernameViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField! {
        didSet {
//            if usernameTextField.text == nil || usernameTextField.text == "" {
//                nextButton.isEnabled = false
//                nextButton.backgroundColor = UIColor().hexStringToUIColor(hex: "76D6FF")
//            } else {
//                nextButton.isEnabled = true
//                nextButton.backgroundColor = .systemBlue
//            }
        }
    }
    
    @IBOutlet weak var alertLabel: UILabel! {
        didSet {
            alertLabel.isHidden = true
        }
    }
    
    @IBOutlet weak var nextButton: CustomButton!
    
    let authManager = AuthManager.shared
    
    var isAvailable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenDidTapAround()
        setupButton()
        usernameTextField.delegate = self
    }

    @IBAction func nextButtonDidTap(_ sender: CustomButton) {
        // MARK: - For test
        isAvailable = true
        // MARK: -
        
        // Check Username
//        checkUsername()
        guard isAvailable else { return }
        
        // Save Username
        guard let username = usernameTextField.text else { return }
        UserDefaults.standard.setValue(username, forKey: "username")
        
        // Show next page
        showNextVC()
    }
 
    private func checkUsername() {
        
        guard let username = usernameTextField.text else { return }
        
        authManager.checkUsername(username: username, completion: { (hasBeenUsed) in
            
            if hasBeenUsed! {
                self.alertLabel.text = "The username \(username) is not available."
                self.alertLabel.isHidden = false
                self.redTextField()
                self.isAvailable = false
                return
            } else {
                self.alertLabel.isHidden = true
            }
        })
        
        guard username != "fuck" else {
            self.alertLabel.text = "The username \(username) is not available."
            self.alertLabel.isHidden = false
            self.redTextField()
            self.isAvailable = false
            return
        }
        
        self.isAvailable = true
    }
    
    private func showNextVC() {
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: StoryboardId.pickProfilePhotoVC.rawValue) as? PickProfilePhotoViewController else { return }
        nextVC.modalPresentationStyle = .fullScreen
        present(nextVC, animated: true, completion: nil)
    }
    
    private func redTextField() {
        usernameTextField.layer.borderWidth = 1
        usernameTextField.layer.borderColor = UIColor.red.cgColor
    }
    
    private func setupButton() {
        if usernameTextField.text == nil || usernameTextField.text == "" {
            nextButton.isEnabled = false
            nextButton.backgroundColor = UIColor().hexStringToUIColor(hex: "76D6FF")
        } else {
            nextButton.isEnabled = true
            nextButton.backgroundColor = .systemBlue
        }
    }
}

extension PickUsernameViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        setupButton()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        setupButton()
    }
}
