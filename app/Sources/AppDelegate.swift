import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSMakeRect(0, 0, 800, 600),
                          styleMask: [.titled, .closable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "FracTile"
        window.makeKeyAndOrderFront(nil)
    }
}
