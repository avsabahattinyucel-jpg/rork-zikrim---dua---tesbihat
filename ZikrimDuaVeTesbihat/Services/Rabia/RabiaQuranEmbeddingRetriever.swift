import Foundation

nonisolated struct RabiaQuranEmbeddingEntry: Codable, Sendable, Hashable {
    let ref: String
    let surah: Int
    let ayah: Int
    let topics: [String]
    let searchText: [String: String]
    let embedding: [Int8]

    enum CodingKeys: String, CodingKey {
        case ref
        case surah
        case ayah
        case topics
        case searchText = "search_text"
        case embedding
    }
}

nonisolated struct RabiaQuranSemanticEntry: Codable, Sendable, Hashable {
    let ref: String
    let surah: Int
    let ayah: Int
    let topics: [String]
    let priorityScore: Float
    let keywords: [String: [String]]
    let searchText: [String: String]

    enum CodingKeys: String, CodingKey {
        case ref
        case surah
        case ayah
        case topics
        case priorityScore = "priority_score"
        case keywords
        case searchText = "search_text"
    }
}

nonisolated struct RabiaQuranRefScore: Sendable {
    let ref: String
    let surah: Int
    let ayah: Int
    let score: Float
}

private enum SemanticTextSource {
    case app
    case english
    case arabic
    case none
}

protocol RabiaQuranEmbeddingRetrieving: Sendable {
    func retrieveRefs(for query: String, appLanguage: String, topK: Int, threshold: Float) async -> [RabiaQuranRefScore]
}

final class RabiaQuranEmbeddingRetriever: RabiaQuranEmbeddingRetrieving {
    static let shared = RabiaQuranEmbeddingRetriever()

    private let embeddingDimensions = 64
    private let embeddingScale: Float = 127.0

    private lazy var semanticIndex: [RabiaQuranSemanticEntry] = loadSemanticIndex()
    private lazy var embeddingIndex: [RabiaQuranEmbeddingEntry] = loadEmbeddingIndex()
    private lazy var embeddingNorms: [Float] = embeddingIndex.map { l2Norm(of: $0.embedding) }
    private var semanticEmbeddingsByLanguage: [String: [[Float]]] = [:]
    private var semanticNormsByLanguage: [String: [Float]] = [:]
    private var semanticSourcesByLanguage: [String: [SemanticTextSource]] = [:]

    private init() {}

    func preloadSemanticIndex() {
        _ = semanticIndex
    }

    func retrieveRefs(for query: String, appLanguage: String, topK: Int, threshold: Float) async -> [RabiaQuranRefScore] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }
        let sensitiveQuery = isSensitiveQuery(normalizedQuery, appLanguage: appLanguage)
        let explicitQuranQuery = isExplicitQuranQuery(normalizedQuery, appLanguage: appLanguage)

#if DEBUG
        print("[RabiaQuranEmbedding] app_language=\(appLanguage)")
        print("[RabiaQuranEmbedding] query_embedding_start")
#endif

        if !semanticIndex.isEmpty {
            let refs = retrieveFromSemanticIndex(
                query: normalizedQuery,
                appLanguage: appLanguage,
                topK: topK,
                threshold: threshold,
                sensitiveQuery: sensitiveQuery,
                explicitQuranQuery: explicitQuranQuery
            )
#if DEBUG
            print("retrieval_disabled_for_sensitive_query=\(sensitiveQuery && refs.isEmpty)")
#endif
            return refs
        }

        guard !embeddingIndex.isEmpty else {
#if DEBUG
            print("[RabiaQuranEmbedding] query_embedding_failure=empty_index")
#endif
            return []
        }

        let queryVector = embed(text: normalizedQuery)
        let queryNorm = l2Norm(of: queryVector)
        guard queryNorm > 0 else {
#if DEBUG
            print("[RabiaQuranEmbedding] query_embedding_failure=empty_vector")
#endif
            return []
        }

#if DEBUG
        print("[RabiaQuranEmbedding] query_embedding_success")
#endif

        var scored: [RabiaQuranRefScore] = []
        scored.reserveCapacity(embeddingIndex.count)

        for (idx, entry) in embeddingIndex.enumerated() {
            let emb = entry.embedding
            if emb.count != embeddingDimensions { continue }
            let denom = queryNorm * embeddingNorms[idx]
            if denom == 0 { continue }

            var dot: Float = 0
            for i in 0..<embeddingDimensions {
                let v = Float(emb[i]) / embeddingScale
                dot += queryVector[i] * v
            }
            let score = dot / denom
            scored.append(RabiaQuranRefScore(ref: entry.ref, surah: entry.surah, ayah: entry.ayah, score: score))
        }

        let top = scored.sorted { $0.score > $1.score }.prefix(topK)
        let topList = Array(top)

        let adjustedThreshold = explicitQuranQuery ? max(threshold - 0.03, 0.2) : threshold
        let effectiveThreshold = sensitiveQuery && !explicitQuranQuery ? max(adjustedThreshold, 0.45) : adjustedThreshold
        let minMargin: Float = sensitiveQuery && !explicitQuranQuery ? 0.05 : (explicitQuranQuery ? 0.01 : 0.02)
        let bestScore = topList.first?.score ?? 0
        let secondScore = topList.dropFirst().first?.score ?? 0
        let marginPass = topList.count < 2 ? true : (bestScore - secondScore) >= minMargin
        let scoreThresholdPass = bestScore >= effectiveThreshold
        let marginThresholdPass = explicitQuranQuery ? true : marginPass
        let sensitiveGateBlocked = sensitiveQuery && !explicitQuranQuery && !scoreThresholdPass
        let thresholdPass = scoreThresholdPass && marginThresholdPass && !sensitiveGateBlocked

#if DEBUG
        if topList.isEmpty {
            print("[RabiaQuranEmbedding] top_refs_empty")
        } else {
            let preview = topList.map { "\($0.ref)=\(String(format: "%.3f", $0.score))" }.joined(separator: ", ")
            print("[RabiaQuranEmbedding] top_refs=\(preview)")
            print("retrieval_top_scores:", preview)
        }
        print("score_threshold_pass=\(scoreThresholdPass)")
        print("margin_threshold_pass=\(marginThresholdPass)")
        print("sensitive_gate_blocked=\(sensitiveGateBlocked)")
        print("final_retrieval_pass=\(thresholdPass)")
#endif

        guard thresholdPass else {
#if DEBUG
            print("[RabiaQuranEmbedding] threshold_fail best=\(String(format: "%.3f", bestScore)) threshold=\(String(format: "%.3f", effectiveThreshold))")
            print("retrieval_disabled_for_sensitive_query=\(sensitiveQuery)")
#endif
            return []
        }

#if DEBUG
        print("[RabiaQuranEmbedding] threshold_pass threshold=\(String(format: "%.3f", effectiveThreshold))")
#endif

        let finalList = topList.filter { $0.score >= effectiveThreshold }
#if DEBUG
        let refs = finalList.map { $0.ref }.joined(separator: ",")
        print("RETRIEVED_REFS=[\(refs)]")
        print("retrieval_disabled_for_sensitive_query=false")
#endif
        return finalList
    }

    func queryMode(for query: String, appLanguage: String) -> String {
        _ = appLanguage
        return RabiaQueryMode.detectQueryMode(userText: query).rawValue
    }

    private func retrieveFromSemanticIndex(query: String, appLanguage: String, topK: Int, threshold: Float, sensitiveQuery: Bool, explicitQuranQuery: Bool) -> [RabiaQuranRefScore] {
        guard !semanticIndex.isEmpty else { return [] }
#if DEBUG
        print("SEMANTIC_QUERY:", query)
#endif
        let (embeddings, norms, sources) = semanticEmbeddings(for: appLanguage)
        return retrieveFromSemanticEntries(
            entries: semanticIndex,
            query: query,
            appLanguage: appLanguage,
            topK: topK,
            threshold: threshold,
            sensitiveQuery: sensitiveQuery,
            explicitQuranQuery: explicitQuranQuery,
            embeddings: embeddings,
            norms: norms,
            sources: sources
        )
    }

    private func retrieveFromSemanticEntries(
        entries: [RabiaQuranSemanticEntry],
        query: String,
        appLanguage: String,
        topK: Int,
        threshold: Float,
        sensitiveQuery: Bool,
        explicitQuranQuery: Bool,
        embeddings: [[Float]]?,
        norms: [Float]?,
        sources: [SemanticTextSource]?
    ) -> [RabiaQuranRefScore] {
        guard !entries.isEmpty else { return [] }
        let queryVector = embed(text: query)
        let queryNorm = l2Norm(of: queryVector)
        guard queryNorm > 0 else {
#if DEBUG
            print("[RabiaQuranEmbedding] query_embedding_failure=empty_vector")
#endif
            return []
        }

#if DEBUG
        print("[RabiaQuranEmbedding] query_embedding_success")
#endif

        let queryTokens = Set(tokenize(query))
        var scored: [(score: Float, ref: RabiaQuranRefScore, relevanceMatch: Bool)] = []
        scored.reserveCapacity(entries.count)

        for (idx, entry) in entries.enumerated() {
            let emb: [Float]
            let norm: Float
            let source: SemanticTextSource

            if let embeddings, let norms, let sources, idx < embeddings.count, idx < norms.count, idx < sources.count {
                emb = embeddings[idx]
                norm = norms[idx]
                source = sources[idx]
            } else {
                let (text, inferredSource) = semanticTextAndSource(for: entry, appLanguage: appLanguage)
                let vector = embed(text: text)
                emb = vector
                norm = l2Norm(of: vector)
                source = inferredSource
            }

            if emb.count != embeddingDimensions { continue }
            let denom = queryNorm * norm
            if denom == 0 { continue }

            var dot: Float = 0
            for i in 0..<embeddingDimensions {
                dot += queryVector[i] * emb[i]
            }
            var score = dot / denom
            let adjustment = adjustedSemanticScore(
                score,
                entry: entry,
                source: source,
                queryTokens: queryTokens,
                appLanguage: appLanguage,
                sensitiveQuery: sensitiveQuery
            )
            score = adjustment.score
            if score <= 0 { continue }
            let refScore = RabiaQuranRefScore(ref: entry.ref, surah: entry.surah, ayah: entry.ayah, score: score)
            scored.append((score: score, ref: refScore, relevanceMatch: adjustment.relevanceMatch))
        }

        let top = scored.sorted { $0.score > $1.score }.prefix(topK)
        let topList = Array(top)
        let topRefs = topList.map { $0.ref }
        let topRelevance = topList.first?.relevanceMatch ?? false

        let adjustedThreshold = explicitQuranQuery ? max(threshold - 0.03, 0.2) : threshold
        let effectiveThreshold = sensitiveQuery && !explicitQuranQuery ? max(adjustedThreshold, 0.45) : adjustedThreshold
        let minMargin: Float = sensitiveQuery && !explicitQuranQuery ? 0.05 : (explicitQuranQuery ? 0.01 : 0.02)
        let bestScore = topList.first?.score ?? 0
        let secondScore = topList.dropFirst().first?.score ?? 0
        let marginPass = topList.count < 2 ? true : (bestScore - secondScore) >= minMargin
        let scoreThresholdPass = bestScore >= effectiveThreshold
        let marginThresholdPass = explicitQuranQuery ? true : marginPass
        let sensitiveGateBlocked = sensitiveQuery && !explicitQuranQuery && !topRelevance
        let thresholdPass = scoreThresholdPass && marginThresholdPass && !sensitiveGateBlocked

#if DEBUG
        if topList.isEmpty {
            print("[RabiaQuranEmbedding] top_refs_empty")
        } else {
            let preview = topRefs.map { "\($0.ref)=\(String(format: "%.3f", $0.score))" }.joined(separator: ", ")
            print("[RabiaQuranEmbedding] top_refs=\(preview)")
            print("retrieval_top_scores:", preview)
        }
        print("score_threshold_pass=\(scoreThresholdPass)")
        print("margin_threshold_pass=\(marginThresholdPass)")
        print("sensitive_gate_blocked=\(sensitiveGateBlocked)")
        print("final_retrieval_pass=\(thresholdPass)")
#endif

        guard thresholdPass else {
#if DEBUG
            print("[RabiaQuranEmbedding] threshold_fail best=\(String(format: "%.3f", bestScore)) threshold=\(String(format: "%.3f", effectiveThreshold))")
#endif
            return []
        }

#if DEBUG
        print("[RabiaQuranEmbedding] threshold_pass threshold=\(String(format: "%.3f", effectiveThreshold))")
#endif

        let finalList = topRefs.filter { $0.score >= effectiveThreshold }
#if DEBUG
        let refs = finalList.map { $0.ref }.joined(separator: ",")
        print("SEMANTIC_REFS:", refs)
        print("RETRIEVED_REFS=[\(refs)]")
#endif
        return finalList
    }

#if DEBUG
    func retrieveRefsForTesting(
        query: String,
        appLanguage: String,
        entries: [RabiaQuranSemanticEntry],
        topK: Int,
        threshold: Float,
        sensitiveQuery: Bool? = nil
    ) -> [RabiaQuranRefScore] {
        let isSensitive = sensitiveQuery ?? isSensitiveQuery(query, appLanguage: appLanguage)
        let explicitQuery = isExplicitQuranQuery(query, appLanguage: appLanguage)
        return retrieveFromSemanticEntries(
            entries: entries,
            query: query,
            appLanguage: appLanguage,
            topK: topK,
            threshold: threshold,
            sensitiveQuery: isSensitive,
            explicitQuranQuery: explicitQuery,
            embeddings: nil,
            norms: nil,
            sources: nil
        )
    }
#endif

    private func semanticEmbeddings(for appLanguage: String) -> ([[Float]], [Float], [SemanticTextSource]) {
        if let cached = semanticEmbeddingsByLanguage[appLanguage],
           let norms = semanticNormsByLanguage[appLanguage],
           let sources = semanticSourcesByLanguage[appLanguage] {
            return (cached, norms, sources)
        }

        var embeddings: [[Float]] = []
        embeddings.reserveCapacity(semanticIndex.count)
        var norms: [Float] = []
        norms.reserveCapacity(semanticIndex.count)
        var sources: [SemanticTextSource] = []
        sources.reserveCapacity(semanticIndex.count)

        for entry in semanticIndex {
            let (text, source) = semanticTextAndSource(for: entry, appLanguage: appLanguage)
            let vector = embed(text: text)
            embeddings.append(vector)
            norms.append(l2Norm(of: vector))
            sources.append(source)
        }

        semanticEmbeddingsByLanguage[appLanguage] = embeddings
        semanticNormsByLanguage[appLanguage] = norms
        semanticSourcesByLanguage[appLanguage] = sources
        return (embeddings, norms, sources)
    }

    private func semanticTextAndSource(for entry: RabiaQuranSemanticEntry, appLanguage: String) -> (String, SemanticTextSource) {
        var parts: [String] = []
        var source: SemanticTextSource = .none

        if let text = entry.searchText[appLanguage], !text.isEmpty {
            parts.append(text)
            source = .app
        }
        if let keywords = entry.keywords[appLanguage], !keywords.isEmpty {
            parts.append(keywords.joined(separator: " "))
            if source == .none { source = .app }
        }

        if parts.isEmpty {
            if let text = entry.searchText["en"], !text.isEmpty {
                parts.append(text)
                source = .english
            }
            if let keywords = entry.keywords["en"], !keywords.isEmpty {
                parts.append(keywords.joined(separator: " "))
                if source == .none { source = .english }
            }
        }

        if parts.isEmpty {
            if let text = entry.searchText["ar"], !text.isEmpty {
                parts.append(text)
                source = .arabic
            }
            if let keywords = entry.keywords["ar"], !keywords.isEmpty {
                parts.append(keywords.joined(separator: " "))
                if source == .none { source = .arabic }
            }
        }

        if !entry.topics.isEmpty {
            parts.append(entry.topics.joined(separator: " "))
            if source == .none { source = .english }
        }

        let text = parts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return ("", .none) }
        return (text, source)
    }

    private func adjustedSemanticScore(
        _ base: Float,
        entry: RabiaQuranSemanticEntry,
        source: SemanticTextSource,
        queryTokens: Set<String>,
        appLanguage: String,
        sensitiveQuery: Bool
    ) -> (score: Float, relevanceMatch: Bool) {
        var score = max(0, base)

        switch source {
        case .english:
            score *= 0.8
        case .arabic:
            score *= 0.6
        case .none:
            return (score: 0, relevanceMatch: false)
        case .app:
            break
        }

        let keywordsApp = entry.keywords[appLanguage] ?? []
        let keywordsEn = entry.keywords["en"] ?? []
        let hasKeywords = !(keywordsApp.isEmpty && keywordsEn.isEmpty)
        let keywordMatch = keywordMatches(keywordsApp, queryTokens: queryTokens) || keywordMatches(keywordsEn, queryTokens: queryTokens)
        let topicMatch = topicMatches(entry.topics, queryTokens: queryTokens)
        let relevanceMatch = keywordMatch || topicMatch

        if hasKeywords {
            score *= relevanceMatch ? 1.18 : 0.85
        }

        if topicMatch {
            score *= 1.08
        }

        if entry.topics.isEmpty && !hasKeywords {
            score *= 0.75
        }

        if entry.priorityScore > 0 {
            score += min(entry.priorityScore, 1.0) * 0.05
        }

        if sensitiveQuery && !relevanceMatch {
            score *= 0.7
        }

        return (score: score, relevanceMatch: relevanceMatch)
    }

    private func keywordMatches(_ keywords: [String], queryTokens: Set<String>) -> Bool {
        guard !keywords.isEmpty else { return false }
        for keyword in keywords {
            let normalized = keyword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { continue }
            if queryTokens.contains(normalized) { return true }
            for token in queryTokens {
                if token.contains(normalized) || normalized.contains(token) {
                    return true
                }
            }
        }
        return false
    }

    private func topicMatches(_ topics: [String], queryTokens: Set<String>) -> Bool {
        guard !topics.isEmpty else { return false }
        for topic in topics {
            let normalized = topic.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty else { continue }
            if queryTokens.contains(normalized) { return true }
            for token in queryTokens {
                if token.contains(normalized) || normalized.contains(token) {
                    return true
                }
            }
        }
        return false
    }

    private func isSensitiveQuery(_ query: String, appLanguage: String) -> Bool {
        let normalized = query
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: appLanguage))
            .lowercased()

        let common = ["sexual", "sex", "porn", "masturbation", "masturbate", "homosexual", "gay", "lesbian", "lgbt", "trans", "gender", "identity", "orientation"]
        let tr = ["eşcinsellik", "homoseksüel", "gay", "lezbiyen", "lgbt", "trans", "cinsellik", "seks", "masturbasyon", "porno", "zina", "kimlik", "yönelim"]
        let de = ["homosexuell", "schwul", "lesbisch", "lgbt", "trans", "sexualität", "sex", "porno", "masturbation", "geschlecht", "identität"]
        let fr = ["homosexuel", "gay", "lesbienne", "lgbt", "trans", "sexualité", "sexe", "porno", "masturbation", "identité"]
        let es = ["homosexual", "gay", "lesbiana", "lgbt", "trans", "sexualidad", "sexo", "porno", "masturbación", "identidad"]
        let id = ["homoseksual", "gay", "lesbian", "lgbt", "trans", "seksualitas", "seks", "porno", "masturbasi", "identitas"]
        let ur = ["ہم جنس", "ہمجنس", "گی", "لیسبین", "lgbt", "ٹرانس", "جنس", "سیکس", "فحش", "مشت زنی", "شناخت"]
        let ms = ["homoseksual", "gay", "lesbian", "lgbt", "trans", "seksualiti", "seks", "porno", "melancap", "identiti"]
        let ru = ["гомосек", "гомосексуал", "гей", "лесбиян", "лгбт", "транс", "сексуал", "секс", "порно", "мастурбац", "идентич"]
        let fa = ["همجنس", "همجنسگر", "همجنس‌گرا", "گی", "لزبین", "ال‌جی‌بی‌تی", "ترنس", "جنسیت", "سکس", "پورن", "خودارضایی", "هویت"]
        let ar = ["الشذوذ", "مثلي", "مثلية", "شذوذ", "جنس", "جنسية", "سكس", "إباحية", "استمناء", "هوية", "ميول"]

        let langList: [String]
        switch appLanguage {
        case "tr": langList = tr + common
        case "de": langList = de + common
        case "fr": langList = fr + common
        case "es": langList = es + common
        case "id": langList = id + common
        case "ur": langList = ur + common
        case "ms": langList = ms + common
        case "ru": langList = ru + common
        case "fa": langList = fa + common
        case "ar": langList = ar
        default: langList = common
        }

        return langList.contains { normalized.contains($0) }
    }

    private func isEmotionalSupportQuery(_ query: String, appLanguage: String) -> Bool {
        let normalized = query
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: appLanguage))
            .lowercased()
        let normalizedSearch = latinFriendlyMatchText(normalized)

        let common = [
            "i feel alone", "i feel lonely", "i feel overwhelmed", "my chest feels tight",
            "i am not okay", "i'm not okay", "i feel suffocated", "i feel trapped",
            "i feel awful", "i feel broken", "i feel empty", "panic", "anxious", "overwhelmed"
        ]
        let tr = [
            "kalbim sıkışıyor", "kalbim sıkisiyor", "içim daralıyor", "icim daraliyor",
            "çok yalnızım", "cok yalnizim", "çok kötüyüm", "cok kotuyum", "çok bunaldım",
            "cok bunaldim", "yalnız hissediyorum", "yalniz hissediyorum", "boğuluyorum",
            "boguluyorum", "nefes alamıyorum", "nefes alamiyorum", "çok sıkıştım",
            "cok sikistim", "dayanamıyorum", "dayanamiyorum", "çok yoruldum", "cok yoruldum"
        ]
        let de = [
            "ich bin sehr allein", "ich fühle mich allein", "mir ist alles zu viel",
            "mein herz ist eng", "ich bin am ende", "ich fühle mich schlecht"
        ]
        let fr = [
            "je me sens seul", "je me sens très seul", "j'étouffe", "je me sens mal",
            "je suis dépassé", "mon coeur est serré"
        ]
        let es = [
            "me siento solo", "me siento muy solo", "me ahogo", "me siento fatal",
            "estoy abrumado", "siento el pecho apretado"
        ]
        let id = [
            "aku merasa sendirian", "aku sangat kesepian", "dadaku sesak",
            "aku sangat lelah", "aku tertekan", "aku tidak baik-baik saja"
        ]
        let ur = [
            "میں بہت اکیلا ہوں", "دل گھبرا رہا ہے", "بہت گھٹن ہو رہی ہے",
            "میں بہت پریشان ہوں", "میں ٹھیک نہیں ہوں"
        ]
        let ms = [
            "saya rasa sangat keseorangan", "dada saya sesak", "saya sangat tertekan",
            "saya tidak okay", "saya rasa terhimpit"
        ]
        let ru = [
            "мне очень одиноко", "мне тяжело", "на душе тяжело",
            "я задыхаюсь", "я не в порядке", "мне очень плохо"
        ]
        let fa = [
            "خیلی تنها هستم", "دلم گرفته", "نفسم بند آمده",
            "خیلی حالم بد است", "خیلی تحت فشارم"
        ]
        let ar = [
            "اشعر بالوحدة", "أنا وحيد جدا", "صدري ضيق", "مختنق",
            "لست بخير", "تعبت جدا", "منهك"
        ]

        let langList: [String]
        switch appLanguage {
        case "tr": langList = tr + common
        case "de": langList = de + common
        case "fr": langList = fr + common
        case "es": langList = es + common
        case "id": langList = id + common
        case "ur": langList = ur + common
        case "ms": langList = ms + common
        case "ru": langList = ru + common
        case "fa": langList = fa + common
        case "ar": langList = ar
        default: langList = common
        }

        return langList.contains { normalizedSearch.contains(latinFriendlyMatchText($0)) }
    }

    private func isExplicitQuranQuery(_ query: String, appLanguage: String) -> Bool {
        let normalized = query
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: appLanguage))
            .lowercased()

        let keywords = [
            "ayet", "ayetler", "sure", "suresi", "sûre", "sûresi",
            "kuran", "kur'an", "quran",
            "verse", "verses", "ayah", "ayahs",
            "surah", "surahs"
        ]
        return keywords.contains { keyword in
            normalized.range(of: "(^|[^\\p{L}])\(keyword)([^\\p{L}]|$)", options: .regularExpression) != nil
        }
    }

    private func loadSemanticIndex() -> [RabiaQuranSemanticEntry] {
        guard let url = Bundle.main.url(forResource: "rabia_quran_semantic_index", withExtension: "json") else {
#if DEBUG
            print("[RabiaQuranEmbedding] index_load_failure=missing_semantic_file")
#endif
            return []
        }
        guard let data = try? Data(contentsOf: url) else {
#if DEBUG
            print("[RabiaQuranEmbedding] index_load_failure=semantic_read_error")
#endif
            return []
        }
        guard let entries = try? JSONDecoder().decode([RabiaQuranSemanticEntry].self, from: data) else {
#if DEBUG
            print("[RabiaQuranEmbedding] index_load_failure=semantic_decode_error")
#endif
            return []
        }

#if DEBUG
        print("QURAN_SEMANTIC_INDEX_LOADED:", entries.count)
        print("ACTIVE_QURAN_RETRIEVAL_SOURCE=rabia_quran_semantic_index.json")
        print("LOADED_ENTRY_COUNT=\(entries.count)")
#endif
        return entries
    }

    private func loadEmbeddingIndex() -> [RabiaQuranEmbeddingEntry] {
        guard let url = Bundle.main.url(forResource: "rabia_quran_embedding_index", withExtension: "json") else {
#if DEBUG
            print("[RabiaQuranEmbedding] index_load_failure=missing_file")
#endif
            return []
        }
        guard let data = try? Data(contentsOf: url) else {
#if DEBUG
            print("[RabiaQuranEmbedding] index_load_failure=read_error")
#endif
            return []
        }
        guard let entries = try? JSONDecoder().decode([RabiaQuranEmbeddingEntry].self, from: data) else {
#if DEBUG
            print("[RabiaQuranEmbedding] index_load_failure=decode_error")
#endif
            return []
        }

#if DEBUG
        print("ACTIVE_QURAN_RETRIEVAL_SOURCE=rabia_quran_embedding_index.json")
        print("LOADED_ENTRY_COUNT=\(entries.count)")
#endif
        return entries
    }

    private func embed(text: String) -> [Float] {
        var vector = Array(repeating: Float(0), count: embeddingDimensions)
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return vector }

        for token in tokens {
            let hash = fnv1a(token)
            let idx = Int(hash % UInt32(embeddingDimensions))
            vector[idx] += 1
        }

        let norm = l2Norm(of: vector)
        if norm > 0 {
            for i in 0..<vector.count {
                vector[i] /= norm
            }
        }
        return vector
    }

    private func tokenize(_ text: String) -> [String] {
        let lowered = text.lowercased()
        var tokens: [String] = []
        var current = ""

        for scalar in lowered.unicodeScalars {
            let v = scalar.value
            let isLetterNumber = (0x0030...0x0039).contains(v)
                || (0x0041...0x005A).contains(v)
                || (0x0061...0x007A).contains(v)
                || (0x00C0...0x02AF).contains(v)
                || (0x0300...0x036F).contains(v)
                || (0x0400...0x04FF).contains(v)
                || (0x0500...0x052F).contains(v)
                || (0x0600...0x06FF).contains(v)
                || (0x0750...0x077F).contains(v)
                || (0x08A0...0x08FF).contains(v)
                || (0xFB50...0xFDFF).contains(v)
                || (0xFE70...0xFEFF).contains(v)
                || v == 0x0027
                || v == 0x2019
                || v == 0x002D

            if isLetterNumber {
                current.unicodeScalars.append(scalar)
            } else if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens
    }

    private func latinFriendlyMatchText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "İ", with: "i")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "Ş", with: "s")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "Ğ", with: "g")
            .replacingOccurrences(of: "ç", with: "c")
            .replacingOccurrences(of: "Ç", with: "c")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "Ö", with: "o")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "Ü", with: "u")
    }

    private func fnv1a(_ text: String) -> UInt32 {
        var hash: UInt32 = 2166136261
        for scalar in text.unicodeScalars {
            hash ^= UInt32(scalar.value)
            hash &*= 16777619
        }
        return hash
    }

    private func l2Norm(of vector: [Float]) -> Float {
        var sum: Float = 0
        for v in vector { sum += v * v }
        return sqrt(sum)
    }

    private func l2Norm(of vector: [Int8]) -> Float {
        var sum: Float = 0
        for v in vector {
            let scaled = Float(v) / embeddingScale
            sum += scaled * scaled
        }
        return sqrt(sum)
    }
}
