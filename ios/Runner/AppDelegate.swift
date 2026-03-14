import fl_pip
import Flutter
import UIKit
import AVKit
import AVFoundation

@main
@objc class AppDelegate: FlFlutterAppDelegate {

    private var pipControlsChannel: FlutterMethodChannel?
    private var pipController: AVPictureInPictureController?
    private var pipSampleLayer: AVSampleBufferDisplayLayer?
    private var pipContainerView: UIView?
    private var isPlayingState: Bool = true

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        setupAudioSession()

        if let controller = window?.rootViewController as? FlutterViewController {
            pipControlsChannel = FlutterMethodChannel(
                name: "com.ryan.anymex/pip_controls",
                binaryMessenger: controller.binaryMessenger
            )
            pipControlsChannel?.setMethodCallHandler { [weak self] call, result in
                guard let self = self else { return }
                switch call.method {
                case "updatePlaybackState":
                    if let args = call.arguments as? [String: Any],
                       let playing = args["isPlaying"] as? Bool {
                        self.isPlayingState = playing
                        self.pipController?.invalidatePlaybackState()
                    }
                    result(nil)
                case "setupNativePip":
                    self.setupNativePipController()
                    result(nil)
                case "startNativePip":
                    self.pipController?.startPictureInPicture()
                    result(nil)
                case "stopNativePip":
                    self.pipController?.stopPictureInPicture()
                    result(nil)
                default:
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func registerPlugin(_ registry: FlutterPluginRegistry) {
        GeneratedPluginRegistrant.register(with: registry)
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
    }

    private func setupNativePipController() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        guard let rootView = window?.rootViewController?.view else { return }

        if pipController != nil { return }

        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspect

        var timebase: CMTimebase?
        CMTimebaseCreateWithSourceClock(
            allocator: kCFAllocatorDefault,
            sourceClock: CMClockGetHostTimeClock(),
            timebaseOut: &timebase
        )
        if let tb = timebase {
            CMTimebaseSetTime(tb, time: .zero)
            CMTimebaseSetRate(tb, rate: 1.0)
            layer.controlTimebase = tb
        }

        enqueueDummyBuffer(into: layer)

        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        containerView.alpha = 0.01
        containerView.isUserInteractionEnabled = false
        containerView.layer.addSublayer(layer)
        rootView.addSubview(containerView)

        layer.frame = containerView.bounds

        pipSampleLayer = layer
        pipContainerView = containerView

        let source = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: layer,
            playbackDelegate: self
        )
        let controller = AVPictureInPictureController(contentSource: source)
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        controller.delegate = self
        pipController = controller
    }

    private func enqueueDummyBuffer(into layer: AVSampleBufferDisplayLayer) {
        let width = 16
        let height = 9
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            [kCVPixelBufferIOSurfacePropertiesKey: [:]] as CFDictionary,
            &pixelBuffer
        )
        guard let pb = pixelBuffer else { return }

        CVPixelBufferLockBaseAddress(pb, [])
        if let base = CVPixelBufferGetBaseAddress(pb) {
            memset(base, 0, CVPixelBufferGetDataSize(pb))
        }
        CVPixelBufferUnlockBaseAddress(pb, [])

        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pb,
            formatDescriptionOut: &formatDesc
        )
        guard let fd = formatDesc else { return }

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: .zero,
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pb,
            formatDescription: fd,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        guard let sb = sampleBuffer else { return }

        let attachments = CMSampleBufferGetSampleAttachmentsArray(sb, createIfNecessary: true)
        if let arr = attachments, CFArrayGetCount(arr) > 0,
           let dict = CFArrayGetValueAtIndex(arr, 0) {
            let mutableDict = dict as! CFMutableDictionary
            CFDictionarySetValue(
                mutableDict,
                Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
            )
        }
        layer.enqueue(sb)
    }
}

extension AppDelegate: AVPictureInPictureControllerDelegate {

    func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        pipControlsChannel?.invokeMethod("pipDidStart", arguments: nil)
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        pipControlsChannel?.invokeMethod("pipDidStop", arguments: nil)
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {}

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}

extension AppDelegate: AVPictureInPictureSampleBufferPlaybackDelegate {

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        setPlaying playing: Bool
    ) {
        if playing {
            pipControlsChannel?.invokeMethod("play", arguments: nil)
        } else {
            pipControlsChannel?.invokeMethod("pause", arguments: nil)
        }
    }

    func pictureInPictureControllerTimeRangeForPlayback(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> CMTimeRange {
        return CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(
        _ pictureInPictureController: AVPictureInPictureController
    ) -> Bool {
        return !isPlayingState
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {}

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime
    ) async {}
}
