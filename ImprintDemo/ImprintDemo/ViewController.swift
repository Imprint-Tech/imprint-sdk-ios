//
//  ViewController.swift
//  Example
//
//  Created by Wanting Shao on 10/7/24.
//

import UIKit
import Imprint

class ViewController: UIViewController {

  @IBOutlet weak var completionStateLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

  @IBAction func startTapped(_ sender: Any) {
    let configuration = ImprintConfiguration(sessionToken: "GENERATE_IN_POST_AUTH", environment: .staging)
    // Optional fields
    configuration.externalReferenceId = "YOUR_CUSTOMER_ID"
    configuration.applicationId = "IMPRINT_GENERATED_GUID"
    configuration.additionalData = ["other": "value"]
    
    configuration.onCompletion = { state, metadata in
      switch state {
      case .offerAccepted:
        self.completionStateLabel.text = "Offer accepted\n\(String(describing: metadata))"
      case .rejected:
        self.completionStateLabel.text = "Application rejected\n\(String(describing: metadata))"
      case .abandoned:
        self.completionStateLabel.text = "Application abanddoned"
      }
    }
    
    ImprintApp.startApplication(from: self, configuration: configuration)
  }
  
}

