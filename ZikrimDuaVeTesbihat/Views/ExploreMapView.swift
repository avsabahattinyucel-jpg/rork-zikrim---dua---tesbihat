import SwiftUI
@preconcurrency import MapKit
import UIKit

struct ExploreMapView: View {
    let authService: AuthService

    @EnvironmentObject private var themeManager: ThemeManager
    @State private var viewModel = ExploreMapViewModel()

    private var theme: ActiveTheme { themeManager.current }

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { proxy in
                ExploreMapContainer(
                    items: viewModel.items,
                    region: $viewModel.visibleRegion,
                    selectedItem: Binding(
                        get: { viewModel.selectedItem },
                        set: { viewModel.setSelectedItem($0, userInitiated: true) }
                    ),
                    onRegionChange: { region in
                        viewModel.updateVisibleRegion(region, userInitiated: true)
                    }
                )
                .frame(
                    width: max(proxy.size.width, 1),
                    height: max(proxy.size.height, 320)
                )
            }
            .frame(minHeight: 320)
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 10) {
                GuideHeaderBar(statusText: viewModel.statusText, theme: theme)
                ExploreCategoryChips(
                    selectedCategory: viewModel.selectedCategory,
                    resultCounts: viewModel.categoryResultCounts,
                    theme: theme,
                    onTap: { category in
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            viewModel.selectCategory(category)
                        }
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if let emptyStateTitle = viewModel.emptyStateTitle, viewModel.shouldShowZoomHelper {
                ExploreEmptyStateHelperCard(
                    title: emptyStateTitle,
                    helper: L10n.string(.guideEmptyHelperZoom),
                    theme: theme
                )
                .padding(.horizontal, 24)
                .padding(.top, 150)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.items)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 10) {
                if viewModel.isLoading {
                    loadingPill
                }

                if let item = viewModel.featuredItem {
                    NearbyPOICard(
                        item: item,
                        theme: theme,
                        onDirections: {
                            viewModel.openDirections(to: item)
                        }
                    )
                    .id("poi-card-\(item.id)")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if viewModel.isLoading {
                    NearbyPOILoadingCard(theme: theme)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 6)
            .background(Color.clear)
        }
        .animation(.spring(response: 0.26, dampingFraction: 0.88), value: viewModel.featuredItem?.id)
        .background(theme.backgroundPrimary)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(.guideTitleDiscover)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
            }
        }
        .onAppear {
            if viewModel.authorizationStatus == .authorizedWhenInUse || viewModel.authorizationStatus == .authorizedAlways {
                viewModel.startUpdates()
            } else if viewModel.authorizationStatus == .notDetermined {
                viewModel.requestPermission()
            } else {
                viewModel.updateVisibleRegion(viewModel.visibleRegion, userInitiated: false)
            }
        }
        .onDisappear {
            viewModel.stopUpdates()
        }
    }

    private var loadingPill: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(theme.accent)
                .scaleEffect(0.78)

            Text(.guideSearchLoading)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(theme.elevatedBackground.opacity(theme.isDarkMode ? 0.92 : 0.94))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.08 : 0.4), lineWidth: 1)
        )
        .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.16 : 0.08), radius: 12, y: 6)
        .transition(.scale.combined(with: .opacity))
    }
}

private struct GuideHeaderBar: View {
    let statusText: String
    let theme: ActiveTheme

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.accent)

            Text(statusText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(theme.elevatedBackground.opacity(theme.isDarkMode ? 0.9 : 0.92))
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.10 : 0.46), lineWidth: 1)
        )
        .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.16 : 0.08), radius: 14, y: 8)
    }
}

private struct ExploreCategoryChips: View {
    let selectedCategory: POICategory
    let resultCounts: [POICategory: Int]
    let theme: ActiveTheme
    let onTap: (POICategory) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(POICategory.discoverableCases) { category in
                    ExploreCategoryChip(
                        category: category,
                        resultCount: resultCounts[category] ?? 0,
                        theme: theme,
                        isSelected: selectedCategory == category,
                        action: { onTap(category) }
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

private struct ExploreCategoryChip: View {
    let category: POICategory
    let resultCount: Int
    let theme: ActiveTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(category.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text("\(resultCount)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill((isSelected ? Color.white : theme.border).opacity(isSelected ? 0.24 : 0.30))
                    )
            }
            .foregroundStyle(isSelected ? .white : theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(category.chipColor) : AnyShapeStyle(theme.elevatedBackground.opacity(theme.isDarkMode ? 0.86 : 0.90)))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.white.opacity(0.20) : theme.border.opacity(0.58), lineWidth: 1)
            )
            .shadow(color: isSelected ? category.chipColor.opacity(0.18) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private extension POICategory {
    static var discoverableCases: [POICategory] {
        [.mosques, .shrines, .historicalPlaces]
    }

    var chipColor: Color {
        switch self {
        case .mosques:
            return Color(red: 0.13, green: 0.55, blue: 0.35)
        case .shrines:
            return Color(red: 0.45, green: 0.34, blue: 0.76)
        case .historicalPlaces:
            return Color(red: 0.86, green: 0.52, blue: 0.18)
        case .halalFood:
            return Color(red: 0.80, green: 0.25, blue: 0.22)
        }
    }
}

private struct NearbyPOICard: View {
    let item: POIItem
    let theme: ActiveTheme
    let onDirections: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(item.category.chipColor.opacity(theme.isDarkMode ? 0.16 : 0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: item.category.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(item.category.chipColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(.guideNearbyPlaces)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textSecondary)

                    Text(item.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(item.category.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(item.category.chipColor)
                        if let distanceText = item.distanceText {
                            Text("•")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(theme.textSecondary.opacity(0.8))
                            Text(distanceText)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }

                Spacer(minLength: 0)
            }

            GuideMiniActionButton(
                title: L10n.string(.guideDirections),
                icon: "arrow.triangle.turn.up.right.diamond.fill",
                theme: theme,
                tint: item.category.chipColor,
                isFilled: true,
                action: onDirections
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.elevatedBackground.opacity(theme.isDarkMode ? 0.95 : 0.96))
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(theme.isDarkMode ? 0.04 : 0.18),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.11 : 0.42), lineWidth: 1)
        )
        .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.24 : 0.10), radius: 18, y: 10)
    }
}

private struct NearbyPOILoadingCard: View {
    let theme: ActiveTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(.guideSearchLoading)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textSecondary)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(theme.backgroundSecondary.opacity(theme.isDarkMode ? 0.62 : 0.45))
                .frame(height: 12)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(theme.backgroundSecondary.opacity(theme.isDarkMode ? 0.46 : 0.34))
                .frame(width: 160, height: 10)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.elevatedBackground.opacity(theme.isDarkMode ? 0.94 : 0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.10 : 0.40), lineWidth: 1)
        )
        .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.20 : 0.08), radius: 14, y: 8)
        .redacted(reason: .placeholder)
    }
}

private struct ExploreEmptyStateHelperCard: View {
    let title: String
    let helper: String
    let theme: ActiveTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textPrimary)

            Text(helper)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.elevatedBackground.opacity(theme.isDarkMode ? 0.92 : 0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(theme.isDarkMode ? 0.10 : 0.40), lineWidth: 1)
        )
        .shadow(color: theme.shadowColor.opacity(theme.isDarkMode ? 0.16 : 0.08), radius: 14, y: 7)
    }
}

private struct GuideMiniActionButton: View {
    let title: String
    let icon: String
    let theme: ActiveTheme
    var tint: Color?
    let isFilled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(isFilled ? Color.white : theme.textPrimary)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isFilled ? Color.clear : theme.border.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var background: some View {
        if isFilled {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint ?? theme.accent)
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.backgroundSecondary.opacity(theme.isDarkMode ? 0.72 : 0.7))
        }
    }
}

private struct ExploreMapContainer: UIViewRepresentable {
    let items: [POIItem]
    @Binding var region: MKCoordinateRegion
    @Binding var selectedItem: POIItem?
    let onRegionChange: (MKCoordinateRegion) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.pointOfInterestFilter = .excludingAll
        mapView.isOpaque = true
        mapView.layoutMargins = UIEdgeInsets(top: 112, left: 18, bottom: 210, right: 18)
        if #available(iOS 16.0, *) {
            let configuration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
            mapView.preferredConfiguration = configuration
        }
        mapView.register(POIMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: POIMarkerAnnotationView.reuseIdentifier)
        mapView.register(POIClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: POIClusterAnnotationView.reuseIdentifier)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        guard mapView.bounds.width > 1, mapView.bounds.height > 1 else { return }
        context.coordinator.parent = self
        context.coordinator.updateAnnotations(on: mapView, with: items)
        context.coordinator.updateRegionIfNeeded(on: mapView, region: region)
        context.coordinator.updateSelection(on: mapView, selectedItem: selectedItem)
    }

    @MainActor
    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ExploreMapContainer
        private var suppressedProgrammaticRegionCallbacks = 0
        private var isProgrammaticSelectionChange = false
        private var isSynchronizingAnnotations = false
        private var annotationsByID: [String: POIAnnotation] = [:]

        init(_ parent: ExploreMapContainer) {
            self.parent = parent
        }

        func updateAnnotations(on mapView: MKMapView, with items: [POIItem]) {
            let desiredIDs = Set(items.map(\.id))
            let existingIDs = Set(annotationsByID.keys)

            let idsToRemove = existingIDs.subtracting(desiredIDs)
            let idsToAdd = desiredIDs.subtracting(existingIDs)

            isSynchronizingAnnotations = true

            if !idsToRemove.isEmpty {
                let annotationsToRemove = idsToRemove.compactMap { annotationsByID.removeValue(forKey: $0) }
                mapView.removeAnnotations(annotationsToRemove)
            }

            for item in items {
                guard let annotation = annotationsByID[item.id] else { continue }
                annotation.poi = item
            }

            if !idsToAdd.isEmpty {
                let annotationsToAdd = items
                    .filter { idsToAdd.contains($0.id) }
                    .map(POIAnnotation.init)

                for annotation in annotationsToAdd {
                    annotationsByID[annotation.poi.id] = annotation
                }

                mapView.addAnnotations(annotationsToAdd)
            }

            isSynchronizingAnnotations = false
        }

        func updateRegionIfNeeded(on mapView: MKMapView, region: MKCoordinateRegion) {
            guard !mapView.region.isApproximatelyEqual(to: region) else { return }
            suppressedProgrammaticRegionCallbacks = 3
            mapView.setRegion(region, animated: true)
        }

        func updateSelection(on mapView: MKMapView, selectedItem: POIItem?) {
            isProgrammaticSelectionChange = true
            defer { isProgrammaticSelectionChange = false }

            guard let selectedItem else {
                mapView.selectedAnnotations.forEach { annotation in
                    mapView.deselectAnnotation(annotation, animated: true)
                }
                return
            }

            if let selectedAnnotation = mapView.selectedAnnotations.first as? POIAnnotation,
               selectedAnnotation.poi.id == selectedItem.id {
                return
            }

            if let annotation = mapView.annotations
                .compactMap({ $0 as? POIAnnotation })
                .first(where: { $0.poi.id == selectedItem.id }) {
                mapView.selectAnnotation(annotation, animated: true)
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if suppressedProgrammaticRegionCallbacks > 0 {
                suppressedProgrammaticRegionCallbacks -= 1
                return
            }
            parent.onRegionChange(mapView.region)
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard !isProgrammaticSelectionChange else { return }
            if let cluster = view.annotation as? MKClusterAnnotation {
                let rect = cluster.memberAnnotations.reduce(MKMapRect.null) { partial, annotation in
                    partial.union(MKMapRect(origin: MKMapPoint(annotation.coordinate), size: MKMapSize(width: 0, height: 0)))
                }
                mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 60, bottom: 160, right: 60), animated: true)
                mapView.deselectAnnotation(cluster, animated: false)
                return
            }

            guard let annotation = view.annotation as? POIAnnotation else { return }
            parent.selectedItem = annotation.poi
        }

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard !isProgrammaticSelectionChange else { return }
            guard !isSynchronizingAnnotations else { return }
            guard view.annotation is POIAnnotation else { return }
            parent.selectedItem = nil
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }

            if let clusterAnnotation = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: POIClusterAnnotationView.reuseIdentifier, for: clusterAnnotation)
                if let clusterView = view as? POIClusterAnnotationView {
                    clusterView.configure(with: clusterAnnotation)
                }
                return view
            }

            guard let poiAnnotation = annotation as? POIAnnotation else { return nil }
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: POIMarkerAnnotationView.reuseIdentifier, for: poiAnnotation)
            if let markerView = view as? POIMarkerAnnotationView {
                markerView.configure(with: poiAnnotation)
            }
            return view
        }
    }
}

private final class POIAnnotation: NSObject, MKAnnotation {
    var poi: POIItem {
        didSet {
            guard oldValue.coordinate.latitude != poi.coordinate.latitude ||
                    oldValue.coordinate.longitude != poi.coordinate.longitude else { return }
            coordinate = poi.coordinate
        }
    }

    init(poi: POIItem) {
        self.poi = poi
        self.coordinate = poi.coordinate
    }

    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { poi.displayName }
    var subtitle: String? { poi.address?.isEmpty == false ? poi.address : poi.subtitle }
}

private final class POIMarkerAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "POIMarkerAnnotationView"

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let tintView = UIView()
    private let glyphView = UIImageView()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        centerOffset = CGPoint(x: 0, y: -2)
        collisionMode = .circle
        canShowCallout = false
        displayPriority = .defaultHigh

        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 17
        blurView.clipsToBounds = true
        blurView.layer.borderWidth = 1
        blurView.layer.borderColor = UIColor.white.withAlphaComponent(0.72).cgColor
        addSubview(blurView)

        tintView.frame = blurView.bounds
        tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.contentView.addSubview(tintView)

        glyphView.contentMode = .scaleAspectFit
        glyphView.tintColor = .white
        glyphView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(glyphView)
        NSLayoutConstraint.activate([
            glyphView.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            glyphView.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor),
            glyphView.widthAnchor.constraint(equalToConstant: 14),
            glyphView.heightAnchor.constraint(equalToConstant: 14)
        ])

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 7
        layer.shadowOpacity = 0.18
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            applySelectionStyle(animated: true)
        }
    }

    func configure(with annotation: POIAnnotation) {
        self.annotation = annotation
        clusteringIdentifier = "explore-poi"

        let baseColor = UIColor(annotation.poi.category.chipColor)
        tintView.backgroundColor = baseColor
            .withAlphaComponent(annotation.poi.confidence >= 0.45 ? 0.82 : 0.62)
        glyphView.image = UIImage(
            systemName: annotation.poi.category.icon,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        )
        glyphView.tintColor = .white
        applySelectionStyle(animated: false)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        transform = .identity
        alpha = 1
        layer.shadowOpacity = 0.18
    }

    private func applySelectionStyle(animated: Bool) {
        let apply = { [self] in
            transform = isSelected ? CGAffineTransform(scaleX: 1.13, y: 1.13) : .identity
            layer.shadowOpacity = isSelected ? 0.30 : 0.18
            layer.shadowRadius = isSelected ? 11 : 7
            blurView.layer.borderColor = UIColor.white.withAlphaComponent(isSelected ? 0.95 : 0.72).cgColor
        }

        if animated {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: apply)
        } else {
            apply()
        }
    }
}

private final class POIClusterAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "POIClusterAnnotationView"

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let tintView = UIView()
    private let countLabel = UILabel()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 42, height: 42)
        collisionMode = .circle
        centerOffset = CGPoint(x: 0, y: -2)

        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 21
        blurView.clipsToBounds = true
        blurView.layer.borderWidth = 1
        blurView.layer.borderColor = UIColor.white.withAlphaComponent(0.78).cgColor
        addSubview(blurView)

        tintView.frame = blurView.bounds
        tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.contentView.addSubview(tintView)

        countLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        countLabel.textAlignment = .center
        countLabel.textColor = .white
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(countLabel)
        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: blurView.contentView.centerXAnchor),
            countLabel.centerYAnchor.constraint(equalTo: blurView.contentView.centerYAnchor)
        ])

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowRadius = 10
        layer.shadowOpacity = 0.22
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with annotation: MKClusterAnnotation) {
        self.annotation = annotation
        let categories = annotation.memberAnnotations.compactMap { ($0 as? POIAnnotation)?.poi.category }
        let dominantCategory = Dictionary(grouping: categories, by: { $0 })
            .max(by: { $0.value.count < $1.value.count })?
            .key

        let baseColor = UIColor(dominantCategory?.chipColor ?? Color.accentColor)
        tintView.backgroundColor = baseColor.withAlphaComponent(0.84)
        blurView.layer.borderColor = UIColor.white.withAlphaComponent(0.82).cgColor
        countLabel.text = "\(annotation.memberAnnotations.count)"

        let count = annotation.memberAnnotations.count
        let targetSize: CGFloat = count >= 100 ? 48 : (count >= 10 ? 44 : 40)
        if abs(bounds.width - targetSize) > 0.5 {
            bounds = CGRect(x: 0, y: 0, width: targetSize, height: targetSize)
            blurView.frame = bounds
            blurView.layer.cornerRadius = targetSize / 2
        }

        transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.transform = .identity
        }
    }
}

private extension MKCoordinateRegion {
    func isApproximatelyEqual(to other: MKCoordinateRegion) -> Bool {
        abs(center.latitude - other.center.latitude) < 0.0008 &&
        abs(center.longitude - other.center.longitude) < 0.0008 &&
        abs(span.latitudeDelta - other.span.latitudeDelta) < 0.001 &&
        abs(span.longitudeDelta - other.span.longitudeDelta) < 0.001
    }
}

private extension POIItem {
    var distanceText: String? {
        guard let distanceMeters else { return nil }
        return ExploreDistanceFormatter.shared.string(fromMeters: distanceMeters)
    }
}

private final class ExploreDistanceFormatter {
    static let shared = ExploreDistanceFormatter()

    private let measurementFormatter: MeasurementFormatter

    private init() {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1

        measurementFormatter = MeasurementFormatter()
        measurementFormatter.numberFormatter = numberFormatter
        measurementFormatter.unitStyle = .short
        measurementFormatter.unitOptions = .naturalScale
    }

    func string(fromMeters meters: CLLocationDistance) -> String {
        measurementFormatter.string(from: Measurement(value: meters, unit: UnitLength.meters))
    }
}
