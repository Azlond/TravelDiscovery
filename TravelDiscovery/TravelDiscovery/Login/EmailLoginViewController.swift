//
//  EmailLoginViewController.swift
//  TravelDiscovery
//
//  Created by Jan on 22.11.17.
//  Copyright © 2017 Jan. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class EmailLoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var userID = Auth.auth().currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        passwordField.delegate = self
        self.hideKeyboardWhenTappedAround()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func loginButtonTapped(_ sender: UIBarButtonItem) {
        Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!, completion: { (user, error) in
            if error != nil {
                let loginErrorAlert = UIAlertController(title: "Login error!", message: "\(error?.localizedDescription ?? "Something went wrong. Sorry.") Please try again", preferredStyle: .alert)
                loginErrorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(loginErrorAlert, animated: true, completion: nil)
                return
            }
            if user!.isEmailVerified {
                // Take user to Firebase Realtime Database
                self.performSegue(withIdentifier: "emailLoggedIn", sender: self)
            } else {
                let notVerifiedAltert = UIAlertController(title: "Not verified", message: "Your account is pending verification. Please check your email and verify your account.", preferredStyle: .alert)
                notVerifiedAltert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(notVerifiedAltert, animated: true, completion: nil)
                do {
                    try Auth.auth().signOut()
                } catch {
                    // Handle error
                }
            }
        })
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let forgotPasswordAlert = UIAlertController(title: "Forgot Password?", message: "Don't worry. We can reset if for you. Just enter your email address here.", preferredStyle: .alert)
        forgotPasswordAlert.addTextField { (textField) in
            textField.placeholder = "Enter your email address"
        }
        forgotPasswordAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        forgotPasswordAlert.addAction(UIAlertAction(title: "Reset Password", style: .default, handler: { (action) in
            let resetMail = forgotPasswordAlert.textFields?.first?.text
            Auth.auth().sendPasswordReset(withEmail: resetMail!, completion: { (error) in
                if error != nil {
                    let resetFailedAlert = UIAlertController(title: "Reset Failed", message: "Error: \(error?.localizedDescription ?? "Something went wrong. Sorry.")", preferredStyle: .alert)
                    resetFailedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(resetFailedAlert, animated: true, completion: nil)
                } else {
                    let resetEmailSentAlert = UIAlertController(title: "Reset email sent", message: "A password reset email has been sent to your registered email address successfully. Please check your email for further password reset instructions", preferredStyle: .alert)
                    resetEmailSentAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(resetEmailSentAlert, animated: true, completion: nil)
                }
            })
        }))
        self.present(forgotPasswordAlert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
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
