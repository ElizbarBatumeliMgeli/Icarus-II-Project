//
//  CircleButton.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct CircleIconButton: View {
    let systemName: String
    let size: CGFloat
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .regular))
                .foregroundStyle(Color(hex: "222222"))
                .frame(width: size, height: size)
                .background(.white.opacity(0.88), in: Circle())
                .glassEffect(.regular, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
