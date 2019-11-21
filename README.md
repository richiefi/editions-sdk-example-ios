# Richie Editions SDK for iOS Demo

This is an iOS app demonstrating the usage of the Richie Editions SDK framework.

The app initializes the SDK at launch, once initialization is done, it updates the feed content and displays the available editions.

## How to use

Use tap to download an edition, cancel an ongoing download or open a downloaded edition. Use a long tap to delete a downloaded edition. 

## Building

The repository uses [XcodeGen] to create the project file, and the SDK is integrated using [Cocoa Pods]. Use the included script `generate-xcode-project.sh` to generate the project and install the dependencies, after that open the workspace `EditionsSampleApp.xcworkspace`.

[XcodeGen]: https://github.com/yonaskolb/XcodeGen
[Cocoa Pods]: https://cocoapods.org
