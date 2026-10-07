//
//  WebViewWrapperTests.swift
//  ImprintTests
//
//  Created by Xingtan Hu on 2/14/25.
//

import XCTest
import WebKit
import Combine
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
      "source": "imprint_web_app",
      "event_name": "OFFER_ACCEPTED",
      "tier": "outcome",
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
  
  func testPayloadWithoutTierPreservesLegacyOutcomeOnClosed() {
    // Arrange
    let messageBody: [String: Any] = [
      "source": "imprint_web_app",
      "event_name": "OFFER_ACCEPTED",
      "customer_id": "consumer-123",
      "partner_customer_id": "partner-ref-789",
      "payment_method_id": "account-321"
    ]
    let message = MockWKScriptMessage(name: WebViewWrapper.Constants.callbackHandlerName, body: messageBody)
    
    let messageBody2: [String: Any] = [
      "source": "imprint_web_app",
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
      "source": "imprint_web_app",
      "event_name": "REJECTED",
      "tier": "outcome",
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
      "source": "imprint_web_app",
      "event_name": "ERROR",
      "tier": "outcome",
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
      "source": "imprint_web_app",
      "event_name": "OFFER_ACCEPTED",
      "tier": "outcome",
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
      "source": "imprint_web_app",
      "event_name": "OFFER_ACCEPTED",
      "tier": "outcome",
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

  func testIntermediateEventsAreObservableWithoutOverwritingAcceptedOutcome() {
    // Arrange
    let configuration = ImprintConfiguration(clientSecret: "testSecret")
    var receivedEvents: [String] = []
    var accountLinkStatus: String?
    var paymentMethodID: String?
    configuration.onEvent = { eventName, data in
      receivedEvents.append(eventName)
      if eventName == "ACCOUNT_LINK_RESULT" {
        accountLinkStatus = data?["status"] as? String
      }
      if eventName == "PAYMENT_METHOD_CREATED" {
        paymentMethodID = data?["payment_method_id"] as? String
      }
    }
    viewModel = ApplicationViewModel(configuration: configuration)
    coordinator = WebViewWrapper.Coordinator(viewModel: viewModel)

    let accepted = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: [
        "source": "imprint_web_app",
        "event_name": "OFFER_ACCEPTED",
        "tier": "outcome"
      ]
    )
    let accountLinkResult = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: [
        "source": "imprint_web_app",
        "event_name": "ACCOUNT_LINK_RESULT",
        "tier": "intermediate",
        "status": "success"
      ]
    )
    let paymentMethodCreated = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: [
        "source": "imprint_web_app",
        "event_name": "PAYMENT_METHOD_CREATED",
        "tier": "intermediate",
        "payment_method_id": "payment-123"
      ]
    )

    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: accepted)
    coordinator.userContentController(WKUserContentController(), didReceive: accountLinkResult)
    coordinator.userContentController(WKUserContentController(), didReceive: paymentMethodCreated)

    // Assert
    XCTAssertEqual(viewModel.completionState, .offerAccepted)
    XCTAssertEqual(receivedEvents, [
      "OFFER_ACCEPTED",
      "ACCOUNT_LINK_RESULT",
      "PAYMENT_METHOD_CREATED"
    ])
    XCTAssertEqual(accountLinkStatus, "success")
    XCTAssertEqual(paymentMethodID, "payment-123")
  }

  func testUnknownEventAndTierAreObservableButNonTerminal() {
    // Arrange
    let configuration = ImprintConfiguration(clientSecret: "testSecret")
    var receivedEvents: [String] = []
    configuration.onEvent = { eventName, _ in
      receivedEvents.append(eventName)
    }
    viewModel = ApplicationViewModel(configuration: configuration)
    coordinator = WebViewWrapper.Coordinator(viewModel: viewModel)

    let accepted = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: [
        "source": "imprint_web_app",
        "event_name": "OFFER_ACCEPTED",
        "tier": "outcome"
      ]
    )
    let unknownEvent = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: [
        "source": "imprint_web_app",
        "event_name": "FUTURE_EVENT",
        "tier": "outcome"
      ]
    )
    let unknownTier = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: [
        "source": "imprint_web_app",
        "event_name": "CLOSED",
        "tier": "future_tier"
      ]
    )
    let malformedTier = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: [
        "source": "imprint_web_app",
        "event_name": "CLOSED",
        "tier": 3
      ]
    )

    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: accepted)
    coordinator.userContentController(WKUserContentController(), didReceive: unknownEvent)
    coordinator.userContentController(WKUserContentController(), didReceive: unknownTier)
    coordinator.userContentController(WKUserContentController(), didReceive: malformedTier)

    // Assert
    XCTAssertEqual(viewModel.completionState, .offerAccepted)
    XCTAssertEqual(viewModel.processState, .offerAccepted)
    XCTAssertEqual(receivedEvents, ["OFFER_ACCEPTED", "FUTURE_EVENT", "CLOSED", "CLOSED"])
  }

  func testInternalEventsStayPrivateWhileUpdatingShellLifecycle() {
    // Arrange
    let configuration = ImprintConfiguration(clientSecret: "testSecret")
    var receivedEvents: [String] = []
    configuration.onEvent = { eventName, _ in
      receivedEvents.append(eventName)
    }
    viewModel = ApplicationViewModel(configuration: configuration)
    coordinator = WebViewWrapper.Coordinator(viewModel: viewModel)

    let internalOutcome = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: [
        "source": "imprint_internal_event",
        "event_name": "OFFER_ACCEPTED",
        "tier": "outcome"
      ]
    )
    let internalClosed = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: [
        "source": "imprint_internal_event",
        "event_name": "CLOSED",
        "tier": "terminal"
      ]
    )

    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: internalOutcome)
    coordinator.userContentController(WKUserContentController(), didReceive: internalClosed)

    // Assert
    XCTAssertTrue(receivedEvents.isEmpty)
    XCTAssertEqual(viewModel.completionState, .offerAccepted)
    XCTAssertEqual(viewModel.processState, .closed)
  }
  
  func testDuplicateClosedMessagesCompleteOnce() {
    // Arrange
    let configuration = ImprintConfiguration(clientSecret: "testSecret")
    var completions: [ImprintConfiguration.CompletionState] = []
    configuration.onCompletion = { state, _ in
      completions.append(state)
    }
    viewModel = ApplicationViewModel(configuration: configuration)
    coordinator = WebViewWrapper.Coordinator(viewModel: viewModel)
    var closedPublishes = 0
    let subscription = viewModel.$processState.sink { state in
      if state == .closed { closedPublishes += 1 }
    }

    let accepted = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: ["source": "imprint_web_app", "event_name": "OFFER_ACCEPTED", "tier": "outcome"]
    )
    let partnerClosed = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: ["source": "imprint_web_app", "event_name": "CLOSED", "tier": "terminal"]
    )
    let internalClosed = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: ["source": "imprint_internal_event", "event_name": "CLOSED", "tier": "terminal"]
    )

    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: accepted)
    coordinator.userContentController(WKUserContentController(), didReceive: partnerClosed)
    coordinator.userContentController(WKUserContentController(), didReceive: internalClosed)
    viewModel.onDismiss()
    viewModel.onDismiss()
    subscription.cancel()

    // Assert
    XCTAssertEqual(closedPublishes, 1)
    XCTAssertEqual(completions, [.offerAccepted])
  }

  func testPayloadWithoutSourceIsTreatedAsPartnerEvent() {
    // Arrange
    let configuration = ImprintConfiguration(clientSecret: "testSecret")
    var receivedEvents: [String] = []
    configuration.onEvent = { eventName, _ in
      receivedEvents.append(eventName)
    }
    viewModel = ApplicationViewModel(configuration: configuration)
    coordinator = WebViewWrapper.Coordinator(viewModel: viewModel)

    let accepted = MockWKScriptMessage(
      name: WebViewWrapper.Constants.callbackHandlerName,
      body: ["event_name": "OFFER_ACCEPTED", "tier": "outcome"]
    )

    // Act
    coordinator.userContentController(WKUserContentController(), didReceive: accepted)

    // Assert
    XCTAssertEqual(receivedEvents, ["OFFER_ACCEPTED"])
    XCTAssertEqual(viewModel.completionState, .offerAccepted)
  }

  @MainActor
  func testTieredEventsCrossWebKitBridge() async throws {
    let configuration = ImprintConfiguration(clientSecret: "testSecret")
    var receivedEvents: [String] = []
    var completions: [ImprintConfiguration.CompletionState] = []
    let eventsDelivered = expectation(description: "Partner events delivered")
    eventsDelivered.expectedFulfillmentCount = 3
    configuration.onEvent = { name, _ in
      receivedEvents.append(name)
      eventsDelivered.fulfill()
    }
    configuration.onCompletion = { state, _ in completions.append(state) }
    viewModel = ApplicationViewModel(configuration: configuration)
    coordinator = WebViewWrapper.Coordinator(viewModel: viewModel)

    let webConfiguration = WKWebViewConfiguration()
    webConfiguration.userContentController.add(coordinator, name: WebViewWrapper.Constants.callbackHandlerName)
    let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), configuration: webConfiguration)
    let window = UIWindow(frame: webView.frame)
    window.rootViewController = UIViewController()
    window.makeKeyAndVisible()
    window.rootViewController?.view.addSubview(webView)

    let pageLoaded = expectation(description: "WebKit page loaded")
    let observer = WebViewNavigationObserver { pageLoaded.fulfill() }
    webView.navigationDelegate = observer
    webView.loadHTMLString("<html><body>Event bridge test</body></html>", baseURL: nil)
    await fulfillment(of: [pageLoaded], timeout: 10)

    _ = try await webView.evaluateJavaScript("""
      const send = (name, source, tier) => window.webkit.messageHandlers.imprintWebCallback.postMessage(
        {event_name: name, source: source, tier: tier});
      send('OFFER_ACCEPTED', 'imprint_web_app', 'outcome');
      send('ACCOUNT_LINK_RESULT', 'imprint_web_app', 'intermediate');
      send('CLOSED', 'imprint_web_app', 'terminal');
      send('CLOSED', 'imprint_internal_event', 'terminal');
      true;
      """)
    await fulfillment(of: [eventsDelivered], timeout: 10)
    viewModel.onDismiss()
    viewModel.onDismiss()

    XCTAssertEqual(receivedEvents, ["OFFER_ACCEPTED", "ACCOUNT_LINK_RESULT", "CLOSED"])
    XCTAssertEqual(viewModel.processState, .closed)
    XCTAssertEqual(completions, [.offerAccepted])
    webConfiguration.userContentController.removeScriptMessageHandler(forName: WebViewWrapper.Constants.callbackHandlerName)
    window.isHidden = true
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

private class WebViewNavigationObserver: NSObject, WKNavigationDelegate {
  let onFinish: () -> Void

  init(onFinish: @escaping () -> Void) {
    self.onFinish = onFinish
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    onFinish()
  }
}
