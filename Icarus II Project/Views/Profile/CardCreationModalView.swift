import SwiftUI

struct CardCreationModalView: View {
    @Binding var isPresented: Bool
    let ownerName: String
    let onSave: (DeckCard) -> Void

    @State private var newCard: DeckCard
    
    init(isPresented: Binding<Bool>, ownerName: String, onSave: @escaping (DeckCard) -> Void) {
        self._isPresented = isPresented
        self.ownerName = ownerName
        self.onSave = onSave
        self._newCard = State(initialValue: DeckCard(
            title: "",
            ownerName: ownerName,
            category: "",
            dateText: "",
            location: "",
            color: Color(hex: "D8D8D8")
        ))
    }
    
    @State private var shakeTitleThrows = 0
    @State private var shakeCategoryThrows = 0
    @State private var shakeLocationThrows = 0

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                DottedBackground()
                VStack {
                    // Header
                    HStack {
                        // Dismiss Button
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: width * 0.05, weight: .bold))
                                .foregroundStyle(.red)
                                .frame(width: width * 0.12, height: width * 0.12)
                                .background(.white, in: Circle())
                                .shadow(radius: 5)
                        }
                        
                        Spacer()
                        
                        Text("Add a card")
                            .font(.custom("Nohemi-Medium", fixedSize: width * 0.08))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        // Confirm Button
                        Button {
                            if newCard.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                shakeTitleThrows += 1
                                return
                            }
                            if newCard.category.isEmpty {
                                shakeCategoryThrows += 1
                                return
                            }
                            if newCard.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                shakeLocationThrows += 1
                                return
                            }
                            onSave(newCard)
                            isPresented = false
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: width * 0.05, weight: .bold))
                                .foregroundStyle(.green)
                                .frame(width: width * 0.12, height: width * 0.12)
                                .background(.white, in: Circle())
                                .shadow(radius: 5)
                        }
                    }
                    .padding(.horizontal, width * 0.06)
                    .padding(.top, height * 0.06)
                    
                    Spacer()

                    // Card Editor
                    let cardWidth = width * 0.70
                    let cardHeight = min(width * 1.36, height * 0.6)
                    
                    EditableCardView(
                        card: $newCard,
                        width: cardWidth,
                        height: cardHeight,
                        shakeTitleThrows: $shakeTitleThrows,
                        shakeCategoryThrows: $shakeCategoryThrows,
                        shakeLocationThrows: $shakeLocationThrows
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .padding(.bottom, height * 0.05)

                    Spacer()
                }
            }
        }
    }
}
