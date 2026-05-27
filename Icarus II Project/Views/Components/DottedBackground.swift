//
//  DottedBackground.swift
//  test1123
//
//  Created by Elizbar Kheladze on 25/05/26.
//

import SwiftUI

struct DottedBackground: View {
    var baseColor: Color = .black
    // Use a solid dotColor; opacity will be computed per-dot.
    var dotColor: Color = .gray
    // Spacing and size controls
    var spacing: CGFloat = 20
    var maxDotDiameter: CGFloat = 3
    var minDotDiameter: CGFloat = 3
    // Opacity will fade with vertical position (bottom -> top)
    var startOpacity: Double = 0.33
    var endOpacity: Double = 0.33
    // Adjust the curve of the gradient (1.0 = linear)
    var exponent: Double = 1.0

    var body: some View {
        ZStack {
            baseColor
            Canvas { context, size in
                let h = size.height

                var y: CGFloat = 0
                while y <= h {
                    // Normalize from bottom (0) to top (1)
                    let tyRaw = Double(1.0 - (y / h))
                    let ty = max(0.0, min(1.0, tyRaw))
                    let t = pow(ty, exponent)

                    var x: CGFloat = 0
                    while x <= size.width {
                        let diameterDouble = (1.0 - t) * Double(maxDotDiameter) + t * Double(minDotDiameter)
                        let alpha = (1.0 - t) * startOpacity + t * endOpacity
                        let diameter = CGFloat(diameterDouble)

                        let rect = CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter)
                        context.fill(Path(ellipseIn: rect), with: .color(dotColor.opacity(alpha)))

                        x += spacing
                    }
                    y += spacing
                }
            }
        }
        .ignoresSafeArea()
    }
}
