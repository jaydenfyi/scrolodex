// swift-tools-version: 6.1

import PackageDescription

let package = Package(
	name: "Scrolodex",
	platforms: [
		.macOS(.v14)
	],
	products: [
		.library(name: "ScrolodexCore", targets: ["ScrolodexCore"]),
		.executable(name: "Scrolodex", targets: ["Scrolodex"])
	],
	targets: [
		.target(name: "ScrolodexCore"),
		.target(name: "ScrolodexSettings", dependencies: ["ScrolodexCore"]),
		.executableTarget(
			name: "Scrolodex",
			dependencies: ["ScrolodexCore", "ScrolodexSettings"]
		),
		.testTarget(name: "ScrolodexCoreTests", dependencies: ["ScrolodexCore"]),
		.testTarget(name: "ScrolodexSettingsTests", dependencies: ["ScrolodexSettings", "ScrolodexCore"])
	]
)
