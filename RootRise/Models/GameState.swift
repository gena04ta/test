import Combine
import Foundation

enum Upgrade: String, CaseIterable, Codable, Identifiable {
    case photosynthesis
    case mycorrhiza
    case branching

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photosynthesis: return "Солнечный обмен"
        case .mycorrhiza: return "Мицелий"
        case .branching: return "Боковые корни"
        }
    }

    var subtitle: String {
        switch self {
        case .photosynthesis: return "Больше энергии каждую секунду"
        case .mycorrhiza: return "Корни тянутся быстрее"
        case .branching: return "Корневая сеть становится шире"
        }
    }

    var symbol: String {
        switch self {
        case .photosynthesis: return "sun.max.fill"
        case .mycorrhiza: return "circle.hexagongrid.fill"
        case .branching: return "point.3.connected.trianglepath.dotted"
        }
    }
}

struct OfflineSummary {
    let duration: TimeInterval
    let sunlight: Double
    let rootLength: Double
    let rootSpread: Double
}

@MainActor
final class GameState: ObservableObject {
    @Published private(set) var sunlight: Double = 28
    @Published private(set) var rootLength: Double = 5.8
    @Published private(set) var rootSpread: Double = 3.2
    @Published private(set) var level: Int = 1
    @Published private(set) var photosynthesisLevel: Int = 0
    @Published private(set) var mycorrhizaLevel: Int = 0
    @Published private(set) var branchingLevel: Int = 0
    @Published private(set) var offlineSummary: OfflineSummary?

    private var lastSaved = Date()
    private var ticksSinceSave = 0
    private let saveKey = "rootrise.save.v1"

    init() {
        load()
    }

    var sunlightPerSecond: Double {
        0.85 + (Double(photosynthesisLevel) * 0.72) + (Double(level - 1) * 0.08)
    }

    var rootLengthPerSecond: Double {
        0.018 * (1 + Double(mycorrhizaLevel) * 0.22) * (1 + Double(level - 1) * 0.035)
    }

    var rootSpreadPerSecond: Double {
        0.012 * (1 + Double(branchingLevel) * 0.26) * (1 + Double(level - 1) * 0.02)
    }

    var levelProgress: Double {
        let lowerBound = Double(max(0, level - 1) * 12)
        let upperBound = Double(level * 12)
        return min(1, max(0, (rootLength - lowerBound) / (upperBound - lowerBound)))
    }

    func tick() {
        advance(by: 1)
        ticksSinceSave += 1

        if ticksSinceSave >= 5 {
            save()
            ticksSinceSave = 0
        }
    }

    func buy(_ upgrade: Upgrade) {
        let price = cost(for: upgrade)
        guard sunlight >= price else { return }

        sunlight -= price

        switch upgrade {
        case .photosynthesis: photosynthesisLevel += 1
        case .mycorrhiza: mycorrhizaLevel += 1
        case .branching: branchingLevel += 1
        }

        save()
    }

    func cost(for upgrade: Upgrade) -> Int {
        let base: Double

        switch upgrade {
        case .photosynthesis: base = 18
        case .mycorrhiza: base = 26
        case .branching: base = 32
        }

        let currentLevel = Double(upgradeLevel(for: upgrade))
        return max(1, Int((base * pow(1.48, currentLevel)).rounded()))
    }

    func upgradeLevel(for upgrade: Upgrade) -> Int {
        switch upgrade {
        case .photosynthesis: return photosynthesisLevel
        case .mycorrhiza: return mycorrhizaLevel
        case .branching: return branchingLevel
        }
    }

    func dismissOfflineSummary() {
        offlineSummary = nil
    }

    func save() {
        let data = SaveData(
            sunlight: sunlight,
            rootLength: rootLength,
            rootSpread: rootSpread,
            level: level,
            photosynthesisLevel: photosynthesisLevel,
            mycorrhizaLevel: mycorrhizaLevel,
            branchingLevel: branchingLevel,
            lastSaved: Date()
        )

        guard let encoded = try? JSONEncoder().encode(data) else { return }
        UserDefaults.standard.set(encoded, forKey: saveKey)
        lastSaved = data.lastSaved
    }

    private func advance(by seconds: TimeInterval) {
        guard seconds > 0 else { return }

        sunlight += sunlightPerSecond * seconds
        rootLength += rootLengthPerSecond * seconds
        rootSpread += rootSpreadPerSecond * seconds

        let calculatedLevel = max(1, Int(rootLength / 12) + 1)
        if calculatedLevel != level {
            level = calculatedLevel
        }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: saveKey),
            let saveData = try? JSONDecoder().decode(SaveData.self, from: data)
        else {
            lastSaved = Date()
            return
        }

        sunlight = saveData.sunlight
        rootLength = saveData.rootLength
        rootSpread = saveData.rootSpread
        level = saveData.level
        photosynthesisLevel = saveData.photosynthesisLevel
        mycorrhizaLevel = saveData.mycorrhizaLevel
        branchingLevel = saveData.branchingLevel

        let elapsed = min(max(0, Date().timeIntervalSince(saveData.lastSaved)), 60 * 60 * 12)
        if elapsed > 20 {
            let earnedSunlight = sunlightPerSecond * elapsed
            let earnedLength = rootLengthPerSecond * elapsed
            let earnedSpread = rootSpreadPerSecond * elapsed

            advance(by: elapsed)
            offlineSummary = OfflineSummary(
                duration: elapsed,
                sunlight: earnedSunlight,
                rootLength: earnedLength,
                rootSpread: earnedSpread
            )
        }

        lastSaved = Date()
        save()
    }
}

private struct SaveData: Codable {
    let sunlight: Double
    let rootLength: Double
    let rootSpread: Double
    let level: Int
    let photosynthesisLevel: Int
    let mycorrhizaLevel: Int
    let branchingLevel: Int
    let lastSaved: Date
}