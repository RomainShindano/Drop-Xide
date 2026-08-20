import Cocoa
import FlutterMacOS
import macos_window_utils
import UniformTypeIdentifiers

class MainFlutterWindow: NSWindow {
  private var filePickerChannel: FlutterMethodChannel?

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
        switch call.method {
        case "pickDirectory":
          self.pickDirectory(result: result)
        case "pickFile":
          let args = call.arguments as? [String: Any]
          let extensions = args?["extensions"] as? [String] ?? []
          self.pickFile(allowedExtensions: extensions, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  private func pickDirectory(result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = false
    panel.prompt = "Select"
    panel.message = "Choose a Flutter project folder"

    present(panel, result: result)
  }

  private func pickFile(allowedExtensions: [String], result: @escaping FlutterResult) {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.prompt = "Select"

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
    panel.beginSheetModal(for: self) { response in
      if response == .OK {
        result(panel.url?.path)
      } else {
        result(nil)
      }
    }
  }
}
