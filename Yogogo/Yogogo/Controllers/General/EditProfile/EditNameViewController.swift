//
//  EditNameViewController.swift
//  Yogogo
//
//  Created by prince on 2020/12/6.
//

import UIKit

class EditNameViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField! {
        didSet {
            nameTextField.text = text
        }
    }
    
    var text: String?
    
    var tapHandler: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func backButtonDidTap(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneButtonDidTap(_ sender: UIBarButtonItem) {
        if let textInput = nameTextField.text {
            tapHandler?(textInput)
            navigationController?.popViewController(animated: true)
        }
    }
}
