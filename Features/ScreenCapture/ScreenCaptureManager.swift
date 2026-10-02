import Foundation
import Combine
import ReplayKit
import CoreImage
import CoreMedia
import CoreGraphics

@MainActor
final class ScreenCaptureManager: ObservableObject {
    @Published private(set) var isCapturing = false
    @Published private(set) var latestFrame: CGImage?
    @Published private(set) var frameCount = 0
    @Published private(set) var frameSizeText = "—"
    @Published private(set) var statusText = "جاهز"
    @Published private(set) var errorText: String?

    private let recorder = RPScreenRecorder.shared()
    private let ciContext = CIContext()

    init() {
        recorder.isMicrophoneEnabled = false
    }

    func toggleCapture() {
        isCapturing ? stopCapture() : startCapture()
    }

    func startCapture() {
        guard recorder.isAvailable else {
            statusText = "التقاط الشاشة غير متاح"
            errorText = "iOS لا يسمح بالتقاط الشاشة حاليًا على هذا الجهاز."
            return
        }

        errorText = nil
        statusText = "طلب إذن الالتقاط…"
        frameCount = 0

        recorder.startCapture(
            handler: { [weak self] sampleBuffer, sampleType, error in
                guard let self else { return }

                if let error {
                    Task { @MainActor in
                        self.handleCaptureError(error)
                    }
                    return
                }

                guard
                    sampleType == .video,
                    let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                else {
                    return
                }

                let ciImage = CIImage(cvImageBuffer: imageBuffer)
                let extent = ciImage.extent

                guard let cgImage = self.ciContext.createCGImage(ciImage, from: extent) else {
                    return
                }

                Task { @MainActor in
                    self.latestFrame = cgImage
                    self.frameCount += 1
                    self.frameSizeText = "\(Int(extent.width)) × \(Int(extent.height))"
                }
            },
            completionHandler: { [weak self] error in
                guard let self else { return }

                Task { @MainActor in
                    if let error {
                        self.handleCaptureError(error)
                        return
                    }

                    self.isCapturing = true
                    self.statusText = "يتم التقاط شاشة التطبيق"
                }
            }
        )
    }

    func stopCapture() {
        guard isCapturing else { return }

        statusText = "جارٍ إيقاف الالتقاط…"

        recorder.stopCapture { [weak self] error in
            guard let self else { return }

            Task { @MainActor in
                if let error {
                    self.handleCaptureError(error)
                    return
                }

                self.isCapturing = false
                self.statusText = "متوقف"
            }
        }
    }

    private func handleCaptureError(_ error: Error) {
        isCapturing = false
        statusText = "حدث خطأ"
        errorText = error.localizedDescription
    }
}
