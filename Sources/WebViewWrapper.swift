//
//  WebViewWrapper.swift
//
//
//  Created by Wanting Shao on 10/7/24.
//

import SwiftUI
import WebKit

struct WebViewWrapper: UIViewRepresentable {
  enum Constants {
    static let callbackHandlerName = "imprintWebCallback"
    static let logoUrl = "logoUrl"
    static let eventName = "event_name"
    static let errorCode = "error_code"
    static let data = "data"
  }
  
  @ObservedObject var viewModel: ApplicationViewModel
  
  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.navigationDelegate = context.coordinator
    
    webView.configuration.userContentController.add(context.coordinator, name: Constants.callbackHandlerName)
    let request = URLRequest(url: viewModel.webUrl)
    webView.load(request)
    
    return webView
  }
  
  func updateUIView(_ uiView: WKWebView, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(viewModel: viewModel)
  }
  
  class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var viewModel: ApplicationViewModel
    
    init(viewModel: ApplicationViewModel) {
      self.viewModel = viewModel
    }
    
    // Handle messages from the web page
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      if message.name == Constants.callbackHandlerName,
         let body = message.body as? [String: Any] {
        if let logoUrlString = body[Constants.logoUrl] as? String,
           let logoUrl = URL(string: logoUrlString) {
          // load logo on navbar
          viewModel.updateLogoUrl(logoUrl)
          return
        } else if let eventData = body as? ImprintConfiguration.CompletionData,
                  let event = eventData[Constants.eventName] as? String,
                  let state = ImprintConfiguration.ProcessState(rawValue: event){
          viewModel.processState = state
          switch state {
          case .offerAccepted:
            viewModel.updateCompletionState(.offerAccepted, data: eventData)
          case .rejected:
            viewModel.updateCompletionState(.rejected, data: eventData)
          case .error:
            viewModel.updateCompletionState(.error, data: processErrorData(eventData))
          case .imprintClosed: // no action needed, still presist previous internal/external state
            break
          default:
            viewModel.updateCompletionState(.inProgress, data: eventData)
          }
        }
      }
    }
    
    // Helper method to process error data
    private func processErrorData(_ data: ImprintConfiguration.CompletionData) -> ImprintConfiguration.CompletionData {
      var processedData = data
      
      // Convert error_code string to ErrorCode enum if present
      if let errorCodeString = data[Constants.errorCode] as? String {
        let errorCode = ImprintConfiguration.ErrorCode.from(stringValue: errorCodeString)
        processedData[Constants.errorCode] = errorCode
      }
      
      return processedData
    }
  }
}
