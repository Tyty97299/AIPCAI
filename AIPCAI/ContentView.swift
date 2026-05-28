import SwiftUI

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
                            isJSONEditorFocused = false
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
        isJSONEditorFocused = false
    }
}

private struct EditorView: View {
    @Binding var jsonText: String
    var isFocused: FocusState<Bool>.Binding
    let onGenerate: () -> Void

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button(action: onGenerate) {
                    Label("Générer", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
    }
}

private struct LiveRenderView: View {
    let jsonText: String

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            switch decodedComponent {
            case .success(let component):
                UIInterpreterView(component: component)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding()

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
            }
        }
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
