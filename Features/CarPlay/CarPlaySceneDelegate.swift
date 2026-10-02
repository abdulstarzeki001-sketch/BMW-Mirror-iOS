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

        let pipelineItem = CPListItem(
            text: "Media Pipeline",
            detailText: "30 FPS target • 1280px max edge"
        )
        pipelineItem.isEnabled = false

        let captureItem = CPListItem(
            text: "Screen Capture",
            detailText: "Prepared on iPhone"
        )
        captureItem.isEnabled = false

        let vehicleItem = CPListItem(
            text: "Target Vehicle",
            detailText: "BMW X6 2025"
        )
        vehicleItem.isEnabled = false

        let statusSection = CPListSection(
            items: [pipelineItem, captureItem, vehicleItem],
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
        print("BMW Mirror CarPlay scene disconnected")
    }
}
