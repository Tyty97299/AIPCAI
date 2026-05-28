import SwiftUI

struct UIInterpreterView: View {
    let component: DynamicComponent

    @State private var isShowingButtonAlert = false

    var body: some View {
        render(component)
    }

    @ViewBuilder
    private func render(_ component: DynamicComponent) -> some View {
        switch component.type.lowercased() {
        case "text":
            Text(component.text ?? "")
                .font(.system(size: component.fontSize ?? 17))
                .foregroundStyle(color(from: component.color))

        case "button":
            Button(component.text ?? "Bouton") {
                isShowingButtonAlert = true
            }
            .buttonStyle(.borderedProminent)
            .tint(color(from: component.color))
            .alert("Action déclenchée", isPresented: $isShowingButtonAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(component.text ?? "Bouton")
            }

        case "vstack":
            VStack(spacing: 16) {
                ForEach(component.children ?? []) { child in
                    UIInterpreterView(component: child)
                }
            }

        case "spacer":
            Spacer()

        default:
            Text("Type inconnu: \(component.type)")
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }

    private func color(from name: String?) -> Color {
        switch name?.lowercased() {
        case "black":
            return .black
        case "blue":
            return .blue
        case "cyan":
            return .cyan
        case "gray", "grey":
            return .gray
        case "green":
            return .green
        case "indigo":
            return .indigo
        case "mint":
            return .mint
        case "orange":
            return .orange
        case "pink":
            return .pink
        case "purple":
            return .purple
        case "red":
            return .red
        case "teal":
            return .teal
        case "white":
            return .white
        case "yellow":
            return .yellow
        default:
            return .primary
        }
    }
}
