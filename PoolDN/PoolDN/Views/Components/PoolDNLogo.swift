import SwiftUI

struct PoolDNLogo: View {
    var size: CGFloat = 120

    var body: some View {
        VStack(spacing: 16) {
            logoMark
                .frame(width: size, height: size)

            wordmark
        }
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        HStack(spacing: 2) {
            Text("Pool")
                .font(.system(size: 36, weight: .black, design: .default))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: 0xFFE99A), Color(hex: 0xC8991A), Color(hex: 0x8B6914)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            Text("DN")
                .font(.system(size: 36, weight: .black, design: .default))
                .foregroundColor(Color(hex: 0x2ECC71))
        }
    }

    // MARK: - Logo Mark (Canvas)

    private var logoMark: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 140.0

            // Felt circle (dark overlay)
            let feltCenter = CGPoint(x: 70 * s, y: 70 * s)
            let feltRadius = 54 * s
            var feltPath = Path()
            feltPath.addEllipse(in: CGRect(
                x: feltCenter.x - feltRadius,
                y: feltCenter.y - feltRadius,
                width: feltRadius * 2,
                height: feltRadius * 2
            ))
            context.fill(feltPath, with: .color(.black.opacity(0.3)))

            // Felt circle gold border
            context.stroke(feltPath, with: .color(Color(hex: 0xC8991A).opacity(0.4)), lineWidth: 1.5 * s)

            // Gold outer ring
            let ringRadius = 67 * s
            var ringPath = Path()
            ringPath.addEllipse(in: CGRect(
                x: feltCenter.x - ringRadius,
                y: feltCenter.y - ringRadius,
                width: ringRadius * 2,
                height: ringRadius * 2
            ))
            context.stroke(
                ringPath,
                with: .linearGradient(
                    Gradient(colors: [Color(hex: 0xF0C84A), Color(hex: 0xC8991A).opacity(0.4)]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height)
                ),
                lineWidth: 1.2 * s
            )

            // Cue stick
            drawCueStick(context: context, s: s)

            // 8-ball (center)
            drawBall(context: context, cx: 70 * s, cy: 70 * s, r: 20 * s,
                     colors: [Color(hex: 0x555555), Color(hex: 0x282828), Color(hex: 0x0A0A0A)])
            draw8BallStripe(context: context, s: s)

            // Gold ball (top-right)
            drawBall(context: context, cx: 96 * s, cy: 51 * s, r: 13 * s,
                     colors: [Color(hex: 0xFFE898), Color(hex: 0xC8991A), Color(hex: 0x6B4A00)])

            // Blue ball (bottom-left)
            drawBall(context: context, cx: 46 * s, cy: 91 * s, r: 13 * s,
                     colors: [Color(hex: 0xB8D8FF), Color(hex: 0x1566CC), Color(hex: 0x07224A)])

            // Cue ball (bottom-right)
            drawBall(context: context, cx: 96 * s, cy: 92 * s, r: 10 * s,
                     colors: [Color(hex: 0xFFFFFF), Color(hex: 0xE8E0D0), Color(hex: 0xACA090)])
        }
    }

    private func drawCueStick(context: GraphicsContext, s: CGFloat) {
        // Cue stick: rotated -30 degrees around (18*s, 60*s)
        let pivotX = 18 * s
        let pivotY = 60 * s
        let width = 105 * s
        let height = 5.5 * s
        let angle = Angle.degrees(-30)

        var cueContext = context
        cueContext.translateBy(x: pivotX, y: pivotY)
        cueContext.rotate(by: angle)

        let cueRect = CGRect(x: 0, y: 0, width: width, height: height)
        let cuePath = Path(roundedRect: cueRect, cornerRadius: height / 2)
        cueContext.fill(
            cuePath,
            with: .linearGradient(
                Gradient(colors: [Color(hex: 0xFFE99A), Color(hex: 0xC8991A), Color(hex: 0x3A2200)]),
                startPoint: .zero,
                endPoint: CGPoint(x: width, y: height)
            )
        )
    }

    private func drawBall(context: GraphicsContext, cx: CGFloat, cy: CGFloat, r: CGFloat, colors: [Color]) {
        // Shadow
        let shadowRect = CGRect(x: cx - r + r * 0.05, y: cy - r + r * 0.1, width: r * 2, height: r * 2)
        var shadowPath = Path()
        shadowPath.addEllipse(in: shadowRect)
        context.fill(shadowPath, with: .color(.black.opacity(0.2)))

        // Ball body with radial gradient
        let ballRect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
        var ballPath = Path()
        ballPath.addEllipse(in: ballRect)
        context.fill(
            ballPath,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: colors[0], location: 0.0),
                    .init(color: colors[1], location: 0.42),
                    .init(color: colors[2], location: 1.0)
                ]),
                center: CGPoint(x: cx - r * 0.15, y: cy - r * 0.2),
                startRadius: 0,
                endRadius: r
            )
        )

        // Highlight
        let hr = r * 0.25
        let hx = cx - r * 0.3
        let hy = cy - r * 0.35
        var highlightPath = Path()
        highlightPath.addEllipse(in: CGRect(x: hx - hr, y: hy - hr, width: hr * 2, height: hr * 2))
        context.fill(highlightPath, with: .color(.white.opacity(0.25)))
    }

    private func draw8BallStripe(context: GraphicsContext, s: CGFloat) {
        // Dark stripe band
        let stripeRect = CGRect(x: 50.5 * s, y: 63.5 * s, width: 39 * s, height: 13 * s)
        let stripePath = Path(roundedRect: stripeRect, cornerRadius: 6.5 * s)
        context.fill(stripePath, with: .color(Color(hex: 0x0A0A0A)))

        // "8" text
        let text = Text("8")
            .font(.system(size: 12.5 * s, weight: .black))
            .foregroundColor(.white)
        context.draw(context.resolve(text), at: CGPoint(x: 70 * s, y: 70 * s))
    }
}

// MARK: - Hex Color Helper

private extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
