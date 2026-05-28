import SwiftUI

struct DynamicComponent: Codable, Identifiable {
    let id: String
    let type: String
    let text: String?
    let color: String?
    let fontSize: CGFloat?
    let children: [DynamicComponent]?
}
