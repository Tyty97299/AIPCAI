import SwiftUI
import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView: View {
    private static let sampleJSON = """
    {
      "id": "root",
      "type": "scrollview",
      "children": [
        {
          "id": "studio",
          "type": "vstack",
          "children": [
            {
              "id": "hero-icon",
              "type": "image",
              "systemImage": "sparkles",
              "color": "purple",
              "fontSize": 56
            },
            {
              "id": "title",
              "type": "text",
              "text": "AIPCAI Studio",
              "color": "primary",
              "fontSize": 32
            },
            {
              "id": "subtitle",
              "type": "text",
              "text": "Composez une interface native depuis du JSON.",
              "color": "gray",
              "fontSize": 17
            },
            {
              "id": "idea-field",
              "type": "textfield",
              "placeholder": "Nom de votre mini-app"
            },
            {
              "id": "actions",
              "type": "hstack",
              "children": [
                {
                  "id": "preview-button",
                  "type": "button",
                  "text": "Prévisualiser",
                  "color": "blue"
                },
                {
                  "id": "publish-button",
                  "type": "button",
                  "text": "Publier",
                  "color": "green"
                }
              ]
            }
          ]
        }
      ]
    }
    """

    @StateObject private var dynamicState = DynamicUIState()
    @State private var jsonText = Self.sampleJSON
    @State private var generatedJSON = Self.sampleJSON
    @FocusState private var isJSONEditorFocused: Bool

    var body: some View {
        TabView {
            NavigationStack {
                EditorView(
                    jsonText: $jsonText,
                    isFocused: $isJSONEditorFocused,
                    onGenerate: generatePreview
                )
                .navigationTitle("Éditeur JSON")
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Fermer") {
                            dismissKeyboard()
                        }
                    }
                }
            }
            .tabItem {
                Label("Éditeur JSON", systemImage: "curlybraces")
            }

            NavigationStack {
                LiveRenderView(jsonText: generatedJSON)
                    .navigationTitle("Rendu Live")
            }
            .tabItem {
                Label("Rendu Live", systemImage: "iphone")
            }
        }
        .environmentObject(dynamicState)
    }

    private func generatePreview() {
        generatedJSON = jsonText
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        isJSONEditorFocused = false
        UIApplication.shared.endEditing()
    }
}

private struct EditorView: View {
    private static let editorMinimumHeight: CGFloat = 300
    private static let bottomControlsReserve: CGFloat = 120

    @Binding var jsonText: String
    var isFocused: FocusState<Bool>.Binding
    let onGenerate: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    .onTapGesture(perform: dismissKeyboard)

                ScrollView {
                    VStack(spacing: 16) {
                        TextEditor(text: $jsonText)
                            .focused(isFocused)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .scrollContentBackground(.hidden)
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(
                                height: max(
                                    Self.editorMinimumHeight,
                                    proxy.size.height - Self.bottomControlsReserve
                                )
                            )
                            .layoutPriority(1)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 12) {
                Divider()

                Button(action: generatePreview) {
                    Label("Générer", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(.regularMaterial)
        }
    }

    private func generatePreview() {
        dismissKeyboard()
        onGenerate()
    }

    private func dismissKeyboard() {
        isFocused.wrappedValue = false
        UIApplication.shared.endEditing()
    }
}

private struct LiveRenderView: View {
    let jsonText: String

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.endEditing()
                }

            switch decodedComponent {
            case .success(let component):
                if component.type.lowercased() == "scrollview" {
                    componentPreview(component, fillsHeight: true)
                        .scrollDismissesKeyboard(.interactively)
                } else {
                    ScrollView {
                        componentPreview(component, fillsHeight: false)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }

            case .failure(let error):
                ScrollView {
                    VStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("JSON invalide")
                                .font(.headline)
                                .foregroundStyle(.red)

                            Text(Self.message(for: error))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }

    @ViewBuilder
    private func componentPreview(_ component: DynamicComponent, fillsHeight: Bool) -> some View {
        let maxHeight: CGFloat? = fillsHeight ? .infinity : nil

        UIInterpreterView(component: component)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .top)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .padding()
    }

    private var decodedComponent: Result<DynamicComponent, Error> {
        Result {
            let data = Data(jsonText.utf8)
            return try JSONDecoder().decode(DynamicComponent.self, from: data)
        }
    }

    private static func message(for error: Error) -> String {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                return "Le JSON est mal formé. \(context.debugDescription)"
            case .keyNotFound(let key, let context):
                return "Clé manquante: \(key.stringValue). \(context.debugDescription)"
            case .typeMismatch(let type, let context):
                return "Type incorrect pour \(type). \(context.debugDescription)"
            case .valueNotFound(let type, let context):
                return "Valeur manquante pour \(type). \(context.debugDescription)"
            @unknown default:
                return decodingError.localizedDescription
            }
        }

        return error.localizedDescription
    }
}

#Preview {
    ContentView()
}
