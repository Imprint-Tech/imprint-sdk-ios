// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// Core functionality for interacting with Imprint.
public enum ImprintApp {
  
  /// Starts the application process with the specified configuration.
  /// - Parameters:
  ///   - viewController: The view controller from which the application process will be presented.
  ///   - configuration: The configuration settings for the application process.
  public static func startApplication(from viewController: UIViewController, configuration: ImprintConfiguration) {
    let viewModel = ApplicationViewModel(configuration: configuration)
    let applicationView = ApplicationView(viewModel: viewModel)
    let hostingController = UIHostingController(rootView: applicationView)
    hostingController.isModalInPresentation = true
    viewController.present(hostingController, animated: true)
  }
}

/// Configuration settings for the Imprint application process.
public class ImprintConfiguration {
  
  /// The clientSecret used to initiate the application session.
  /// - Note: This clientSecret is generated through the Post Auth endpoint.
  ///   Please refer to the API documentation (https://docs.imprint.co/api-reference/customer-sessions/create-a-new-customer-session) for details on obtaining a clientSecret.
  let clientSecret: String
  
  /// The partnerReference will allow the web-app to know which partner is initializing the application.
  let partnerReference: String
  
  /// The environment for the application process, with a default value of `.production`.
  let environment: Environment
  
  /// A closure that handles the terminal state of the application process.
  /// - Parameters:
  ///   - state: The final state of the application flow.
  ///   - data: A dictionary that may contain additional data.
  /// - Note: The `state` parameter can have the following values:
  ///   - `offerAccepted`: Triggered when the applicant has been approved and accepted their credit offer — they are now a new cardholder!
  ///   - `rejected`: Triggered when the applicant has been rejected by Imprint.
  ///   - `abandoned`: Triggered when the flow is abandoned before completing.
  ///   - `error`: Triggered when an error occurs during embedded sign up application flow.
  public var onCompletion: ((CompletionState, CompletionData?) -> Void)?

  /// Initializes a new configuration with the specified clientSecret, partnerReference and environment.
  /// - Parameters:
  ///   - clientSecret: The clientSecret to initiate the application session.
  ///   - partnerReference: The unique reference identifier for the partner.
  ///   - environment: The environment to be used, defaulting to `.production`.
  public init(clientSecret: String, partnerReference: String, environment: Environment = .production) {
    self.clientSecret = clientSecret
    self.partnerReference = partnerReference
    self.environment = environment
  }
  
  /// Available environments for the application process.
  public enum Environment: Int {
    case staging
    case sandbox
    case production
  }

  /// Data dictionary passed to the completion handler, containing flexible key-value pairs.
  /// Common keys may include:
  /// - Note: Other keys may be provided; contact your Imprint team for details.
  ///   - `customer_id` (String | nil): Imprint identifier for customer
  ///   - `payment_method_id` (String | nil): Identifier to the payment method of customer in current webflow session
  ///   - `partner_customer_id` (String | nil): Partner identifier for customer
  ///   - `error_code` (String | nil): Identifier for the specific issue encountered.

  public typealias CompletionData = [String: Any?]
  
  /// Terminal states for the application process.
  public enum CompletionState: Int {
    case offerAccepted
    case rejected
    case abandoned
    case error
  }
}
