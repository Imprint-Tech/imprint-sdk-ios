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
    static let eventName = "eventName"
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
        } else if let event = body[Constants.eventName] as? String,
                  let data = body[Constants.data] as? ImprintConfiguration.CompletionData {
          switch event {
          case "OFFER_ACCEPTED":
            viewModel.updateCompletionState(.offerAccepted, data: data)
          case "REJECTED":
            viewModel.updateCompletionState(.rejected, data: data)
          case "ERROR":
            viewModel.updateCompletionState(.error, data: data)
          case "ABANDONED":
            viewModel.updateCompletionState(.abandoned, data: data)
          default:
            break
          }
        }
      }
    }
  }
}
