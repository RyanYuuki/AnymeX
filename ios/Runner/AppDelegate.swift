import Flutter
import UIKit
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.anymex.app/thumbnail", binaryMessenger: controller.binaryMessenger)

    cleanupOldThumbnails()

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getVideoThumbnail" {
        guard let args = call.arguments as? [String: Any],
              let videoPath = args["videoPath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "videoPath is null", details: nil))
          return
        }
        self.extractThumbnail(videoPath: videoPath, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func extractThumbnail(videoPath: String, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      let url = URL(fileURLWithPath: videoPath)
      let asset = AVAsset(url: url)
      let generator = AVAssetImageGenerator(asset: asset)
      generator.appliesPreferredTrackTransform = true
      generator.maximumSize = CGSize(width: 320, height: 240)

      let durationSeconds = CMTimeGetSeconds(asset.duration)
      let targetSeconds: Double
      if durationSeconds > 60 {
        targetSeconds = min(30.0, durationSeconds * 0.10)
      } else if durationSeconds > 10 {
        targetSeconds = min(5.0, durationSeconds * 0.10)
      } else if durationSeconds > 0 {
        targetSeconds = max(0.5, durationSeconds * 0.10)
      } else {
        targetSeconds = 1.0
      }

      let time = CMTime(seconds: targetSeconds, preferredTimescale: 60)
      do {
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        let uiImage = UIImage(cgImage: cgImage)
        if let data = uiImage.jpegData(compressionQuality: 0.85) {
          let tempDir = NSTemporaryDirectory()
          let fileName = "thumb_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString).jpg"
          let filePath = (tempDir as NSString).appendingPathComponent(fileName)
          try data.write(to: URL(fileURLWithPath: filePath))

          DispatchQueue.main.async { result(filePath) }
          return
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "EXTRACTION_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func cleanupOldThumbnails() {
    DispatchQueue.global(qos: .background).async {
      let tempDir = NSTemporaryDirectory()
      let fileManager = FileManager.default
      guard let files = try? fileManager.contentsOfDirectory(atPath: tempDir) else { return }
      let now = Date().timeIntervalSince1970
      for file in files where file.hasPrefix("thumb_") && file.hasSuffix(".jpg") {
        let path = (tempDir as NSString).appendingPathComponent(file)
        if let attrs = try? fileManager.attributesOfItem(atPath: path),
           let modDate = attrs[.modificationDate] as? Date,
           now - modDate.timeIntervalSince1970 > 86400 {
          try? fileManager.removeItem(atPath: path)
        }
      }
    }
  }
}
