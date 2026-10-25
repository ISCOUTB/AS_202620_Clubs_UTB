import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ _: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ _: NSApplication) -> Bool {
    return true
  }
}
