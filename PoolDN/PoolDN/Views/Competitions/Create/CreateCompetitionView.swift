import SwiftUI

struct CreateCompetitionView: View {
    @Bindable var appState: AppState
    @State private var viewModel = CompetitionCreateViewModel()
    @Environment(\.dismiss) private var dismiss

    private let stepTitles = ["Info", "Teams", "Structure", "Schedule"]

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator — capsule pills
            HStack(spacing: 4) {
                ForEach(0..<4) { step in
                    Text(stepTitles[step])
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(step <= viewModel.currentStep ? Color.theme.accent : Color.theme.surfaceLight)
                        .foregroundColor(step <= viewModel.currentStep ? .white : Color.theme.textTertiary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.theme.surface)

            Divider().overlay(Color.theme.separator)

            TabView(selection: $viewModel.currentStep) {
                BasicInfoStep(viewModel: viewModel).tag(0)
                ParticipantsStep(viewModel: viewModel).tag(1)
                StructureStep(viewModel: viewModel).tag(2)
                ScheduleReviewStep(viewModel: viewModel).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Navigation buttons
            HStack(spacing: 12) {
                if viewModel.currentStep > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { viewModel.currentStep -= 1 }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                            Text("Back")
                        }
                        .secondaryButton()
                    }
                }

                if viewModel.currentStep < 3 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { viewModel.currentStep += 1 }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .primaryButton()
                    }
                } else {
                    Button {
                        Task {
                            if let _ = await viewModel.createAndPublish() {
                                dismiss()
                            }
                        }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Create Competition")
                                }
                            }
                        }
                        .primaryButton()
                    }
                    .disabled(viewModel.isLoading || viewModel.name.isEmpty)
                }
            }
            .padding(16)
            .background(Color.theme.surface)
        }
        .background(Color.theme.background)
        .navigationTitle("New Competition")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
