import Foundation

nonisolated struct QuranWordTimingSegment: Hashable, Sendable {
    let startWordIndex: Int
    let endWordIndex: Int
    let startMilliseconds: Int
    let endMilliseconds: Int

    init?(rawValues: [Int]) {
        switch rawValues.count {
        case 3:
            let wordIndex = rawValues[0]
            self.init(
                startWordIndex: wordIndex,
                endWordIndex: wordIndex,
                startMilliseconds: rawValues[1],
                endMilliseconds: rawValues[2]
            )
        case 4:
            self.init(
                startWordIndex: rawValues[0],
                endWordIndex: max(rawValues[0], rawValues[1] - 1),
                startMilliseconds: rawValues[2],
                endMilliseconds: rawValues[3]
            )
        default:
            return nil
        }
    }

    init(startWordIndex: Int, endWordIndex: Int, startMilliseconds: Int, endMilliseconds: Int) {
        self.startWordIndex = startWordIndex
        self.endWordIndex = max(startWordIndex, endWordIndex)
        self.startMilliseconds = startMilliseconds
        self.endMilliseconds = max(startMilliseconds, endMilliseconds)
    }

    func contains(milliseconds: Int) -> Bool {
        milliseconds >= startMilliseconds && milliseconds < endMilliseconds
    }
}

nonisolated struct QuranAyahTimingPayload: Hashable, Sendable {
    let audioURL: URL
    let segments: [QuranWordTimingSegment]

    var estimatedDurationMilliseconds: Int {
        segments.map(\.endMilliseconds).max() ?? 0
    }

    func resolvedSegment(at milliseconds: Int) -> QuranWordTimingSegment? {
        guard !segments.isEmpty else { return nil }

        if let exact = segments.first(where: { $0.contains(milliseconds: milliseconds) }) {
            return exact
        }

        var previous: QuranWordTimingSegment?

        for segment in segments {
            if milliseconds < segment.startMilliseconds {
                return previous
            }

            previous = segment
        }

        return previous
    }
}

nonisolated struct QuranActiveWordRange: Equatable, Sendable {
    let surahID: Int
    let ayahNumber: Int
    let startWordIndex: Int
    let endWordIndex: Int

    func contains(wordIndex: Int) -> Bool {
        (startWordIndex...endWordIndex).contains(wordIndex)
    }
}
