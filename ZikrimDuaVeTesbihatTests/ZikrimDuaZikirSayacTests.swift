//
//  ZikrimDuaZikirSayacTests.swift
//  ZikrimDuaZikirSayacTests
//
//  Created by Rork on February 25, 2026.
//

import Testing
import MapKit
@testable import ZikrimDuaVeTesbihat

struct ZikrimDuaVeTesbihatTests {

    @Test func subscriptionDisplayDateMapsMidnightBoundaryToPreviousDay() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let renewalMoment = calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 0, minute: 0, second: 0))!

        let displayDate = SubscriptionStore.displayDate(
            forRenewalMoment: renewalMoment,
            calendar: calendar
        )

        let components = calendar.dateComponents([.year, .month, .day], from: displayDate!)
        #expect(components.year == 2026)
        #expect(components.month == 3)
        #expect(components.day == 17)
    }

    @Test func subscriptionDisplayDateKeepsSameDayForNonMidnightRenewal() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let renewalMoment = calendar.date(from: DateComponents(year: 2026, month: 3, day: 18, hour: 14, minute: 30, second: 0))!

        let displayDate = SubscriptionStore.displayDate(
            forRenewalMoment: renewalMoment,
            calendar: calendar
        )

        let components = calendar.dateComponents([.year, .month, .day], from: displayDate!)
        #expect(components.year == 2026)
        #expect(components.month == 3)
        #expect(components.day == 18)
    }

    @Test func displayNamePrefersLocalizedName() async throws {
        let item = POIItem(
            id: "poi-1",
            source: .osm,
            category: .mosques,
            name: "Blue Mosque",
            localizedName: "Sultanahmet Camii",
            coordinate: .init(latitude: 41.0054, longitude: 28.9768),
            confidence: 0.9
        )

        #expect(item.displayName == "Sultanahmet Camii")
    }

    @Test func deduplicationMergesNearbySimilarItems() async throws {
        let dedupe = POIDeduplicationService()

        let osm = POIItem(
            id: "osm-1",
            source: .osm,
            category: .mosques,
            name: "Fatih Camii",
            coordinate: .init(latitude: 41.0194, longitude: 28.9490),
            confidence: 0.88
        )
        let mapKit = POIItem(
            id: "mapkit-1",
            source: .mapKit,
            category: .mosques,
            name: "Fatih Mosque",
            coordinate: .init(latitude: 41.0196, longitude: 28.9491),
            confidence: 0.78
        )

        let merged = dedupe.merge([osm, mapKit], userLocation: nil)
        #expect(merged.count == 1)
        #expect(merged.first?.source == .merged)
    }

    @Test func rankingPushesLowConfidenceNameHintDown() async throws {
        let ranking = POIRankingService()
        let region = MKCoordinateRegion(
            center: .init(latitude: 41.0082, longitude: 28.9784),
            span: .init(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )

        let high = POIItem(
            id: "high",
            source: .osm,
            category: .mosques,
            name: "Şehzade Camii",
            coordinate: .init(latitude: 41.0169, longitude: 28.9607),
            confidence: 0.88,
            metadata: POIMetadata(osmTags: ["zikrim:query_id": "mosques_primary"])
        )
        let low = POIItem(
            id: "low",
            source: .osm,
            category: .mosques,
            name: "Cami Center",
            coordinate: .init(latitude: 41.0170, longitude: 28.9608),
            confidence: 0.52,
            metadata: POIMetadata(osmTags: ["zikrim:query_id": "mosques_secondary_name_hint"])
        )

        let ranked = ranking.rank([low, high], category: .mosques, in: region, userLocation: nil)
        #expect(ranked.first?.id == "high")
    }

    @Test func blueMosqueStyleMismatchHeuristic() async throws {
        let mismatched = MapKitPOIQualityRules.isLikelyMismatchedMosque(
            nameText: "blue mosque museum",
            contextText: "ticket tour info",
            distanceFromRegionCenter: 3_000,
            regionRadiusMeters: 1_000
        )

        #expect(mismatched == true)
    }

}
