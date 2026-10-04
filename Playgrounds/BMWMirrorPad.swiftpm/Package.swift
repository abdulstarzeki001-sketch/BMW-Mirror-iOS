// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "BMW Mirror Pad Full Screen R4",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "BMW Mirror Pad Full Screen R4",
            targets: ["AppModule"],
            bundleIdentifier: "com.abdulstar.bmwmirror.padfullscreenr4",
            displayVersion: "4.0",
            bundleVersion: "400",
            appIcon: .placeholder(icon: .star),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            additionalInfoPlistContentFilePath: "AdditionalInfo.plist"
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            exclude: [
                "README.md",
                "AdditionalInfo.plist"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
