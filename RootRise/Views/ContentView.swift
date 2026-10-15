import SwiftUI

struct ContentView: View {
    @StateObject private var game = GameState()
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .grove

    var body: some View {
        ZStack {
            AppPalette.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .grove:
                        GroveView(game: game)
                    case .upgrades:
                        UpgradesView(game: game)
                    case .journal:
                        JournalView(game: game)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                AppTabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            game.tick()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background || phase == .inactive {
                game.save()
            }
        }
        .overlay {
            if let summary = game.offlineSummary {
                OfflineGrowthCard(summary: summary) {
                    game.dismissOfflineSummary()
                }
            }
        }
    }
}

private enum AppTab: String, CaseIterable {
    case grove
    case upgrades
    case journal

    var title: String {
        switch self {
        case .grove: return "Роща"
        case .upgrades: return "Улучшения"
        case .journal: return "Дневник"
        }
    }

    var icon: String {
        switch self {
        case .grove: return "leaf.fill"
        case .upgrades: return "arrow.up.circle.fill"
        case .journal: return "book.closed.fill"
        }
    }
}

private struct GroveView: View {
    @ObservedObject var game: GameState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView(game: game)

                TreeCanvas(rootLength: game.rootLength, rootSpread: game.rootSpread, level: game.level)
                    .frame(height: 355)

                ResourceRow(game: game)

                GrowthProgress(game: game)

                SectionTitle(title: "Питание дерева", detail: "Трать солнечный свет на рост")
                UpgradeList(game: game, limit: 3)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 22)
        }
    }
}

private struct HeaderView: View {
    @ObservedObject var game: GameState

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("ROOTRISE")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(.white)
                Text("Вырасти. Углубись. Соединись.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppPalette.muted)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 5) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppPalette.sand)
                    Text(game.sunlight.compactString())
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text("+\(game.sunlightPerSecond.compactString()) / сек")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppPalette.sand.opacity(0.78))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(AppPalette.panel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct ResourceRow: View {
    @ObservedObject var game: GameState

    var body: some View {
        HStack(spacing: 10) {
            ResourceTile(
                icon: "arrow.down.right",
                value: "\(game.rootLength.compactString()) m",
                label: "длина корней",
                tint: AppPalette.root
            )
            ResourceTile(
                icon: "arrow.left.and.right",
                value: "\(game.rootSpread.compactString()) m",
                label: "размах сети",
                tint: AppPalette.mint
            )
            ResourceTile(
                icon: "chart.line.uptrend.xyaxis",
                value: "ур. \(game.level)",
                label: "стадия роста",
                tint: AppPalette.lime
            )
        }
    }
}

private struct ResourceTile: View {
    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(AppPalette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppPalette.panel, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

private struct GrowthProgress: View {
    @ObservedObject var game: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("СЛЕДУЮЩАЯ СТАДИЯ")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(AppPalette.muted)
                    Text("Пробуждение боковых ветвей")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("\(Int(game.levelProgress * 100))%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.mint)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppPalette.background)
                    Capsule()
                        .fill(LinearGradient(colors: [AppPalette.mint, AppPalette.lime], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, proxy.size.width * game.levelProgress))
                }
            }
            .frame(height: 7)
        }
        .padding(16)
        .background(AppPalette.panel, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct SectionTitle: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(detail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppPalette.muted)
        }
    }
}

private struct UpgradeList: View {
    @ObservedObject var game: GameState
    let limit: Int?

    var upgrades: [Upgrade] {
        if let limit {
            return Array(Upgrade.allCases.prefix(limit))
        }
        return Upgrade.allCases
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(upgrades) { upgrade in
                UpgradeRow(upgrade: upgrade, game: game)
            }
        }
    }
}

private struct UpgradeRow: View {
    let upgrade: Upgrade
    @ObservedObject var game: GameState

    private var canBuy: Bool { game.sunlight >= Double(game.cost(for: upgrade)) }

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: upgrade.symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppPalette.mint)
                .frame(width: 42, height: 42)
                .background(AppPalette.mint.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(upgrade.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if game.upgradeLevel(for: upgrade) > 0 {
                        Text("ур. \(game.upgradeLevel(for: upgrade))")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.lime)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppPalette.lime.opacity(0.12), in: Capsule())
                    }
                }
                Text(upgrade.subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppPalette.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Button {
                game.buy(upgrade)
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(game.cost(for: upgrade))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(canBuy ? AppPalette.sand : AppPalette.muted.opacity(0.55))
                .frame(width: 49, height: 43)
                .background((canBuy ? AppPalette.sand : AppPalette.muted).opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canBuy)
        }
        .padding(11)
        .background(AppPalette.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct UpgradesView: View {
    @ObservedObject var game: GameState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: "Улучшения", detail: "Направь энергию в нужную сторону")

                HStack(spacing: 10) {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(AppPalette.sand)
                    Text("Доступно \(game.sunlight.compactString()) солнечного света")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(15)
                .background(AppPalette.sand.opacity(0.09), in: RoundedRectangle(cornerRadius: 17, style: .continuous))

                UpgradeList(game: game, limit: nil)
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 22)
        }
    }
}

private struct JournalView: View {
    @ObservedObject var game: GameState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(title: "Дневник роста", detail: "История твоей подземной сети")

                VStack(alignment: .leading, spacing: 16) {
                    JournalStat(title: "Текущая глубина", value: "\(game.rootLength.compactString()) м", icon: "arrow.down.right", color: AppPalette.root)
                    JournalStat(title: "Площадь влияния", value: "\(game.rootSpread.compactString()) м", icon: "circle.dotted", color: AppPalette.mint)
                    JournalStat(title: "Скорость обмена", value: "+\(game.sunlightPerSecond.compactString()) / сек", icon: "sun.max.fill", color: AppPalette.sand)
                }
                .padding(17)
                .background(AppPalette.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    CapsuleLabel(text: "наблюдение 0\(game.level)", color: AppPalette.lime)
                    Text(journalText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineSpacing(5)
                }
                .padding(18)
                .background(AppPalette.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .padding(.bottom, 22)
        }
    }

    private var journalText: String {
        switch game.level {
        case 1: return "Первые корни нашли мягкую землю. Дерево собирает солнечный свет и переводит его в движение вниз."
        case 2...4: return "Под землёй появляется сеть. Каждый новый отросток находит собственный путь к воде и питательным веществам."
        default: return "Корневая система стала настоящей экосистемой. Её связи уходят далеко за пределы кроны."
        }
    }
}

private struct JournalStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30)
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppPalette.muted)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

private struct PageHeader: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 29, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(detail)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppPalette.muted)
        }
    }
}

private struct AppTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selectedTab == tab ? AppPalette.mint : AppPalette.muted.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 5)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial.opacity(0.7))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppPalette.panelLight.opacity(0.8))
                .frame(height: 1)
        }
    }
}

private struct OfflineGrowthCard: View {
    let summary: OfflineSummary
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.68)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    CapsuleLabel(text: "пока тебя не было", color: AppPalette.mint)
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(AppPalette.mint)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Система продолжала расти")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Дерево развивалось \(durationText) и нашло новые пути в земле.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.muted)
                        .lineSpacing(3)
                }

                HStack(spacing: 10) {
                    OfflineMetric(value: "+\(summary.sunlight.compactString())", label: "свет", color: AppPalette.sand)
                    OfflineMetric(value: "+\(summary.rootLength.compactString()) м", label: "длина", color: AppPalette.root)
                    OfflineMetric(value: "+\(summary.rootSpread.compactString()) м", label: "размах", color: AppPalette.mint)
                }

                Button(action: dismiss) {
                    Text("Продолжить рост")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppPalette.mint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(AppPalette.panelLight, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .padding(24)
        }
    }

    private var durationText: String {
        if summary.duration >= 3600 {
            return "\(Int(summary.duration / 3600)) ч"
        }
        return "\(max(1, Int(summary.duration / 60))) мин"
    }
}

private struct OfflineMetric: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(AppPalette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(AppPalette.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}