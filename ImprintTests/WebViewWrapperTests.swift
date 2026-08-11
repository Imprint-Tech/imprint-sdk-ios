//
//  WebViewWrapperTests.swift
//  ImprintTests
//
//  Created by Xingtan Hu on 2/14/25.
//

import XCTest
import WebKit
@testable import Imprint

class WebViewWrapperTests: XCTestCase {
  
  var viewModel: ApplicationViewModel!
  var coordinator: WebViewWrapper.Coordinator!
  
  override func setUp() {
    super.setUp()
    viewModel = ApplicationViewModel(configuration: ImprintConfiguration(clientSecret: "testSecret"))
    coordinator = WebViewWrapper.Coordinator(viewModel: viewModel)
  }
  
  override func tearDown() {
    viewModel = nil
    coordinator = nil
    super.tearDown()
  }
  
  func testOfferAcceptedMessage() {
    // Arrange
    let messageBody: [String: Any] = [
      "event_name": "OFFER_ACCEPTED",
      "customer_id": "consumer-123",
      "applicationId": "app-456",
      "partner_customer_id": "partner-ref-789",
      "payment_method_id": "account-321"
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    
    // Assert
    XCTAssertEqual(viewModel.completionState, .offerAccepted)
    XCTAssertEqual(viewModel.completionData?["customer_id"] as? String, "consumer-123")
    XCTAssertEqual(viewModel.completionData?["applicationId"] as? String, "app-456")
    XCTAssertEqual(viewModel.completionData?["partner_customer_id"] as? String, "partner-ref-789")
    XCTAssertEqual(viewModel.completionData?["payment_method_id"] as? String, "account-321")
  }
  
  func testSDKv02HappyPath() {
    // Arrange
    let messageBody: [String: Any] = [
      "event_name": "OFFER_ACCEPTED",
      "customer_id": "consumer-123",
      "partner_customer_id": "partner-ref-789",
      "payment_method_id": "account-321"
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    let messageBody2: [String: Any] = [
      "event_name": "CLOSED",
      "customer_id": "",
      "partner_customer_id": "",
      "payment_method_id": "",
    ]
    let message2 = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody2)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    coordinator.userContentController(WKUserContentController(), didReceive: message2)
    
    // Assert
    XCTAssertEqual(viewModel.completionState, .offerAccepted)
    XCTAssertEqual(viewModel.completionData?["customer_id"] as? String, "consumer-123")
    XCTAssertEqual(viewModel.completionData?["partner_customer_id"] as? String, "partner-ref-789")
    XCTAssertEqual(viewModel.completionData?["payment_method_id"] as? String, "account-321")
  }
  
  func testRejectedMessage() {
    // Arrange
    let messageBody: [String: Any] = [
      "event_name": "REJECTED",
      "error_code": "invalidToken"
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    
    // Assert
    XCTAssertEqual(viewModel.completionState, .rejected)
    XCTAssertEqual(viewModel.completionData?["error_code"] as? String, "invalidToken")
  }
  
  func testErrorMessage() {
    // Arrange
    let messageBody: [String: Any] = [
      "event_name": "ERROR",
      "error_code": "INVALID_CLIENT_SECRET",
      "error_message": "The client secret provided is invalid"
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    
    // Assert
    XCTAssertEqual(viewModel.completionState, .error)
    XCTAssertEqual(viewModel.completionData?["error_code"] as? ImprintConfiguration.ErrorCode, .invalidClientSecret)
  }
  
  func testAdditionalDataFields() {
    // Arrange
    let messageBody: [String: Any] = [
      "event_name": "OFFER_ACCEPTED",
      "customer_id": "customer-xyz",
      "payment_method_id": "payment-abc",
      "partner_customer_id": "partner-987"
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    
    // Assert
    XCTAssertEqual(viewModel.completionData?["customer_id"] as? String, "customer-xyz")
    XCTAssertEqual(viewModel.completionData?["payment_method_id"] as? String, "payment-abc")
    XCTAssertEqual(viewModel.completionData?["partner_customer_id"] as? String, "partner-987")
  }
  
  func testNullableDataFields() {
    // Arrange
    let messageBody: [String: Any] = [
      "event_name": "OFFER_ACCEPTED",
      "data": [
        "customer_id": nil,
        "payment_method_id": nil,
        "partner_customer_id": nil
      ]
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    
    // Assert
    XCTAssertEqual(viewModel.completionData?["customer_id"] as? String, nil)
    XCTAssertEqual(viewModel.completionData?["payment_method_id"] as? String, nil)
    XCTAssertEqual(viewModel.completionData?["partner_customer_id"] as? String, nil)
  }
  
  func testInvalidMessageIgnored() {
    // Arrange
    let messageBody: [String: Any] = [
      "invalidKey": "SomeValue"
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    
    // Assert
    XCTAssertEqual(viewModel.completionState, .inProgress)
  }
  
  func testLogoUrlMessage() {
    // Arrange
    let messageBody: [String: Any] = [
      "logoUrl": "https://example.com/logo.png"
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    
    // Assert
    XCTAssertEqual(viewModel.logoUrl?.absoluteString, "https://example.com/logo.png")
  }

  func testNativeAddToWalletButtonHitReportsSuccessToWebApplicationOnce() {
    var receivedData: ImprintConfiguration.CompletionData?
    var provisioningCompletion: ((ImprintConfiguration.NativeAddToWalletResult) -> Void)?
    let configuration = ImprintConfiguration(clientSecret: "testSecret")
    configuration.onNativeAppleWalletProvisioning = { data, completion in
      receivedData = data
      provisioningCompletion = completion
    }
    viewModel = ApplicationViewModel(configuration: configuration)
    coordinator = WebViewWrapper.Coordinator(viewModel: viewModel)

    let resultReported = expectation(description: "Native wallet result reported")
    resultReported.assertForOverFulfill = true
    var evaluatedScripts: [String] = []
    coordinator.evaluateJavaScript = { script in
      evaluatedScripts.append(script)
      resultReported.fulfill()
    }
    let messageBody: [String: Any] = [
      "source": "imprint_web_app",
      "event_name": "NATIVE_ADD_TO_WALLET_BUTTON_HIT",
      "customer_id": "consumer-123",
      "payment_method_id": "payment-456",
      "type": "apple_wallet"
    ]
    let message = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: messageBody
    )

    coordinator.userContentController(WKUserContentController(), didReceive: message)

    XCTAssertEqual(receivedData?["customer_id"] as? String, "consumer-123")
    XCTAssertEqual(receivedData?["payment_method_id"] as? String, "payment-456")
    XCTAssertEqual(receivedData?["type"] as? String, "apple_wallet")
    XCTAssertNotNil(provisioningCompletion)
    XCTAssertTrue(evaluatedScripts.isEmpty)

    provisioningCompletion?(.succeeded)
    provisioningCompletion?(.cancelled)
    wait(for: [resultReported], timeout: 1)

    XCTAssertEqual(
      evaluatedScripts,
      ["window.dispatchEvent(new CustomEvent('nativeAddToWalletCompleted', { detail: { result: 'succeeded' } }));"]
    )
  }

  func testNativeAddToWalletButtonHitCanReportCancellation() {
    var provisioningCompletion: ((ImprintConfiguration.NativeAddToWalletResult) -> Void)?
    let configuration = ImprintConfiguration(clientSecret: "testSecret")
    configuration.onNativeAppleWalletProvisioning = { _, completion in
      provisioningCompletion = completion
    }
    viewModel = ApplicationViewModel(configuration: configuration)
    coordinator = WebViewWrapper.Coordinator(viewModel: viewModel)

    let resultReported = expectation(description: "Cancellation reported")
    coordinator.evaluateJavaScript = { script in
      XCTAssertEqual(
        script,
        "window.dispatchEvent(new CustomEvent('nativeAddToWalletCompleted', { detail: { result: 'cancelled' } }));"
      )
      resultReported.fulfill()
    }
    let message = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: [
        "event_name": "NATIVE_ADD_TO_WALLET_BUTTON_HIT",
        "payment_method_id": "payment-456",
        "type": "apple_wallet"
      ]
    )

    coordinator.userContentController(WKUserContentController(), didReceive: message)
    provisioningCompletion?(.cancelled)

    wait(for: [resultReported], timeout: 1)
  }

  func testNativeAddToWalletButtonHitIsIgnoredWithoutHandler() {
    let messageBody: [String: Any] = [
      "event_name": "NATIVE_ADD_TO_WALLET_BUTTON_HIT",
      "payment_method_id": "payment-456",
      "type": "apple_wallet"
    ]
    let message = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: messageBody
    )
    var evaluatedScript: String?
    coordinator.evaluateJavaScript = { evaluatedScript = $0 }

    coordinator.userContentController(WKUserContentController(), didReceive: message)

    XCTAssertNil(evaluatedScript)
    XCTAssertEqual(viewModel.completionState, .inProgress)
    XCTAssertNil(viewModel.completionData)
  }
}

class MockWKScriptMessage: WKScriptMessage {
  let mockName: String
  let mockBody: Any
  
  init(name: String, body: Any) {
    self.mockName = name
    self.mockBody = body
  }
  
  override var name: String { return mockName }
  override var body: Any { return mockBody }
}
