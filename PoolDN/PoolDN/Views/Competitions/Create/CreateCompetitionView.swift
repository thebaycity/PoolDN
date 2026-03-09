import SwiftUI

struct CreateCompetitionView: View {
    @Bindable var appState: AppState
    @State private var viewModel = CompetitionCreateViewModel()
    @Environment(\.dismiss) private var dismiss

    private let steps: [(title: String, icon: String, subtitle: String)] = [
        ("Info",      "doc.text",       "Name, location & date"),
        ("Teams",     "person.2",       "Participant settings"),
        ("Structure", "list.bullet",    "Match game format"),
        ("Schedule",  "calendar.badge.checkmark", "Venue & rounds")
    ]

    var body: some View {
        VStack(spacing: 0) {
            stepHeader
            Divider().overlay(Color.theme.separator)

            TabView(selection: $viewModel.currentStep) {
                BasicInfoStep(viewModel: viewModel).tag(0)
                ParticipantsStep(viewModel: viewModel).tag(1)
                StructureStep(viewModel: viewModel).tag(2)
                ScheduleReviewStep(viewModel: viewModel).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)

            Divider().overlay(Color.theme.separator)
            navBar
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

    // MARK: - Step Header

    private var stepHeader: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Color.theme.surfaceLight
                        .frame(height: 3)
                    Color.theme.accent
                        .frame(width: geo.size.width * CGFloat(viewModel.currentStep + 1) / CGFloat(steps.count), height: 3)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                }
            }
            .frame(height: 3)

            // Step pills row
            HStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    let isDone = index < viewModel.currentStep
                    let isCurrent = index == viewModel.currentStep

                    Button {
                        if index <= viewModel.currentStep {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.currentStep = index
                            }
                        }
                    } label: {
                        VStack(spacing: 5) {
                            ZStack {
                                Circle()
                                    .fill(isDone ? Color.theme.accentGreen :
                                          isCurrent ? Color.theme.accent :
                                          Color.theme.surfaceLight)
                                    .frame(width: 28, height: 28)

                                if isDone {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: step.icon)
                                        .font(.caption2)
                                        .foregroundColor(isCurrent ? .white : Color.theme.textTertiary)
                                }
                            }

                            Text(step.title)
                                .font(.caption2)
                                .fontWeight(isCurrent ? .semibold : .regular)
                                .foregroundColor(isCurrent ? Color.theme.accent :
                                                 isDone ? Color.theme.accentGreen :
                                                 Color.theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .disabled(index > viewModel.currentStep)
                    .buttonStyle(.plain)

                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < viewModel.currentStep ? Color.theme.accentGreen.opacity(0.4) : Color.theme.border)
                            .frame(height: 1)
                            .frame(maxWidth: 20)
                            .offset(y: -8)
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color.theme.surface)

            // Current step subtitle
            HStack(spacing: 6) {
                Image(systemName: steps[viewModel.currentStep].icon)
                    .font(.caption)
                    .foregroundColor(Color.theme.accent)
                Text(steps[viewModel.currentStep].subtitle)
                    .font(.caption)
                    .foregroundColor(Color.theme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 6)
            .background(Color.theme.accent.opacity(0.04))
        }
    }

    // MARK: - Navigation Bar

    private var navBar: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { viewModel.currentStep -= 1 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.caption.bold())
                        Text("Back")
                    }
                    .secondaryButton()
                }
                .frame(maxWidth: 110)
            }

            if viewModel.currentStep < steps.count - 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { viewModel.currentStep += 1 }
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right").font(.caption.bold())
                    }
                    .primaryButton()
                }
            } else {
                Button {
                    Task {
                        if await viewModel.createAndPublish() != nil {
                            dismiss()
                        }
                    }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Label("Publish Competition", systemImage: "checkmark.circle.fill")
                        }
                    }
                    .primaryButton()
                }
                .disabled(viewModel.isLoading || viewModel.name.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.theme.surface)
    }
}
