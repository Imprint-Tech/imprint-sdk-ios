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
    environmentSelector.selectedSegmentIndex = 0
    
    // Prefill your token if needed
    clientSecretInput.text = ""
#if DEBUG
    if let testSecret = ProcessInfo.processInfo.environment["IMPRINT_TEST_CLIENT_SECRET"] {
      clientSecretInput.text = testSecret
      DispatchQueue.main.async { self.startTapped(self) }
    }
#endif
  }

  @IBAction func startTapped(_ sender: Any) {
    let clientSecret = clientSecretInput.text ?? ""
    let environment = ImprintConfiguration.Environment(rawValue: environmentSelector.selectedSegmentIndex) ?? .staging
    
    let configuration = ImprintConfiguration(clientSecret: clientSecret, environment: environment)
    completionState.text = ""
    configuration.onEvent = { [weak self] eventName, data in
      let tier = data?["tier"] as? String ?? "legacy"
      self?.appendResult("event: \(eventName) [\(tier)]")
    }
    
    configuration.onCompletion = { [weak self] state, data in
      guard let self else { return }
      switch state {
      case .offerAccepted:
        self.appendResult("completion: Offer accepted\n\(self.jsonString(data))")
      case .rejected:
        self.appendResult("completion: Application rejected\n\(self.jsonString(data))")
      case .inProgress:
        self.appendResult("completion: Application Interrupted - In Progress")
      case .error:
        self.appendResult("completion: Error occurred\n\(self.jsonString(data))")
      @unknown default:
        break
      }
    }
    
    ImprintApp.startApplication(from: self, configuration: configuration)
  }

  private func appendResult(_ result: String) {
    let current = completionState.text ?? ""
    completionState.text = current.isEmpty ? result : "\(current)\n\(result)"
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
  private func jsonString(_ dictionary: ImprintConfiguration.CompletionData?) -> String {
    guard let dictionary else { return "nil" }

    func sanitize(_ value: Any) -> Any? {
      switch value {
      case is NSNull:
        return nil
      case let dict as [String: Any]:
        return sanitizeDictionary(dict)
      case let array as [Any]:
        return array.compactMap(sanitize)
      case is String, is Int, is Double, is Bool:
        return value
      default:
        return String(describing: value) // fallback for enums, etc.
      }
    }

    func sanitizeDictionary(_ dict: [String: Any]) -> [String: Any] {
      var sanitized: [String: Any] = [:]
      for (key, value) in dict {
        if let safeValue = sanitize(value) {
          sanitized[key] = safeValue
        }
      }
      return sanitized
    }

    let sanitized = sanitizeDictionary(dictionary.compactMapValues { $0 })

    if let data = try? JSONSerialization.data(withJSONObject: sanitized, options: .prettyPrinted),
       let jsonString = String(data: data, encoding: .utf8) {
      return jsonString
    } else {
      return String(describing: dictionary)
    }
  }
}
