import fl_pip
import Flutter
import UIKit
import MediaPlayer

@main
@objc class AppDelegate: FlFlutterAppDelegate {

    private var pipControlsChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Set up the MethodChannel for PiP controls after the Flutter engine is ready
        if let controller = window?.rootViewController as? FlutterViewController {
            pipControlsChannel = FlutterMethodChannel(
                name: "com.ryan.anymex/pip_controls",
                binaryMessenger: controller.binaryMessenger
            )

            // Handle calls from Flutter to update our MPNowPlayingInfo state
            pipControlsChannel?.setMethodCallHandler { [weak self] call, result in
                if call.method == "updatePlaybackState" {
                    if let args = call.arguments as? [String: Any],
                       let isPlaying = args["isPlaying"] as? Bool {
                        self?.updateNowPlayingPlaybackState(isPlaying: isPlaying)
                    }
                    result(nil)
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        setupRemoteCommandCenter()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func registerPlugin(_ registry: FlutterPluginRegistry) {
        GeneratedPluginRegistrant.register(with: registry)
    }

    // MARK: - MPRemoteCommandCenter

    /// Registers system-level play/pause/next/previous handlers.
    /// These fire from the iOS PiP overlay controls, lock screen, and Control Center.
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.pipControlsChannel?.invokeMethod("play", arguments: nil)
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pipControlsChannel?.invokeMethod("pause", arguments: nil)
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.pipControlsChannel?.invokeMethod("togglePlayPause", arguments: nil)
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.pipControlsChannel?.invokeMethod("nextEpisode", arguments: nil)
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.pipControlsChannel?.invokeMethod("previousEpisode", arguments: nil)
            return .success
        }
    }

    /// Updates the MPNowPlayingInfoCenter so the system PiP overlay shows the
    /// correct play/pause icon.
    private func updateNowPlayingPlaybackState(isPlaying: Bool) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
    }
}
