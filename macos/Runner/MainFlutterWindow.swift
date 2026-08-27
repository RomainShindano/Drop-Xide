import Cocoa
import FlutterMacOS
import macos_window_utils
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow {
  /// Bookmarks keyed by the path the user originally chose.
  private static let bookmarksKey = "dropxide.securityScopedBookmarks"

  private var filePickerChannel: FlutterMethodChannel?

  /// Security-scoped URLs kept alive for the lifetime of the process. Access
  /// ends as soon as these are released, so they must be retained.
  private var activeScopedURLs: [URL] = []

  override func awakeFromNib() {
    let windowFrame = self.frame
    let macOSWindowUtilsViewController = MacOSWindowUtilsViewController()
    self.contentViewController = macOSWindowUtilsViewController
    self.setFrame(windowFrame, display: true)

    MainFlutterWindowManipulator.start(mainFlutterWindow: self)

    let flutterViewController = macOSWindowUtilsViewController.flutterViewController
    RegisterGeneratedPlugins(registry: flutterViewController)
    setupFilePickerChannel(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }

  private func setupFilePickerChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "drop_xide/file_picker",
      binaryMessenger: messenger
    )
    filePickerChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(
          FlutterError(
            code: "unavailable",
            message: "Window is not available",
            details: nil
          )
        )
        return
      }

      DispatchQueue.main.async {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "pickDirectory":
          self.pickDirectory(
            dialogTitle: args?["dialogTitle"] as? String,
            confirmButtonText: args?["confirmButtonText"] as? String,
            result: result
          )
        case "pickFile":
          self.pickFile(
            allowedExtensions: args?["extensions"] as? [String] ?? [],
            dialogTitle: args?["dialogTitle"] as? String,
            confirmButtonText: args?["confirmButtonText"] as? String,
            result: result
          )
        case "restoreAccess":
          result(self.restoreAccess())
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  private func pickDirectory(
    dialogTitle: String?,
    confirmButtonText: String?,
    result: @escaping FlutterResult
  ) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = false
    panel.prompt = confirmButtonText ?? "Select"
    panel.message = dialogTitle ?? "Choose a folder"

    present(panel, result: result)
  }

  private func pickFile(
    allowedExtensions: [String],
    dialogTitle: String?,
    confirmButtonText: String?,
    result: @escaping FlutterResult
  ) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.prompt = confirmButtonText ?? "Select"

    if let dialogTitle = dialogTitle {
      panel.message = dialogTitle
    }

    if !allowedExtensions.isEmpty {
      if #available(macOS 11.0, *) {
        panel.allowedContentTypes = allowedExtensions.compactMap {
          UTType(filenameExtension: $0)
        }
      } else {
        panel.allowedFileTypes = allowedExtensions
      }
    }

    present(panel, result: result)
  }

  private func present(_ panel: NSOpenPanel, result: @escaping FlutterResult) {
    panel.beginSheetModal(for: self) { [weak self] response in
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }

      self?.persistAccess(to: url)
      result(url.path)
    }
  }

  /// Records a security-scoped bookmark so the folder stays reachable after the
  /// app is relaunched. Without this, App Sandbox grants access only until the
  /// app quits, and saved project or SDK paths become unreadable.
  private func persistAccess(to url: URL) {
    do {
      let data = try url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      var stored = storedBookmarks()
      stored[url.path] = data
      UserDefaults.standard.set(stored, forKey: MainFlutterWindow.bookmarksKey)
    } catch {
      // Bookmarking with security scope is only meaningful for a sandboxed app.
      // An unsandboxed build already has access, so there is nothing to persist.
    }
  }

  /// Re-acquires access to every previously chosen path. Returns the paths that
  /// are usable again; stale or revoked bookmarks are dropped.
  private func restoreAccess() -> [String] {
    let stored = storedBookmarks()
    guard !stored.isEmpty else { return [] }

    var restored: [String] = []
    var surviving: [String: Data] = [:]

    for (path, data) in stored {
      var isStale = false
      guard
        let url = try? URL(
          resolvingBookmarkData: data,
          options: .withSecurityScope,
          relativeTo: nil,
          bookmarkDataIsStale: &isStale
        )
      else {
        continue
      }

      if url.startAccessingSecurityScopedResource() {
        activeScopedURLs.append(url)
        restored.append(url.path)

        if isStale, let refreshed = refreshedBookmark(for: url) {
          surviving[path] = refreshed
        } else {
          surviving[path] = data
        }
      }
    }

    UserDefaults.standard.set(surviving, forKey: MainFlutterWindow.bookmarksKey)
    return restored
  }

  private func refreshedBookmark(for url: URL) -> Data? {
    try? url.bookmarkData(
      options: .withSecurityScope,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
  }

  private func storedBookmarks() -> [String: Data] {
    let raw = UserDefaults.standard.dictionary(forKey: MainFlutterWindow.bookmarksKey)
    return raw as? [String: Data] ?? [:]
  }
}
