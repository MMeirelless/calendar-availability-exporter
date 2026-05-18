import SwiftUI

@main
struct CalendarAvailabilityApp: App {
    @State private var service = CalendarService()
    @State private var options = AvailabilityOptions()

    var body: some Scene {
        Window("Calendar Availability", id: "main") {
            ContentView()
                .environment(service)
                .environment(options)
                .task { await service.requestAccess() }
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1200, height: 760)
        .windowResizability(.contentMinSize)
        .windowToolbarStyle(.unified(showsTitle: false))
    }
}
