import SwiftUI

struct ProviderSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @FocusState private var focusedField: SettingsViewModel.Field?

    var body: some View {
        Form {
            Section {
                Picker("Provider", selection: $viewModel.selectedProvider) {
                    ForEach(AIProviderKind.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .foregroundStyle(.white)
                .onChange(of: viewModel.selectedProvider) { _, _ in
                    viewModel.markChanged()
                }
            } header: {
                Label("Provider", systemImage: "sparkles")
                    .foregroundStyle(.white)
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
                    .tint(AppColors.bright)
                    .disabled(!viewModel.hasChanges)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .onAppear {
            focusedField = .customBaseURL
            viewModel.load()
        }
        .onChange(of: viewModel.customBaseURL) {
            Task {
                await viewModel.fetchAvailableModels()
            }
        }
        .onChange(of: viewModel.customUseAuth) {
            Task {
                await viewModel.fetchAvailableModels()
            }
        }
        .onChange(of: viewModel.apiKey) {
            Task {
                await viewModel.fetchAvailableModels()
            }
        }
        .padding()
    }

    @ViewBuilder
    private var customProviderFields: some View {
        Section {
            TextField("Base URL", text: $viewModel.customBaseURL)
                .textContentType(.URL)
                .focused($focusedField, equals: .customBaseURL)
                .onChange(of: viewModel.customBaseURL) { _, _ in
                    viewModel.markChanged()
                    viewModel.connectionResult = nil
                }

            if viewModel.isFetchingModels {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Fetching models...")
                        .font(.footnote)
                        .foregroundStyle(AppColors.light)
                }
            } else if !viewModel.availableModels.isEmpty {
                Picker("Model", selection: $viewModel.customModel) {
                    ForEach(viewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .foregroundStyle(.white)
            } else {
                TextField("Model", text: $viewModel.customModel)
                    .focused($focusedField, equals: .customModel)
                    .onChange(of: viewModel.customModel) { _, _ in
                        viewModel.markChanged()
                        viewModel.connectionResult = nil
                    }

                Text("Enter model name or fetch from provider above.")
                    .font(.footnote)
                    .foregroundStyle(AppColors.light)
            }

            Toggle("Use API key", isOn: $viewModel.customUseAuth)
                .foregroundStyle(.white)
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
        } header: {
            Label("Custom Provider", systemImage: "gearshape")
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var genericProviderFields: some View {
        Section {
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
                .foregroundStyle(AppColors.light)
        } header: {
            Label("Provider Settings", systemImage: "key")
                .foregroundStyle(.white)
        }
    }
}