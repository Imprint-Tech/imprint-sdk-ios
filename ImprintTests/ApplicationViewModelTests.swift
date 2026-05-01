//
//  ApplicationViewModelTests.swift
//  ImprintTests
//

import XCTest
@testable import Imprint

class ApplicationViewModelTests: XCTestCase {

  func testWebUrlWithoutOfferConfigUUID() {
    let configuration = ImprintConfiguration(clientSecret: "test-secret", environment: .production)
    let viewModel = ApplicationViewModel(configuration: configuration)

    let url = viewModel.webUrl.absoluteString
    XCTAssertTrue(url.hasPrefix("https://apply.imprint.co/start?"))
    XCTAssertTrue(url.contains("client_secret=test-secret"))
    XCTAssertFalse(url.contains("offerConfigUUID"))
  }

  func testWebUrlWithOfferConfigUUID() {
    let configuration = ImprintConfiguration(
      clientSecret: "test-secret",
      environment: .production,
      offerConfigUUID: "offer-uuid-123"
    )
    let viewModel = ApplicationViewModel(configuration: configuration)

    let url = viewModel.webUrl.absoluteString
    XCTAssertTrue(url.contains("client_secret=test-secret"))
    XCTAssertTrue(url.contains("offerConfigUUID=offer-uuid-123"))
  }

  func testWebUrlStagingEnvironment() {
    let configuration = ImprintConfiguration(
      clientSecret: "stg-secret",
      environment: .staging,
      offerConfigUUID: "stg-offer-uuid"
    )
    let viewModel = ApplicationViewModel(configuration: configuration)

    let url = viewModel.webUrl.absoluteString
    XCTAssertTrue(url.hasPrefix("https://apply.stg.imprintapi.co/start?"))
    XCTAssertTrue(url.contains("offerConfigUUID=stg-offer-uuid"))
  }

  func testWebUrlSandboxEnvironment() {
    let configuration = ImprintConfiguration(
      clientSecret: "sbx-secret",
      environment: .sandbox,
      offerConfigUUID: "sbx-offer-uuid"
    )
    let viewModel = ApplicationViewModel(configuration: configuration)

    let url = viewModel.webUrl.absoluteString
    XCTAssertTrue(url.hasPrefix("https://apply.sbx.imprint.co/start?"))
    XCTAssertTrue(url.contains("offerConfigUUID=sbx-offer-uuid"))
  }

  func testConfigurationDefaultsOfferConfigUUIDToNil() {
    let configuration = ImprintConfiguration(clientSecret: "secret")
    XCTAssertNil(configuration.offerConfigUUID)
  }
}
