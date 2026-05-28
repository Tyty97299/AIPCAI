import SwiftUI

struct DynamicComponent: Codable, Identifiable {
    let id: String
    let type: String
    let text: String?
    let color: String?
    let fontSize: CGFloat?
    let systemImage: String?
    let placeholder: String?
    let children: [DynamicComponent]?
}

final class DynamicUIState: ObservableObject {
    @Published private var textValues: [String: String] = [:]

    func binding(for componentID: String) -> Binding<String> {
        Binding(
            get: { self.textValues[componentID, default: ""] },
            set: { self.textValues[componentID] = $0 }
        )
    }
}
