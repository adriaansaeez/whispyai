import SwiftUI

struct ProviderSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @FocusState private var focusedField: SettingsViewModel.Field?

    var body: some View {
        Form {
            Picker("Provider", selection: $viewModel.selectedProvider) {
                ForEach(AIProviderKind.allCases) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .onChange(of: viewModel.selectedProvider) { _, _ in
                viewModel.markChanged()
            }

            if viewModel.selectedProvider == .custom {
                customProviderFields
            } else {
                genericProviderFields
            }

            if let result = viewModel.connectionResult {
                Section {
                    Text(result)
                        .font(.footnote)
                        .foregroundStyle(result.contains("OK") ? .green : .red)
                }
            }

            Section {
                HStack {
                    Spacer()
                    Button("Guardar") {
                        viewModel.save()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.hasChanges)
                }
            }
        }
        .onAppear {
            focusedField = .customBaseURL
        }
    }

    @ViewBuilder
    private var customProviderFields: some View {
        Section("Custom Provider") {
            TextField("Base URL", text: $viewModel.customBaseURL)
                .textContentType(.URL)
                .focused($focusedField, equals: .customBaseURL)
                .onChange(of: viewModel.customBaseURL) { _, _ in
                    viewModel.markChanged()
                    viewModel.connectionResult = nil
                }

            TextField("Model", text: $viewModel.customModel)
                .focused($focusedField, equals: .customModel)
                .onChange(of: viewModel.customModel) { _, _ in
                    viewModel.markChanged()
                    viewModel.connectionResult = nil
                }

            Toggle("Use API key", isOn: $viewModel.customUseAuth)
                .onChange(of: viewModel.customUseAuth) { _, _ in
                    viewModel.markChanged()
                    viewModel.connectionResult = nil
                }

            if viewModel.customUseAuth {
                SecureField("API Key", text: $viewModel.apiKey)
                    .focused($focusedField, equals: .apiKey)
                    .onChange(of: viewModel.apiKey) { _, _ in
                        viewModel.markChanged()
                        viewModel.connectionResult = nil
                    }
            }

            Button("Comprobar conexión") {
                Task {
                    await viewModel.testConnection()
                }
            }
            .disabled(viewModel.isTestingConnection)
            .overlay(alignment: .trailing) {
                if viewModel.isTestingConnection {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                }
            }
        }
    }

    @ViewBuilder
    private var genericProviderFields: some View {
        Section("Provider Settings") {
            TextField("Model", text: $viewModel.selectedModel)
                .focused($focusedField, equals: .customModel)
                .onChange(of: viewModel.selectedModel) { _, _ in
                    viewModel.markChanged()
                    viewModel.connectionResult = nil
                }

            SecureField("API Key", text: $viewModel.apiKey)
                .focused($focusedField, equals: .apiKey)
                .onChange(of: viewModel.apiKey) { _, _ in
                    viewModel.markChanged()
                    viewModel.connectionResult = nil
                }

            Text("OpenAI will be implemented in a future version.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
