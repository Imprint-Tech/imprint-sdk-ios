//
//  ViewController.swift
//  Example
//
//  Created by Wanting Shao on 10/7/24.
//

import UIKit
import Imprint

class ViewController: UIViewController {

  @IBOutlet weak var tokenInput: UITextView!
  @IBOutlet weak var environmentSelector: UISegmentedControl!
  @IBOutlet weak var completionState: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupLayout()
    environmentSelector.selectedSegmentIndex = 1
    
    // Prefill your token if needed
    tokenInput.text = ""
  }

  @IBAction func startTapped(_ sender: Any) {
    let token = tokenInput.text ?? ""
    let environment = ImprintConfiguration.Environment(rawValue: environmentSelector.selectedSegmentIndex) ?? .staging
    
    let configuration = ImprintConfiguration(token: token, environment: environment)
    
    // Optional fields
    configuration.externalReferenceId = "YOUR_CUSTOMER_ID"
    configuration.applicationId = "IMPRINT_GENERATED_GUID"
    configuration.additionalData = ["other": "value"]
    
    configuration.onCompletion = { state, metadata in
      switch state {
      case .offerAccepted:
        self.completionState.text = "Offer accepted\n\(self.jsonString(metadata))"
      case .rejected:
        self.completionState.text = "Application rejected\n\(self.jsonString(metadata))"
      case .abandoned:
        self.completionState.text = "Application abandoned"
      @unknown default:
        break
      }
    }
    
    ImprintApp.startApplication(from: self, configuration: configuration)
  }
  
  private func setupLayout(){
    tokenInput.layer.borderWidth = 1
    tokenInput.layer.borderColor = UIColor.secondaryLabel.cgColor
    tokenInput.layer.cornerRadius = 6
    
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

