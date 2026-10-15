import SwiftUI

struct TreeCanvas: View {
    let rootLength: Double
    let rootSpread: Double
    let level: Int

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08)) { timeline in
            Canvas { context, size in
                drawTree(in: &context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    AppPalette.panelLight.opacity(0.82),
                    AppPalette.panel.opacity(0.45),
                    AppPalette.background.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .topLeading) {
            CapsuleLabel(text: "Живая система", color: AppPalette.mint)
                .padding(18)
        }
        .overlay(alignment: .bottomTrailing) {
            VStack(alignment: .trailing, spacing: 3) {
                Text("УРОВЕНЬ \(level)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(AppPalette.muted)
                Text("корни просыпаются")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(18)
        }
    }

    private func drawTree(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        let centerX = size.width / 2
        let groundY = size.height * 0.37
        let lengthFactor = min(1, max(0.28, rootLength / 75))
        let spreadFactor = min(1.18, max(0.28, rootSpread / 48))
        let breath = CGFloat(sin(time * 1.5) * 0.012)

        let glowRect = CGRect(x: centerX - 95, y: 12, width: 190, height: 190)
        context.fill(Path(ellipseIn: glowRect), with: .color(AppPalette.mint.opacity(0.055)))

        let skyLine = Path(CGRect(x: 0, y: 0, width: size.width, height: groundY + 1))
        context.fill(skyLine, with: .color(AppPalette.mint.opacity(0.018)))

        drawCanopy(in: &context, centerX: centerX, groundY: groundY, breath: breath)
        drawTrunk(in: &context, centerX: centerX, groundY: groundY, breath: breath)

        let soilRect = CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)
        context.fill(Path(soilRect), with: .color(AppPalette.soil.opacity(0.77)))

        var horizon = Path()
        horizon.move(to: CGPoint(x: 0, y: groundY))
        horizon.addCurve(
            to: CGPoint(x: size.width, y: groundY + 3),
            control1: CGPoint(x: size.width * 0.3, y: groundY - 5),
            control2: CGPoint(x: size.width * 0.7, y: groundY + 8)
        )
        context.stroke(horizon, with: .color(AppPalette.mint.opacity(0.18)), lineWidth: 1)

        let rootCount = 9 + min(level, 5)
        for index in 0..<rootCount {
            let normalized = CGFloat(index) / CGFloat(max(1, rootCount - 1))
            let offset = normalized * 2 - 1
            let direction = CGFloat((index % 2 == 0) ? 1 : -1)
            let endX = centerX + offset * size.width * 0.40 * CGFloat(spreadFactor)
            let depth = 0.34 + CGFloat((index * 13) % 53) / 100
            let endY = groundY + (size.height - groundY - 19) * CGFloat(lengthFactor) * depth

            var rootPath = Path()
            rootPath.move(to: CGPoint(x: centerX + offset * 5, y: groundY + 2))
            rootPath.addCurve(
                to: CGPoint(x: endX, y: endY),
                control1: CGPoint(x: centerX + offset * 24, y: groundY + 24),
                control2: CGPoint(x: endX - direction * 26, y: endY - 32)
            )
            context.stroke(
                rootPath,
                with: .color(AppPalette.root.opacity(0.62 + Double(index % 3) * 0.08)),
                lineWidth: CGFloat(1.6 + (index % 3 == 0 ? 1.2 : 0))
            )

            let branchProgress = CGFloat(0.45 + Double(index % 4) * 0.08)
            let branchStart = CGPoint(
                x: centerX + (endX - centerX) * branchProgress,
                y: groundY + (endY - groundY) * branchProgress
            )
            var hairPath = Path()
            hairPath.move(to: branchStart)
            hairPath.addCurve(
                to: CGPoint(x: branchStart.x + direction * 22, y: branchStart.y + 19),
                control1: CGPoint(x: branchStart.x + direction * 5, y: branchStart.y + 4),
                control2: CGPoint(x: branchStart.x + direction * 12, y: branchStart.y + 15)
            )
            context.stroke(hairPath, with: .color(AppPalette.root.opacity(0.38)), lineWidth: 1)

            context.fill(
                Path(ellipseIn: CGRect(x: endX - 2.5, y: endY - 2.5, width: 5, height: 5)),
                with: .color(AppPalette.sand.opacity(0.88))
            )
        }

        for index in 0..<5 {
            let x = size.width * (0.14 + CGFloat(index) * 0.19)
            let y = groundY + 27 + CGFloat((index * 23) % 50)
            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                with: .color(AppPalette.muted.opacity(0.28))
            )
        }
    }

    private func drawTrunk(in context: inout GraphicsContext, centerX: CGFloat, groundY: CGFloat, breath: CGFloat) {
        var trunk = Path()
        trunk.move(to: CGPoint(x: centerX - 7, y: groundY + 8))
        trunk.addCurve(
            to: CGPoint(x: centerX + 8, y: 82),
            control1: CGPoint(x: centerX - 12, y: groundY - 32),
            control2: CGPoint(x: centerX + 13, y: 116)
        )
        trunk.addLine(to: CGPoint(x: centerX - 1, y: 78))
        trunk.addCurve(
            to: CGPoint(x: centerX - 7, y: groundY + 8),
            control1: CGPoint(x: centerX - 8, y: 122),
            control2: CGPoint(x: centerX - 12, y: groundY - 16)
        )
        trunk.closeSubpath()
        context.fill(trunk, with: .color(AppPalette.root.opacity(0.92)))

        var branch = Path()
        branch.move(to: CGPoint(x: centerX + 2, y: 103))
        branch.addCurve(
            to: CGPoint(x: centerX + 44, y: 70 + breath * 20),
            control1: CGPoint(x: centerX + 17, y: 96),
            control2: CGPoint(x: centerX + 27, y: 76)
        )
        context.stroke(branch, with: .color(AppPalette.root.opacity(0.85)), lineWidth: 3)

        var branchLeft = Path()
        branchLeft.move(to: CGPoint(x: centerX - 2, y: 116))
        branchLeft.addCurve(
            to: CGPoint(x: centerX - 39, y: 84 - breath * 18),
            control1: CGPoint(x: centerX - 18, y: 108),
            control2: CGPoint(x: centerX - 25, y: 91)
        )
        context.stroke(branchLeft, with: .color(AppPalette.root.opacity(0.82)), lineWidth: 3)
    }

    private func drawCanopy(in context: inout GraphicsContext, centerX: CGFloat, groundY: CGFloat, breath: CGFloat) {
        let leaves: [(CGFloat, CGFloat, CGFloat)] = [
            (-42, 76, 30), (-18, 49, 34), (13, 54, 36), (40, 76, 28),
            (-2, 24, 31), (-30, 34, 23), (29, 37, 25), (0, 76, 39)
        ]

        for (index, leaf) in leaves.enumerated() {
            let drift = index.isMultiple(of: 2) ? breath * 22 : -breath * 18
            let rect = CGRect(
                x: centerX + leaf.0 - leaf.2,
                y: leaf.1 + drift,
                width: leaf.2 * 2,
                height: leaf.2 * 1.55
            )
            let color = index.isMultiple(of: 3) ? AppPalette.lime : AppPalette.mint
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.70 + Double(index % 3) * 0.06)))
        }

        let crownLine = Path(ellipseIn: CGRect(x: centerX - 48, y: 43, width: 96, height: 80))
        context.stroke(crownLine, with: .color(AppPalette.mint.opacity(0.12)), lineWidth: 1)
    }
}