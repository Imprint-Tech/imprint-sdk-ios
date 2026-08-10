//
//  ApplicationViewModel.swift
//
//
//  Created by Wanting Shao on 10/7/24.
//

import SwiftUI

class ApplicationViewModel: ObservableObject {
  let webUrl: URL
  private let configuration: ImprintConfiguration
  private let nativeAppleWalletProvisioningHandler: ImprintConfiguration.NativeAppleWalletProvisioningHandler?
  
  @Published var logoUrl: URL?
  @Published var completionState: ImprintConfiguration.CompletionState = .inProgress
  @Published var processState: ImprintConfiguration.ProcessState?
  var completionData: ImprintConfiguration.CompletionData?
  
  init(configuration: ImprintConfiguration) {
    let nativeAppleWalletProvisioningHandler = configuration.onNativeAppleWalletProvisioning
    var host: String
    if let applicationBaseURL = configuration.applicationBaseURL {
      host = applicationBaseURL.absoluteString.trimmingCharacters(
        in: CharacterSet(charactersIn: "/")
      )
    } else {
      switch configuration.environment {
      case .staging:
        host = "https://apply.stg.imprintapi.co"
      case .sandbox:
        host = "https://apply.sbx.imprint.co"
      case .production:
        host = "https://apply.imprint.co"
      }
    }
    
    let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
    
    var url = "\(host)/start?client_secret=\(configuration.clientSecret)&device-id=\(deviceId)"

    if let offerConfigUUID = configuration.offerConfigUUID {
      url += "&offerConfigUUIDs=\(offerConfigUUID)"
    }

    if nativeAppleWalletProvisioningHandler != nil {
      url += "&nativeAppleWalletProvisioning=true"
    }

    self.webUrl = URL(string: url)!
    self.configuration = configuration
    self.nativeAppleWalletProvisioningHandler = nativeAppleWalletProvisioningHandler
  }
  
  func updateLogoUrl(_ url: URL) {
    self.logoUrl = url
  }
  
  func updateCompletionState(
    _ state: ImprintConfiguration.CompletionState,
    data: ImprintConfiguration.CompletionData?
  ) {
    self.completionState = state
    self.completionData = data
  }

  var hasNativeAppleWalletProvisioningHandler: Bool {
    nativeAppleWalletProvisioningHandler != nil
  }

  func requestNativeAppleWalletProvisioning(
    data: ImprintConfiguration.CompletionData,
    completion: @escaping () -> Void
  ) {
    nativeAppleWalletProvisioningHandler?(data, completion)
  }
  
  func onDismiss() {
    configuration.onCompletion?(completionState, completionData)
  }
}
