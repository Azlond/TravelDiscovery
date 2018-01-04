//
//  EmailSignUpViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 22.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class EmailSignUpViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var reenterPasswordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextField.delegate = self
        passwordTextField.delegate = self
        reenterPasswordField.delegate = self
        self.hideKeyboardWhenTappedAround()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /**
     * cancel the signupView, go back to LoginView
     */
    @IBAction func cancelButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    /**
     * Create account button clicked - same effect as if pressed 'go' on keyboard
     */
    @IBAction func createAccountButtonTapped(_ sender: UIBarButtonItem) {
        createAccount()
    }
    
    /**
     * Notifies the user that a verification email has been sent - or that an error happened.
     */
    func sendEmail() {
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
            if error != nil {
                print("Error: \(error!.localizedDescription)")
                return
            }
            Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
                if error != nil {
                    let emailNOTSendAlert = UIAlertController(title: "Email Verification", message: "Verification email failed to send: \(error?.localizedDescription ?? "Something went wrong. Sorry.")", preferredStyle: .alert)
                    emailNOTSendAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                        do {
                            try Auth.auth().signOut()
                        } catch {
                            //Error handling
                        }
                    }))
                    self.present(emailNOTSendAlert, animated: true, completion: nil)
                } else {
                    let emailSentAlert = UIAlertController(title: "Email Verification", message: "Verification email has been sent. Please tap on the link in the email to verify your account before you can use the features in the app.", preferredStyle: .alert)
                    emailSentAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                        do {
                            try Auth.auth().signOut()
                        } catch {
                            //Error handling
                        }
                        self.dismiss(animated: true, completion: nil)
                    }))
                    self.present(emailSentAlert, animated: true, completion: nil)
                }
            })
        })
    }
    
    /**
     * Notify the user if an error happened while creating an account
     * Otherwise, go to sendEmail and dismiss SignUpView, go back to loginView
     */
    func createAccount() {
        if reenterPasswordField.text == passwordTextField.text {
            Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
                if error != nil {
                    let signuperrorAlert = UIAlertController(title: "Signup error", message: "\(error?.localizedDescription ?? "Something went wrong. Sorry.") Please try again", preferredStyle: .alert)
                    signuperrorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(signuperrorAlert, animated: true, completion: nil)
                    return
                }
                self.sendEmail()
            })
        } else {
            let passwordNotMatchingAlert = UIAlertController(title: "Oops!", message: "Your passwords do not match. Please enter your password again.", preferredStyle: .alert)
            passwordNotMatchingAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.passwordTextField.text = ""
                self.reenterPasswordField.text = ""
            }))
            self.present(passwordNotMatchingAlert, animated: true, completion: nil)
        }
    }
    
    /**
     * handle textFieldReturn events
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            reenterPasswordField.becomeFirstResponder()
        } else if textField == reenterPasswordField {
            self.view.endEditing(true)
            createAccount()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
