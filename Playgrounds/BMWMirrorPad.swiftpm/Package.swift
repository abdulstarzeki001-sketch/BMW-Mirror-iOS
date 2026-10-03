// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "BMW Mirror Pad",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "BMW Mirror Pad",
            targets: ["AppModule"],
            bundleIdentifier: "com.abdulstar.bmwmirror.padtest",
            displayVersion: "1.0",
            bundleVersion: "1",
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
