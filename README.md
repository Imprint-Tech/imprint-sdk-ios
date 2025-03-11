<p>
  <img src="Assets/imprintLogoSmall.png" alt="Imprint Logo" width="40px">
</p>

# Imprint iOS SDK

## Installation

### Option 1

### Swift Package Manager

1. Add the following repository URL:
   
   ```
   https://github.com/Imprint-Tech/imprint-sdk-ios
   ```
2. Select your desired version or branch
3. Click **Add Package**

You can also add Imprint as a dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Imprint-Tech/imprint-sdk-ios", from: "0.1.6")
]
```

### Option 2
### Cocoapods
Add Imprint iOS SDK to your project using CocoaPods(minimum support cocoapods version: 1.16.1):

1. If you haven't already, install CocoaPods:

   ```bash
   sudo gem install cocoapods
   ```

2. Create a Podfile in your project directory if you don't have one:

   ```bash
   pod init
   ```

3. Add Imprint iOS SDK to your Podfile:

    ```ruby
   target 'YourApp' do
      pod 'Imprint'   
   end
   ```

4. Install the dependencies:

    ```bash
   pod install
   ```

5. Open the `.xcworkspace` file that CocoaPods created (not the `.xcodeproj`).


## Implementation
1. Import the SDK

    ```swift
    import Imprint
    ```

2. Configuration
Create an instance of `ImprintConfiguration` with your `client_secret`, `partner_reference` and `environment`, then assign additional optional fields as needed.

    ```swift
    let configuration = ImprintConfiguration(clientSecret: "client_secret", partnerReference: "partner_reference", environment: .sandbox)
    ```

3. Define the Completion Handler
Define the completion handler onCompletion to manage the terminal states when the application flow ends.

    ```swift
    configuration.onCompletion = { state, metadata in
      switch state {
      case .offerAccepted:
        print("Offer accepted, metadata: \(String(describing: metadata))")
      case .rejected:
        print("Application rejected, metadata: \(String(describing: metadata))")
      case .abandoned:
        print("Flow abandoned, metadata: \(String(describing: metadata))")
      case .error:
        print("Error occurred, metadata: \(String(describing: metadata))")
      }
      // Perform any generic actions after the flow ends if needed
    }
    ```

4. Start the Application flow
Once you’ve configured the ImprintConfiguration, initiate the application flow by calling ImprintApp.startApplication from your view controller.
    
    ```swift
    public static func startApplication(from viewController: UIViewController, configuration: ImprintConfiguration)
    ```
    
    
`viewController`: The view controller from which the application flow will be presented

`configuration`: The previously created ImprintConfiguration object containing your API key and completion handler
