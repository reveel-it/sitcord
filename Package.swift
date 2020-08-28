// swift-tools-version:5.2
import PackageDescription

let packageName = "sitcord"
let package = Package(
  name: "sitcord",
  platforms: [.macOS("15.0")],
  products: [
    .library(name: packageName, targets: [packageName])
  ],
  targets: [
    .target(
      name: packageName,
      path: packageName
    )
  ]
)