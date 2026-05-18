// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CalendarAvailability",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "CalendarAvailability",
            path: "Sources/CalendarAvailability"
        )
    ]
)
