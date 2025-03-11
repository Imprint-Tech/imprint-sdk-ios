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
    viewModel = ApplicationViewModel(configuration: ImprintConfiguration(clientSecret: "testSecret", partnerReference: "testRef"))
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
      "eventName": "OFFER_ACCEPTED",
      "data": [
        "consumerId": "consumer-123",
        "applicationId": "app-456",
        "externalReferenceId": "partner-ref-789",
        "accountId": "account-321"
      ]
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
  
  func testRejectedMessage() {
    // Arrange
    let messageBody: [String: Any] = [
      "eventName": "REJECTED",
      "data": ["errorCode": "invalidToken"]
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: message)
    
    // Assert
    XCTAssertEqual(viewModel.completionState, .rejected)
    XCTAssertEqual(viewModel.completionData?["errorCode"] as? String, "invalidToken")
  }
  
  func testAdditionalDataFields() {
    // Arrange
    let messageBody: [String: Any] = [
      "eventName": "OFFER_ACCEPTED",
      "data": [
        "customer_id": "customer-xyz",
        "payment_method_id": "payment-abc",
        "partner_customer_id": "partner-987"
      ]
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
      "eventName": "OFFER_ACCEPTED",
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
    XCTAssertEqual(viewModel.completionState, .abandoned) // No state change should happen
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
