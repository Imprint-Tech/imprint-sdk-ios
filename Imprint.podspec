# Be sure to run `pod lib lint Imprint.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Imprint'
  s.version          = '0.1.6'
  s.summary          = 'Imprint SDK'

  s.description      = <<-DESC
  Use this SDK to launch the Imprint Sign-Up experience throughout your iOS app.
                       DESC

  s.homepage         = 'https://github.com/Imprint-Tech/imprint-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wantingshao' => 'wanting@imprint.co' }
  s.source           = { :git => 'https://github.com/Imprint-Tech/imprint-sdk-ios.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_version    = '5.0'
  s.ios.vendored_frameworks = [
    "Imprint.xcframework"
  ]
  
end
