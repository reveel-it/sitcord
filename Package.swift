// swift-tools-version:5.2
import PackageDescription

let packageName = "sitcord"
let package = Package(
  name: "sitcord",
  platforms: [.macOS(.v10_15)],
  products: [
  ],
  targets: [
    .target(
      name: packageName,
      path: packageName
    )
  ]
)