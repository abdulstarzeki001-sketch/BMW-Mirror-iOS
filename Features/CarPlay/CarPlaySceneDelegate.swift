import UIKit
import CarPlay

@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private weak var interfaceController: CPInterfaceController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        NotificationCenter.default.post(
            name: .bmwMirrorCarPlaySceneDidConnect,
            object: templateApplicationScene
        )

        let captureItem = CPListItem(
            text: "Full Display Capture",
            detailText: "ScreenCaptureKit • iOS 27+"
        )
        captureItem.isEnabled = false

        let pipelineItem = CPListItem(
            text: "Media Pipeline",
            detailText: "30 FPS target • 1280px max edge"
        )
        pipelineItem.isEnabled = false

        let airPlayItem = CPListItem(
            text: "AirPlay Video Output",
            detailText: "Pending implementation"
        )
        airPlayItem.isEnabled = false

        let vehicleItem = CPListItem(
            text: "Target Vehicle",
            detailText: "BMW X6 2025"
        )
        vehicleItem.isEnabled = false

        let statusSection = CPListSection(
            items: [captureItem, pipelineItem, airPlayItem, vehicleItem],
            header: "BMW Mirror",
            sectionIndexTitle: nil
        )

        let rootTemplate = CPListTemplate(
            title: "BMW Mirror",
            sections: [statusSection]
        )

        interfaceController.setRootTemplate(rootTemplate, animated: false) { success, error in
            if let error {
                print("BMW Mirror CarPlay root template error: \(error.localizedDescription)")
                return
            }

            print("BMW Mirror CarPlay root template ready: \(success)")
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil

        NotificationCenter.default.post(
            name: .bmwMirrorCarPlaySceneDidDisconnect,
            object: templateApplicationScene
        )

        print("BMW Mirror CarPlay scene disconnected")
    }
}
