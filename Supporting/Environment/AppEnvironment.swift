import SwiftUI

private struct ScoreScaleKey: EnvironmentKey {
    static let defaultValue: Int = 5
}

private struct AnimationDurationKey: EnvironmentKey {
    static let defaultValue: Double = 0.3
}

extension EnvironmentValues {
    var scoreScale: Int {
        get { self[ScoreScaleKey.self] }
        set { self[ScoreScaleKey.self] = newValue }
    }
    
    var animationDuration: Double {
        get { self[AnimationDurationKey.self] }
        set { self[AnimationDurationKey.self] = newValue }
    }
}

