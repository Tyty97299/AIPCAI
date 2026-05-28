import SwiftUI

struct ContentView: View {
    @State private var jsonText = """
    {
      "id": "root",
      "type": "vstack",
      "children": [
        {
          "id": "title",
          "type": "text",
          "text": "Bienvenue dans AIPCAI",
          "color": "blue",
          "fontSize": 28
        },
        {
          "id": "subtitle",
          "type": "text",
          "text": "L'atelier de création dynamique",
          "color": "gray",
          "fontSize": 18
        },
        {
          "id": "main-button",
          "type": "button",
          "text": "Tester l'action",
          "color": "purple"
        }
      ]
    }
    """

    var body: some View {
        TabView {
            NavigationStack {
                TextEditor(text: $jsonText)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .navigationTitle("Éditeur JSON")
            }
            .tabItem {
                Label("Éditeur JSON", systemImage: "curlybraces")
            }

            NavigationStack {
                LiveRenderView(jsonText: jsonText)
                    .navigationTitle("Rendu Live")
            }
            .tabItem {
                Label("Rendu Live", systemImage: "iphone")
            }
        }
    }
}

private struct LiveRenderView: View {
    let jsonText: String

    var body: some View {
        ScrollView {
            Group {
                switch decodedComponent {
                case .success(let component):
                    UIInterpreterView(component: component)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()

                case .failure(let error):
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
                }
            }
            .frame(maxWidth: .infinity)
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
