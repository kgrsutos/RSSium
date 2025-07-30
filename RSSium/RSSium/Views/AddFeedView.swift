import SwiftUI

struct AddFeedView: View {
    @StateObject private var viewModel = AddFeedViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onAddFeed: (String, String?) async -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Feed URL") {
                    TextField("Enter RSS feed URL", text: $viewModel.url)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.url) { _, _ in
                            if viewModel.isURLValid {
                                Task {
                                    await viewModel.validateFeed()
                                }
                            }
                        }
                    
                    if viewModel.isValidating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Validating feed...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if !viewModel.validationMessage.isEmpty {
                        Text(viewModel.validationMessage)
                            .font(.caption)
                            .foregroundColor(viewModel.isValid ? .green : .red)
                    }
                }
                
                if viewModel.isValid && !viewModel.previewTitle.isEmpty {
                    Section("Feed Preview") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title: \(viewModel.previewTitle)")
                                .font(.subheadline)
                            
                            Toggle("Use custom title", isOn: $viewModel.useCustomTitle)
                            
                            if viewModel.useCustomTitle {
                                TextField("Custom title", text: $viewModel.customTitle)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            await onAddFeed(viewModel.url, viewModel.useCustomTitle ? viewModel.customTitle : nil)
                            viewModel.reset()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
        }
    }
}

#Preview {
    AddFeedView { url, title in
        print("Adding feed: \(url), title: \(title ?? "nil")")
    }
}