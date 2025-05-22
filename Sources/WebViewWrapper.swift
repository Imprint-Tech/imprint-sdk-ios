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
    // Enable webView open new window
    webView.uiDelegate = context.coordinator
    webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
    
    webView.configuration.userContentController.add(context.coordinator, name: Constants.callbackHandlerName)
    let request = URLRequest(url: viewModel.webUrl)
    webView.load(request)
    
    return webView
  }
  
  func updateUIView(_ uiView: WKWebView, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(viewModel: viewModel)
  }
  
  class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
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
          let processedData = processCompletionData(eventData)
          viewModel.processState = state
          switch state {
          case .offerAccepted:
            viewModel.updateCompletionState(.offerAccepted, data: processedData)
          case .rejected:
            viewModel.updateCompletionState(.rejected, data: processedData)
          case .error:
            viewModel.updateCompletionState(.error, data: processErrorData(processedData))
          case .closed: // no action needed, still presist previous external terminal state
            break
          default:
            viewModel.updateCompletionState(.inProgress, data: processedData)
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
    
    // Helper method to only expose neccessary fields for partners
    private func processCompletionData(_ data: ImprintConfiguration.CompletionData) -> ImprintConfiguration.CompletionData {
      var processedData: ImprintConfiguration.CompletionData = [:]

      let disallowedKeys: Set<String> = [
        "source",
        "event_name"
      ]

      for (key, value) in data where !disallowedKeys.contains(key) {
        processedData[key] = value
      }

      return processedData
    }
    
    // Delegate method for webView to open external links
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      if navigationAction.navigationType == .linkActivated {
        if let url = navigationAction.request.url,
           UIApplication.shared.canOpenURL(url) {
          UIApplication.shared.open(url)
          decisionHandler(.cancel)
          return
        }
      }
      decisionHandler(.allow)
    }
    
    // Delegate method for webView to open new window
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
      if let url = navigationAction.request.url {
        UIApplication.shared.open(url)
      }
      return nil
    }
  }
}
