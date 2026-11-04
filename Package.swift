// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RCJBridge",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "rcj-bridge", targets: ["RCJBridge"])],
    targets: [.executableTarget(name: "RCJBridge", path: "Bridge")],
    swiftLanguageModes: [.v5]
)
