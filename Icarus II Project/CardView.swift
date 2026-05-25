//
//  CardView.swift
//  Icarus II Project
//
//  Created by Aleksandra Stupiec on 22/05/26.
//

import SwiftUI

struct CardView: View {
    let card: Card
    var onRemove: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 24)

            Text(card.title)
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(card.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.82), in: Capsule())
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 440, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(white: 0.88))
        )
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
    }
}

struct AddEditCardView: View {
    @State private var draft: Card
    @State private var newTag: String = ""
    let onSave: (Card) -> Void
    let onCancel: () -> Void

    init(card: Card?, onSave: @escaping (Card) -> Void, onCancel: @escaping () -> Void) {
        if let card {
            _draft = State(initialValue: card)
        } else {
            // Placeholder ownerID until auth is wired — replaced with the real user id on save.
            _draft = State(initialValue: Card.draft(ownerID: UUID().uuidString))
        }
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    whatSection
                    tagsSection
                    whenSection
                    whereSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .floatingPanelSurface()
    }

    private var topBar: some View {
        HStack {
            Button { onCancel() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Capsule()
                .fill(Color(white: 0.75))
                .frame(width: 60, height: 5)

            Spacer()

            Button { onSave(draft) } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var whatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What?")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black.opacity(0.7))

            TextField("", text: $draft.title, axis: .vertical)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.black)
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(white: 0.82))
                )
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black.opacity(0.7))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(draft.tags, id: \.self) { tag in
                        Button {
                            draft.tags.removeAll { $0 == tag }
                        } label: {
                            HStack(spacing: 6) {
                                Text(tag)
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color(white: 0.82), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    TextField("Add", text: $newTag)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.82), in: Capsule())
                        .frame(width: 90)
                        .onSubmit(commitTag)
                        .submitLabel(.done)
                }
            }
        }
    }

    private func commitTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        draft.tags.append(trimmed)
        newTag = ""
    }

    private var whenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When?")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black.opacity(0.7))

            VStack(spacing: 0) {
                HStack {
                    Text("All day")
                        .font(.system(size: 16))
                        .foregroundStyle(.black)
                    Spacer()
                    Toggle("", isOn: $draft.allDay).labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Starts")
                        .font(.system(size: 16))
                        .foregroundStyle(.black)
                    Spacer()
                    DatePicker(
                        "",
                        selection: $draft.startDate,
                        displayedComponents: draft.allDay ? [.date] : [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                HStack {
                    Text("Ends")
                        .font(.system(size: 16))
                        .foregroundStyle(.black)
                    Spacer()
                    DatePicker(
                        "",
                        selection: $draft.endDate,
                        displayedComponents: draft.allDay ? [.date] : [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(white: 0.82))
            )
        }
    }

    private var whereSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where?")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.black.opacity(0.7))

            TextField("Location", text: $draft.location)
                .font(.system(size: 16))
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(white: 0.82))
                )
        }
    }
}

#Preview {
    CardView(card: Card(
        ownerID: UUID().uuidString,
        title: "Design a table",
        tags: ["Food", "Tommorow"],
        allDay: true,
        startDate: .now,
        endDate: .now,
        location: ""
    ))
    .padding()
}

#Preview("Add/Edit") {
    AddEditCardView(card: nil, onSave: { _ in }, onCancel: { })
        .padding()
        .background(Color(white: 0.6))
}

// MARK: - Floating panel

/// Styles a view as a floating panel: rounded background + soft shadow.
struct FloatingPanelSurface: ViewModifier {
    var cornerRadius: CGFloat = 28
    var fill: Color = Color(white: 0.94)

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
            )
            .shadow(color: .black.opacity(0.18), radius: 28, x: 0, y: 14)
    }
}

extension View {
    func floatingPanelSurface(cornerRadius: CGFloat = 28, fill: Color = Color(white: 0.94)) -> some View {
        modifier(FloatingPanelSurface(cornerRadius: cornerRadius, fill: fill))
    }
}

/// Presents an overlay above the modified view: a blurred backdrop plus the supplied
/// content centered with margins. Tap the backdrop to dismiss.
struct FloatingPanelModifier<Item: Identifiable, PanelContent: View>: ViewModifier {
    @Binding var item: Item?
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 60
    let panelContent: (Item) -> PanelContent

    func body(content: Content) -> some View {
        ZStack {
            content

            if item != nil {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { item = nil }
            }

            if let unwrapped = item {
                panelContent(unwrapped)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: item?.id)
    }
}

extension View {
    func floatingPanel<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 60,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(
            FloatingPanelModifier(
                item: item,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                panelContent: content
            )
        )
    }

    func floatingPanel<Content: View>(
        isPresented: Binding<Bool>,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 60,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let item = Binding<PresentationFlag?>(
            get: { isPresented.wrappedValue ? PresentationFlag() : nil },
            set: { isPresented.wrappedValue = $0 != nil }
        )
        return modifier(
            FloatingPanelModifier(
                item: item,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                panelContent: { _ in content() }
            )
        )
    }
}

private struct PresentationFlag: Identifiable {
    let id = "presented"
}
