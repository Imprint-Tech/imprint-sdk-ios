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
      "consumerId": "consumer-123",
      "applicationId": "app-456",
      "externalReferenceId": "partner-ref-789",
      "accountId": "account-321"
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    
    // Assert
    XCTAssertEqual(viewModel.completionState, .offerAccepted)
    XCTAssertEqual(viewModel.completionData?["consumerId"] as? String, "consumer-123")
    XCTAssertEqual(viewModel.completionData?["applicationId"] as? String, "app-456")
    XCTAssertEqual(viewModel.completionData?["externalReferenceId"] as? String, "partner-ref-789")
    XCTAssertEqual(viewModel.completionData?["accountId"] as? String, "account-321")
  }
  
  func testSDKv02HappyPath() {
    // Arrange
    let messageBody: [String: Any] = [
      "event_name": "OFFER_ACCEPTED",
      "consumerId": "consumer-123",
      "applicationId": "app-456",
      "externalReferenceId": "partner-ref-789",
      "accountId": "account-321"
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    let messageBody2: [String: Any] = [
      "event_name": "CLOSED",
      "consumerId": "",
      "applicationId": "",
      "externalReferenceId": "",
      "accountId": ""
    ]
    let message2 = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody2)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    coordinator.userContentController(WKUserContentController(), didReceive: message2)
    
    // Assert
    XCTAssertEqual(viewModel.completionState, .offerAccepted)
    XCTAssertEqual(viewModel.completionData?["consumerId"] as? String, "consumer-123")
    XCTAssertEqual(viewModel.completionData?["applicationId"] as? String, "app-456")
    XCTAssertEqual(viewModel.completionData?["externalReferenceId"] as? String, "partner-ref-789")
    XCTAssertEqual(viewModel.completionData?["accountId"] as? String, "account-321")
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
  
  func testInProgressMessage() {
    // Test cases for states that map to inProgress
    let inProgressStates = ["INITIATED", "APPLICATION_STARTED", "OFFER_PRESENTED", "APPLICATION_REVIEW", "CREDIT_FROZEN", "CUSTOMER_CLOSED"]
    
    for state in inProgressStates {
      // Arrange
      let messageBody: [String: Any] = [
        "event_name": state,
        "session_id": "session-123"
      ]
      let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
      
      // Act
      coordinator.userContentController(WKUserContentController(), didReceive: message)
      
      // Assert
      XCTAssertEqual(viewModel.completionState, .inProgress, "State \(state) should map to inProgress")
    }
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
