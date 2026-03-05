import SwiftUI
import MapKit

struct ManeviRehberView: View {
    @State private var viewModel = ManeviRehberViewModel()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isPremium: Bool = false

    private let spiritualGold = Color(red: 0.82, green: 0.68, blue: 0.21)
    private let spiritualGreen = Color(red: 0.13, green: 0.55, blue: 0.35)

    var body: some View {
        ZStack(alignment: .bottom) {
            mapContent

            VStack(spacing: 0) {
                categoryPicker
                    .padding(.top, 8)

                Spacer()

                if viewModel.isLoading {
                    loadingPill
                }

                if let place = viewModel.selectedPlace {
                    placeCard(place)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }
        }
        .animation(.spring(duration: 0.35), value: viewModel.selectedPlace?.id)
        .animation(.spring(duration: 0.3), value: viewModel.isLoading)
        .navigationTitle("Manevi Rehber")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        cameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
                    }
                } label: {
                    Image(systemName: "location.north.line.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(spiritualGreen)
                }
            }
        }
        .onAppear {
            if viewModel.authorizationStatus == .authorizedWhenInUse || viewModel.authorizationStatus == .authorizedAlways {
                viewModel.startUpdates()
            } else if viewModel.authorizationStatus == .notDetermined {
                viewModel.requestPermission()
            }
        }
        .onDisappear {
            viewModel.stopUpdates()
        }
        .onChange(of: viewModel.isPointingToQibla) { oldValue, newValue in
            if newValue && !oldValue {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
        .task {
            do { let info = try await RevenueCatService.shared.customerInfo(); isPremium = RevenueCatService.shared.hasActiveEntitlement(info) } catch {}
        }
        .safeAreaInset(edge: .bottom) {
            ConditionalBannerAd(isPremium: isPremium)
        }
    }

    // MARK: - Map

    private var mapContent: some View {
        Map(position: $cameraPosition, selection: Binding(
            get: { viewModel.selectedPlace?.id },
            set: { newId in
                viewModel.selectedPlace = viewModel.places.first(where: { $0.id == newId })
            }
        )) {
            UserAnnotation()

            if viewModel.userLocation != nil {
                let coords = viewModel.qiblaLineCoordinates
                if coords.count > 1 {
                    MapPolyline(coordinates: coords)
                        .stroke(
                            LinearGradient(
                                colors: [spiritualGold, spiritualGold.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.5, dash: [8, 4])
                        )
                }

                Annotation("Kabe", coordinate: ManeviRehberViewModel.kaabaCoordinate, anchor: .center) {
                    ZStack {
                        Circle()
                            .fill(spiritualGold.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: "kaaba.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(spiritualGold)
                    }
                }
            }

            ForEach(viewModel.places) { place in
                Annotation(place.name, coordinate: place.coordinate, anchor: .bottom) {
                    placePin(for: place)
                }
                .tag(place.id)
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Place Pin

    private func placePin(for place: ManeviPlace) -> some View {
        let cat = place.category
        let pinColor = Color(red: cat.color.red, green: cat.color.green, blue: cat.color.blue)
        let isSelected = viewModel.selectedPlace?.id == place.id

        return VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                    .shadow(color: pinColor.opacity(0.5), radius: isSelected ? 8 : 4, y: 2)
                Image(systemName: cat.icon)
                    .font(.system(size: isSelected ? 16 : 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            Image(systemName: "triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(pinColor)
                .rotationEffect(.degrees(180))
                .offset(y: -3)
        }
        .animation(.spring(duration: 0.25), value: isSelected)
        .onTapGesture {
            withAnimation(.spring(duration: 0.3)) {
                viewModel.selectedPlace = place
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PlaceCategory.allCases) { category in
                    let isActive = viewModel.selectedCategories.contains(category)
                    let catColor = Color(red: category.color.red, green: category.color.green, blue: category.color.blue)

                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            viewModel.toggleCategory(category)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12, weight: .bold))
                            Text(category.title)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            isActive
                                ? AnyShapeStyle(catColor)
                                : AnyShapeStyle(Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(isActive ? .white : .primary)
                        .clipShape(.capsule)
                        .overlay(
                            Capsule()
                                .strokeBorder(isActive ? catColor.opacity(0.0) : Color(.separator).opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: isActive ? catColor.opacity(0.3) : .clear, radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.selection, trigger: isActive)
                }
            }
            .padding(.horizontal, 16)
        }
        .contentMargins(.horizontal, 0)
    }

    // MARK: - Place Card

    private func placeCard(_ place: ManeviPlace) -> some View {
        let catColor = Color(red: place.category.color.red, green: place.category.color.green, blue: place.category.color.blue)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(catColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: place.category.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(catColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(place.category.title)
                            .font(.caption2.bold())
                            .foregroundStyle(catColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(catColor.opacity(0.12))
                            .clipShape(.capsule)

                        if !place.address.isEmpty {
                            Text(place.address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        viewModel.selectedPlace = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.tertiary)
                }
            }

            Button {
                viewModel.openDirections(to: place)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Yol Tarifi Al")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(catColor)
                .foregroundStyle(.white)
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 20, y: 8)
    }

    // MARK: - Loading

    private var loadingPill: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
                .scaleEffect(0.8)
            Text("Aranıyor...")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7))
        .clipShape(.capsule)
        .padding(.bottom, 8)
        .transition(.scale.combined(with: .opacity))
    }
}
