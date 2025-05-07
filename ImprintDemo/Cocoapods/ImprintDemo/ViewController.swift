//
//  ViewController.swift
//  Example
//
//  Created by Wanting Shao on 10/7/24.
//

import UIKit
import Imprint

class ViewController: UIViewController {

  @IBOutlet weak var clientSecretInput: UITextView!
  @IBOutlet weak var environmentSelector: UISegmentedControl!
  @IBOutlet weak var completionState: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupLayout()
    environmentSelector.selectedSegmentIndex = 1
    
    // Prefill your token if needed
    clientSecretInput.text = ""
  }

  @IBAction func startTapped(_ sender: Any) {
    let clientSecret = clientSecretInput.text ?? ""
    let environment = ImprintConfiguration.Environment(rawValue: environmentSelector.selectedSegmentIndex) ?? .staging
    
    let configuration = ImprintConfiguration(clientSecret: clientSecret, environment: environment)
    
    configuration.onCompletion = { state, data in
      switch state {
      case .offerAccepted:
        self.completionState.text = "Offer accepted\n\(self.jsonString(data))"
      case .rejected:
        self.completionState.text = "Application rejected\n\(self.jsonString(data))"
      case .inProgress:
        self.completionState.text = "Application Interrupted - In Progress"
      case .error:
        self.completionState.text = "Error occured\n\(self.jsonString(data))"
      case .closed:
        break
      @unknown default:
        break
      }
    }
    
    ImprintApp.startApplication(from: self, configuration: configuration)
  }
  
  private func setupLayout(){
    clientSecretInput.layer.borderWidth = 1
    clientSecretInput.layer.borderColor = UIColor.secondaryLabel.cgColor
    clientSecretInput.layer.cornerRadius = 6
    
    completionState.layer.borderWidth = 1
    completionState.layer.borderColor = UIColor.secondaryLabel.cgColor
    completionState.layer.cornerRadius = 6    
  }
  
  // Helper
  private func jsonString(_ dictionary: [String: Any]?) -> String {
    guard let dictionary else { return "nil" }
    if let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted),
       let jsonString = String(data: data, encoding: .utf8) {
      return jsonString
    } else {
      return (String(describing: dictionary))
    }
  }
}

