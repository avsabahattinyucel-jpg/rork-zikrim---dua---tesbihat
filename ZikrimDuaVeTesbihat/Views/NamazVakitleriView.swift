import SwiftUI
import Combine
import AVFoundation
import UserNotifications
import UIKit

struct NamazVakitleriView: View {
    @State private var prayerService = PrayerTimeService()
    @State private var notificationService = NotificationService()
    @State private var adhanPlayer = AdhanPlayerService.shared
    @State private var showCityPicker: Bool = false
    @State private var timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var currentTime: Date = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if prayerService.isLoading {
                        loadingCard
                    } else if let times = prayerService.prayerTimes {
                        nextPrayerCard(times: times)
                        dateCard
                        prayerTimesGrid(times: times)
                    } else if let error = prayerService.errorMessage {
                        errorCard(error)
                    } else {
                        loadingCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Namaz Vakitleri")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCityPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                            Text(prayerService.selectedCity.name)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerView(prayerService: prayerService)
            }
            .onReceive(timer) { date in
                currentTime = date
            }
            .task {
                await prayerService.fetchPrayerTimes()
                await notificationService.checkAuthorization()
                if notificationService.prayerNotificationsEnabled,
                   notificationService.isAuthorized,
                   let times = prayerService.prayerTimes {
                    schedulePrayerNotifications(times: times)
                }
            }
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            Text("Namaz vakitleri yükleniyor...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }

    private func nextPrayerCard(times: PrayerTimes) -> some View {
        VStack(spacing: 12) {
            if let next = prayerService.nextPrayer() {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sıradaki Namaz")
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.8))
                            .textCase(.uppercase)
                            .kerning(0.5)

                        Text(next.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)

                        if let mins = prayerService.minutesUntilNextPrayer() {
                            let h = mins / 60
                            let m = mins % 60
                            Text(h > 0 ? "\(h) saat \(m) dakika sonra" : "\(m) dakika sonra")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        Image(systemName: next.systemImage)
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(0.9))
                        Text(next.time)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                }
                .padding(20)
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.25, blue: 0.4), Color(red: 0.0, green: 0.4, blue: 0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: 20))
    }

    private var dateCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date(), style: .date)
                    .font(.subheadline.bold())
                if !prayerService.gregorianWeekday.isEmpty {
                    Text(prayerService.gregorianWeekday)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if !prayerService.hijriDate.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(prayerService.hijriDate)
                        .font(.subheadline.bold())
                    Text("Hicri Takvim")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private func prayerTimesGrid(times: PrayerTimes) -> some View {
        let prayers: [(String, String, String)] = [
            ("İmsak", times.fajr, "moon.stars.fill"),
            ("Güneş", times.sunrise, "sunrise.fill"),
            ("Öğle", times.dhuhr, "sun.max.fill"),
            ("İkindi", times.asr, "sun.haze.fill"),
            ("Akşam", times.maghrib, "sunset.fill"),
            ("Yatsı", times.isha, "moon.fill")
        ]

        let nextPrayerName = prayerService.nextPrayer()?.name

        return VStack(spacing: 1) {
            ForEach(Array(prayers.enumerated()), id: \.offset) { index, prayer in
                PrayerTimeRow(
                    name: prayer.0,
                    time: prayer.1,
                    icon: prayer.2,
                    isNext: prayer.0 == nextPrayerName,
                    isFirst: index == 0,
                    isLast: index == prayers.count - 1
                )
            }
        }
        .clipShape(.rect(cornerRadius: 16))
    }

    private var notificationSettingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.teal)
                Text("Bildirim Ayarları")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                settingRow(
                    icon: "bell.fill",
                    iconColor: .blue,
                    title: "Namaz Bildirimleri",
                    subtitle: "Her vakit için bildirim al",
                    isOn: Binding(
                        get: { notificationService.prayerNotificationsEnabled },
                        set: { newValue in
                            notificationService.prayerNotificationsEnabled = newValue
                            Task {
                                if !notificationService.isAuthorized {
                                    await notificationService.requestAuthorization()
                                }
                                if newValue, let times = prayerService.prayerTimes {
                                    schedulePrayerNotifications(times: times)
                                } else {
                                    notificationService.cancelPrayerNotifications()
                                }
                            }
                        }
                    )
                )

                if notificationService.prayerNotificationsEnabled {
                    Divider().padding(.leading, 56)
                    volumeRow
                    Divider().padding(.leading, 56)
                    vibrationOnlyRow
                    Divider().padding(.leading, 56)
                    playInSilentRow
                    Divider().padding(.leading, 56)
                    previewSoundRow
                    Divider().padding(.leading, 56)
                    testNotificationRow
                }

                Divider().padding(.leading, 56)

                smartNotificationsRow

                Divider().padding(.leading, 56)

                settingRow(
                    icon: "sunrise.fill",
                    iconColor: .orange,
                    title: "Sabah Hatırlatıcı",
                    subtitle: "Sabah zikirleri için hatırlatıcı",
                    isOn: Binding(
                        get: { notificationService.morningReminderEnabled },
                        set: { newValue in
                            notificationService.morningReminderEnabled = newValue
                            Task {
                                if !notificationService.isAuthorized {
                                    await notificationService.requestAuthorization()
                                }
                                notificationService.scheduleMorningReminder()
                            }
                        }
                    )
                )

                if notificationService.morningReminderEnabled {
                    Divider().padding(.leading, 56)
                    DatePicker("Saat", selection: Binding(
                        get: { notificationService.morningTime },
                        set: {
                            notificationService.morningTime = $0
                            notificationService.scheduleMorningReminder()
                        }
                    ), displayedComponents: .hourAndMinute)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                Divider().padding(.leading, 56)

                settingRow(
                    icon: "sunset.fill",
                    iconColor: .purple,
                    title: "Akşam Hatırlatıcı",
                    subtitle: "Akşam zikirleri için hatırlatıcı",
                    isOn: Binding(
                        get: { notificationService.eveningReminderEnabled },
                        set: { newValue in
                            notificationService.eveningReminderEnabled = newValue
                            Task {
                                if !notificationService.isAuthorized {
                                    await notificationService.requestAuthorization()
                                }
                                notificationService.scheduleEveningReminder()
                            }
                        }
                    )
                )

                if notificationService.eveningReminderEnabled {
                    Divider().padding(.leading, 56)
                    DatePicker("Saat", selection: Binding(
                        get: { notificationService.eveningTime },
                        set: {
                            notificationService.eveningTime = $0
                            notificationService.scheduleEveningReminder()
                        }
                    ), displayedComponents: .hourAndMinute)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
            .padding(.bottom, 4)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }

    private var previewSoundRow: some View {
        Button {
            adhanPlayer.preview()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: adhanPlayer.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.indigo)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ezan Sesini Dinle")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text("Varsayılan bildirim sesi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: adhanPlayer.isPlaying ? "speaker.wave.3.fill" : "speaker.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var vibrationOnlyRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
            }
            Text("Yalnızca titreşim")
                .font(.subheadline)
            Spacer()
            Toggle("", isOn: $notificationService.vibrationOnlyMode)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var playInSilentRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.pink.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.pink)
            }
            Text("Sessiz modda da çal")
                .font(.subheadline)
            Spacer()
            Toggle("", isOn: $notificationService.playEvenInSilentMode)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var testNotificationRow: some View {
        Button {
            let content = UNMutableNotificationContent()
            content.title = "Test Bildirimi"
            content.body = "Ezan sesi bildirim testi."
            if notificationService.vibrationOnlyMode {
                content.sound = nil
            } else {
                content.sound = UNNotificationSound(named: AdhanPlayerService.shared.notificationSoundName)
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "prayer_test_notification", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Label("Test bildirimi gönder", systemImage: "paperplane.fill")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var smartNotificationsRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(.indigo)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Akıllı Bildirimler")
                        .font(.subheadline)
                    Text("Günde en fazla 2 sakin hatırlatma")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { notificationService.smartNotificationsEnabled },
                    set: { newValue in
                        notificationService.smartNotificationsEnabled = newValue
                        notificationService.scheduleSmartNotifications()
                    }
                ))
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if notificationService.smartNotificationsEnabled {
                ForEach(SmartNotificationType.allCases, id: \.self) { type in
                    Button {
                        notificationService.toggleSmartType(type)
                        notificationService.scheduleSmartNotifications()
                    } label: {
                        HStack {
                            Text(type.title)
                                .font(.caption)
                                .foregroundStyle(.primary)
                            Spacer()
                            if notificationService.enabledSmartTypes.contains(type) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.teal)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                Text("Sessiz saatler: 22:00 - 08:00")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
    }

    private var volumeRow: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.green)
            }
            Text("Ses Seviyesi")
                .font(.subheadline)
            Spacer()
            Slider(value: Binding(
                get: { Double(adhanPlayer.volume) },
                set: { adhanPlayer.volume = Float($0) }
            ), in: 0...1)
            .frame(width: 120)
            .tint(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func settingRow(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func schedulePrayerNotifications(times: PrayerTimes) {
        notificationService.schedulePrayerNotification(prayerName: "İmsak", time: times.fajr, identifier: "prayer_fajr")
        notificationService.schedulePrayerNotification(prayerName: "Öğle", time: times.dhuhr, identifier: "prayer_dhuhr")
        notificationService.schedulePrayerNotification(prayerName: "İkindi", time: times.asr, identifier: "prayer_asr")
        notificationService.schedulePrayerNotification(prayerName: "Akşam", time: times.maghrib, identifier: "prayer_maghrib")
        notificationService.schedulePrayerNotification(prayerName: "Yatsı", time: times.isha, identifier: "prayer_isha")
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await prayerService.fetchPrayerTimes() }
            } label: {
                Label("Tekrar Dene", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }
}

struct PrayerTimeRow: View {
    let name: String
    let time: String
    let icon: String
    let isNext: Bool
    let isFirst: Bool
    let isLast: Bool

    private var iconColor: Color {
        switch name {
        case "İmsak": return .indigo
        case "Güneş": return .orange
        case "Öğle": return .yellow
        case "İkindi": return .green
        case "Akşam": return .red
        case "Yatsı": return .purple
        default: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isNext ? .white : iconColor)
                .frame(width: 28)

            Text(name)
                .font(.body.bold())
                .foregroundStyle(isNext ? .white : .primary)

            Spacer()

            Text(time)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(isNext ? .white : .primary)

            if isNext {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(isNext ? Color.teal : Color(.secondarySystemGroupedBackground))
    }
}

struct CityPickerView: View {
    let prayerService: PrayerTimeService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    private var filtered: [TurkishCity] {
        guard !searchText.isEmpty else { return TurkishCities.all }
        return TurkishCities.all.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { city in
                Button {
                    prayerService.selectCity(city)
                    dismiss()
                } label: {
                    HStack {
                        Text(city.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if city.id == prayerService.selectedCity.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.teal)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Şehir ara...")
            .navigationTitle("Şehir Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
}
