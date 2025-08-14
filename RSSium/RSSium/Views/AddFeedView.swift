import SwiftUI

struct AddFeedView: View {
    @StateObject private var viewModel = AddFeedViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onAddFeed: (String, String?) async -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with icon
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 60, height: 60)
                                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                                    .symbolEffect(.bounce.byLayer, options: .speed(0.5).repeat(.continuous))
                            }
                            
                            Text("Add RSS Feed")
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        // Feed URL Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                
                                Text("Feed URL")
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                // Custom text field with better styling
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.systemGray6))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(
                                                    viewModel.isURLValid && viewModel.isValid 
                                                    ? LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                                                    : (viewModel.isURLValid && !viewModel.validationMessage.isEmpty && !viewModel.isValid)
                                                    ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                                    : LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
                                                    lineWidth: viewModel.isURLValid ? 2 : 1
                                                )
                                        }
                                    
                                    TextField("https://example.com/feed.xml", text: $viewModel.url)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
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
                                }
                                
                                // Validation feedback with enhanced styling
                                if viewModel.isValidating {
                                    HStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(0.9)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        
                                        Text("Validating feed...")
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.blue.opacity(0.1))
                                    }
                                } else if !viewModel.validationMessage.isEmpty {
                                    HStack(spacing: 8) {
                                        Image(systemName: viewModel.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(viewModel.isValid ? .green : .red)
                                            .symbolEffect(.bounce, value: viewModel.isValid)
                                        
                                        Text(viewModel.validationMessage)
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundColor(viewModel.isValid ? .green : .red)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill((viewModel.isValid ? Color.green : Color.red).opacity(0.1))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Feed Preview Section
                        if viewModel.isValid && !viewModel.previewTitle.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "eye.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.purple)
                                    
                                    Text("Feed Preview")
                                        .font(.system(.headline, design: .rounded, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    // Preview card
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.orange)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Feed Title")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundColor(.secondary)
                                                    .textCase(.uppercase)
                                                
                                                Text(viewModel.previewTitle)
                                                    .font(.system(.headline, design: .rounded, weight: .medium))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(2)
                                            }
                                        }
                                    }
                                    .padding(16)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(.regularMaterial)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                                            }
                                    }
                                    
                                    // Custom title option
                                    VStack(alignment: .leading, spacing: 12) {
                                        Toggle(isOn: $viewModel.useCustomTitle) {
                                            HStack {
                                                Image(systemName: "pencil.circle.fill")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(.blue)
                                                
                                                Text("Use custom title")
                                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                            }
                                        }
                                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                                        
                                        if viewModel.useCustomTitle {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(Color(.systemGray6))
                                                    .overlay {
                                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                                    }
                                                
                                                TextField("Enter custom title", text: $viewModel.customTitle)
                                                    .font(.system(.body, design: .rounded))
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 12)
                                            }
                                            .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.useCustomTitle)
                        }
                        
                        Spacer(minLength: 30)
                    }
                }
            }
.navigationBarHidden(true)
.safeAreaInset(edge: .bottom) {
                // Custom action buttons
                HStack(spacing: 16) {
                    // Cancel button
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemGray5))
                    }
                    
                    // Add button
                    Button {
                        Task {
                            await onAddFeed(viewModel.url, viewModel.useCustomTitle ? viewModel.customTitle : nil)
                            viewModel.reset()
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("Add Feed")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(viewModel.canSubmit 
                                     ? LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                     : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        }
                        .scaleEffect(viewModel.canSubmit ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.canSubmit)
                    }
                    .disabled(!viewModel.canSubmit)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.regularMaterial)
            }
        }
    }
}

#Preview {
    AddFeedView { url, title in
        print("Adding feed: \(url), title: \(title ?? "nil")")
    }
}