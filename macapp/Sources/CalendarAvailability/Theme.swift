import SwiftUI

/// Catppuccin Mocha palette — mirrors `src/calendar_availability/theme.py`
/// so the in-app preview matches the exported PNG.
enum Theme {
    static let bg      = Color(red: 30/255,  green: 30/255,  blue: 46/255)   // #1e1e2e
    static let surface = Color(red: 49/255,  green: 50/255,  blue: 68/255)   // #313244
    static let grid    = Color(red: 69/255,  green: 71/255,  blue: 90/255)   // #45475a
    static let text    = Color(red: 205/255, green: 214/255, blue: 244/255)  // #cdd6f4
    static let muted   = Color(red: 127/255, green: 132/255, blue: 156/255)  // #7f849c
    static let lunch   = Color(red: 243/255, green: 139/255, blue: 168/255)  // #f38ba8

    static let palette: [Color] = [
        Color(red: 137/255, green: 180/255, blue: 250/255),  // blue
        Color(red: 166/255, green: 227/255, blue: 161/255),  // green
        Color(red: 249/255, green: 226/255, blue: 175/255),  // yellow
        Color(red: 250/255, green: 179/255, blue: 135/255),  // peach
        Color(red: 243/255, green: 139/255, blue: 168/255),  // pink
        Color(red: 203/255, green: 166/255, blue: 247/255),  // mauve
        Color(red: 148/255, green: 226/255, blue: 213/255),  // teal
        Color(red: 116/255, green: 199/255, blue: 236/255),  // sky
    ]
}
