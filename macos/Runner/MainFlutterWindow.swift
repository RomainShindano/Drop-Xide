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
            initialDirectory: args?["initialDirectory"] as? String,
            result: result
          )
        case "pickFlutterSdk":
          self.pickFlutterSdk(
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
    initialDirectory: String?,
    result: @escaping FlutterResult
  ) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = false
    panel.prompt = confirmButtonText ?? "Select"
    panel.message = dialogTitle ?? "Choose a folder"
    applyInitialDirectory(initialDirectory, to: panel)

    present(panel, result: result)
  }

  /// Opens a panel that accepts either the SDK root directory or the `flutter`
  /// executable itself. Starts in the Homebrew Caskroom when it exists.
  private func pickFlutterSdk(
    dialogTitle: String?,
    confirmButtonText: String?,
    result: @escaping FlutterResult
  ) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = false
    panel.prompt = confirmButtonText ?? "Use SDK"
    panel.message =
      dialogTitle
      ?? "Choose a Flutter version folder (e.g. 3.29.0), the flutter folder "
      + "inside it, or the flutter executable. Selecting the Caskroom/flutter "
      + "folder picks the newest version automatically."
    panel.treatsFilePackagesAsDirectories = true

    let homebrewCaskroom = "/opt/homebrew/Caskroom/flutter"
    let legacyCaskroom = "/usr/local/Caskroom/flutter"
    if FileManager.default.fileExists(atPath: homebrewCaskroom) {
      applyInitialDirectory(homebrewCaskroom, to: panel)
    } else if FileManager.default.fileExists(atPath: legacyCaskroom) {
      applyInitialDirectory(legacyCaskroom, to: panel)
    }

    presentFlutterSdk(panel, result: result)
  }

  private func applyInitialDirectory(_ path: String?, to panel: NSOpenPanel) {
    guard let path = path, !path.isEmpty else { return }
    let url = URL(fileURLWithPath: path, isDirectory: true)
    if FileManager.default.fileExists(atPath: url.path) {
      panel.directoryURL = url
    }
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

  private func presentFlutterSdk(_ panel: NSOpenPanel, result: @escaping FlutterResult) {
    panel.beginSheetModal(for: self) { [weak self] response in
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }

      // Grant access to the selection first so nested discovery can run.
      self?.persistAccess(to: url)

      guard let sdkRoot = self?.resolveSdkRoot(from: url) else {
        result(
          FlutterError(
            code: "invalid_sdk",
            message:
              "No Flutter SDK found in that selection. Choose a version folder "
              + "inside Caskroom (e.g. 3.29.0), the flutter folder within it, "
              + "or the flutter executable in bin/.",
            details: url.path
          )
        )
        return
      }

      self?.persistAccess(to: sdkRoot)

      if let version = self?.readFlutterVersion(at: sdkRoot) {
        result([
          "sdkRoot": sdkRoot.path,
          "version": version,
        ])
        return
      }

      result(
        FlutterError(
          code: "invalid_sdk",
          message:
            "No Flutter SDK found in that selection. Choose a version folder "
            + "inside Caskroom (e.g. 3.29.0), the flutter folder within it, "
            + "or the flutter executable in bin/.",
          details: url.path
        )
      )
    }
  }

  private func present(_ panel: NSOpenPanel, result: @escaping FlutterResult) {
    panel.beginSheetModal(for: self) { [weak self] response in
      guard response == .OK, let url = panel.url else {
        result(nil)
        return
      }

      if let sdkRoot = self?.resolveSdkRoot(from: url) {
        self?.persistAccess(to: sdkRoot)
        result(sdkRoot.path)
      } else {
        self?.persistAccess(to: url)
        result(url.path)
      }
    }
  }

  /// Resolves any common Flutter SDK selection to the SDK root directory.
  private func resolveSdkRoot(from url: URL) -> URL? {
    if !url.hasDirectoryPath {
      return sdkRootForFlutterExecutable(url)
    }

    let binFlutter = url.appendingPathComponent("bin/flutter")
    if FileManager.default.fileExists(atPath: binFlutter.path) {
      return url
    }

    let nested = url.appendingPathComponent("flutter")
    let nestedBinFlutter = nested.appendingPathComponent("bin/flutter")
    if FileManager.default.fileExists(atPath: nestedBinFlutter.path) {
      return nested
    }

    if url.lastPathComponent == "flutter" {
      return newestSdkInCaskroom(url)
    }

    return nil
  }

  /// When the user selects `/opt/homebrew/Caskroom/flutter`, pick the newest
  /// installed version automatically (`…/<version>/flutter`).
  private func newestSdkInCaskroom(_ caskroom: URL) -> URL? {
    guard
      let entries = try? FileManager.default.contentsOfDirectory(
        at: caskroom,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      )
    else {
      return nil
    }

    let sorted = entries.sorted { $0.lastPathComponent > $1.lastPathComponent }
    for versionDir in sorted {
      let sdk = versionDir.appendingPathComponent("flutter")
      let binFlutter = sdk.appendingPathComponent("bin/flutter")
      if FileManager.default.fileExists(atPath: binFlutter.path) {
        return sdk
      }
    }
    return nil
  }

  /// Runs `bin/flutter --version` while security-scoped access is active.
  private func readFlutterVersion(at sdkRoot: URL) -> String? {
    let binary = sdkRoot.appendingPathComponent("bin/flutter")
    guard FileManager.default.fileExists(atPath: binary.path) else {
      return structuralVersion(at: sdkRoot)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sh")
    process.arguments = [binary.path, "--version"]

    var env = ProcessInfo.processInfo.environment
    env["FLUTTER_ROOT"] = sdkRoot.path
    let binPath = sdkRoot.appendingPathComponent("bin").path
    env["PATH"] = "\(binPath):" + (env["PATH"] ?? "")
    process.environment = env

    let output = Pipe()
    process.standardOutput = output
    process.standardError = Pipe()

    do {
      try process.run()
      process.waitUntilExit()
      if process.terminationStatus == 0 {
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let text = String(data: data, encoding: .utf8) ?? ""
        let line = text
          .split(separator: "\n", omittingEmptySubsequences: true)
          .first
          .map(String.init)?
          .trimmingCharacters(in: .whitespacesAndNewlines)
        if let line = line, line.hasPrefix("Flutter ") {
          return line
        }
      }
    } catch {
      // Fall through to structural validation.
    }

    return structuralVersion(at: sdkRoot)
  }

  /// Accepts an SDK when `bin/flutter` and core package files exist, even if
  /// sandbox policy blocks executing the flutter script during validation.
  private func structuralVersion(at sdkRoot: URL) -> String? {
    let binFlutter = sdkRoot.appendingPathComponent("bin/flutter")
    let packagesFlutter = sdkRoot.appendingPathComponent("packages/flutter")
    let versionFile = sdkRoot.appendingPathComponent("version")

    guard FileManager.default.fileExists(atPath: binFlutter.path) else {
      return nil
    }

    guard
      FileManager.default.fileExists(atPath: packagesFlutter.path)
        || FileManager.default.fileExists(atPath: versionFile.path)
    else {
      return nil
    }

    if
      let raw = try? String(
        contentsOf: versionFile,
        encoding: .utf8
      )
    {
      let version = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      if !version.isEmpty {
        return "Flutter \(version)"
      }
    }

    return "Flutter SDK"
  }

  /// Maps a panel selection to the SDK root directory when possible.
  private func sdkRootForFlutterExecutable(_ url: URL) -> URL? {
    guard url.lastPathComponent == "flutter" else { return nil }
    let binDir = url.deletingLastPathComponent()
    guard binDir.lastPathComponent == "bin" else { return nil }
    return binDir.deletingLastPathComponent()
  }

  /// Records a security-scoped bookmark so the folder stays reachable after the
  /// app is relaunched. Also starts access for the current process so Dart can
  /// read the path immediately after the user confirms the panel.
  private func persistAccess(to url: URL) {
    activateAccess(to: url)

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

  /// Keeps a security-scoped URL alive for the lifetime of the process.
  private func activateAccess(to url: URL) -> Bool {
    let alreadyActive = activeScopedURLs.contains { existing in
      existing.path == url.path
    }
    if alreadyActive {
      return true
    }
    guard url.startAccessingSecurityScopedResource() else { return false }
    activeScopedURLs.append(url)
    return true
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

      guard activateAccess(to: url) else { continue }
      restored.append(url.path)

      if isStale, let refreshed = refreshedBookmark(for: url) {
        surviving[path] = refreshed
      } else {
        surviving[path] = data
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
