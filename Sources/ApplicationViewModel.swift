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
  
  @Published var logoUrl: URL?
  @Published var completionState: ImprintConfiguration.CompletionState = .abandoned
  var completionData: ImprintConfiguration.CompletionData?
  
  init(configuration: ImprintConfiguration) {
    var host = ""
    switch configuration.environment {
    case .staging:
      host = "https://apply.stg.imprintapi.co"
    case .sandbox:
      host = "https://apply.sbx.imprint.co"
    case .production:
      host = "https://apply.imprint.co"
    }
    
    let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
    
    var url = "\(host)/start?client_secret=\(configuration.clientSecret)&device-id=\(deviceId)&partner_reference=\(configuration.partnerReference)"
    
    self.webUrl = URL(string: url)!
    self.configuration = configuration
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
  
  func onDismiss() {
    configuration.onCompletion?(completionState, completionData)
  }
}
