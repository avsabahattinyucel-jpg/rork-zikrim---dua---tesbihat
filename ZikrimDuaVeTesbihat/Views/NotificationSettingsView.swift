import SwiftUI
import UIKit
import UserNotifications

struct NotificationSettingsView: View {
    @State private var notificationService = NotificationService()
    @State private var adhanPlayer = AdhanPlayerService.shared
    @State private var prayerService = PrayerTimeService()
    @State private var showSystemSettings: Bool = false
    @State private var selectedOffset: PrayerReminderOffset = .atTime

    private let teal = Color(red: 0.2, green: 0.8, blue: 0.7)

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    authorizationBanner
                    prayerSection
                    dailyDuaSection
                    remindersSection
                    soundSection
                    testSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Bildirim & Ses Ayarları")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await notificationService.checkAuthorization()
            await prayerService.fetchPrayerTimes()
            selectedOffset = notificationService.prayerReminderOffset
        }
        .onDisappear {
            adhanPlayer.stop()
        }
    }

    @ViewBuilder
    private var authorizationBanner: some View {
        if !notificationService.isAuthorized {
            Button {
                Task {
                    await notificationService.requestAuthorization()
                    await notificationService.checkAuthorization()
                    if !notificationService.isAuthorized {
                        showSystemSettings = true
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Bildirimler Kapalı")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Hatırlatmaları almak için izin verin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .background(Color.orange.opacity(0.08), in: .rect(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var prayerSection: some View {
        SettingsCard(title: "Namaz Vakti Hatırlatıcı", icon: "moon.stars.fill", iconColor: teal) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Namaz Bildirimleri",
                    subtitle: "Vakit girişinde bildirim al",
                    tintColor: teal,
                    isOn: Binding(
                        get: { notificationService.prayerNotificationsEnabled },
                        set: { newValue in
                            withAnimation(.spring(duration: 0.35)) {
                                notificationService.prayerNotificationsEnabled = newValue
                            }
                            Task {
                                await ensureAuth(enabled: newValue)
                                if newValue, let times = prayerService.prayerTimes {
                                    schedulePrayers(times: times)
                                } else {
                                    notificationService.cancelPrayerNotifications()
                                }
                            }
                        }
                    )
                )

                if notificationService.prayerNotificationsEnabled {
                    Divider().padding(.leading, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vaktinden Önce Hatırlat")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .padding(.top, 4)

                        HStack(spacing: 8) {
                            ForEach(PrayerReminderOffset.allCases, id: \.rawValue) { offset in
                                Button {
                                    withAnimation(.spring(duration: 0.25)) {
                                        selectedOffset = offset
                                    }
                                    notificationService.prayerReminderOffset = offset
                                    if let times = prayerService.prayerTimes {
                                        schedulePrayers(times: times)
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Text(offset.shortName)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(selectedOffset == offset ? .white : .secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(
                                            selectedOffset == offset
                                            ? teal
                                            : Color(.tertiarySystemFill)
                                        )
                                        .clipShape(.rect(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95, anchor: .top)),
                        removal: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95, anchor: .top))
                    ))

                    Divider().padding(.leading, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(teal)
                            Text("Bildirim Sesi")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                        .padding(.top, 4)

                        SettingsToggleRow(
                            title: "Titreşim Modu",
                            subtitle: "Yalnızca titreşim, ses çalınmaz",
                            tintColor: teal,
                            isOn: Binding(
                                get: { notificationService.vibrationOnlyMode },
                                set: { newValue in
                                    withAnimation(.spring(duration: 0.35)) {
                                        notificationService.vibrationOnlyMode = newValue
                                    }
                                }
                            )
                        )
                        .padding(.horizontal, -16)

                        if !notificationService.vibrationOnlyMode {
                            Button {
                                adhanPlayer.preview()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: adhanPlayer.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(teal)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Ezan Sesi")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text(adhanPlayer.isPlaying ? "Durdurmak için dokunun" : "Dinlemek için dokunun")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: adhanPlayer.isPlaying ? "speaker.wave.3.fill" : "speaker.fill")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
            }
        }
    }

    private var dailyDuaSection: some View {
        SettingsCard(title: "Günün Duası / Zikri", icon: "hands.sparkles.fill", iconColor: Color(red: 0.5, green: 0.4, blue: 0.9)) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Günlük Dua Bildirimi",
                    subtitle: "Her gün farklı bir dua ve zikir",
                    tintColor: Color(red: 0.5, green: 0.4, blue: 0.9),
                    isOn: Binding(
                        get: { notificationService.dailyDuaEnabled },
                        set: { newValue in
                            withAnimation(.spring(duration: 0.35)) {
                                notificationService.dailyDuaEnabled = newValue
                            }
                            Task {
                                await ensureAuth(enabled: newValue)
                                notificationService.scheduleDailyDuaNotifications()
                            }
                        }
                    )
                )

                if notificationService.dailyDuaEnabled {
                    Divider().padding(.leading, 16)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bildirim Saati")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text("14 günlük dua bildirimi planlanır")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { notificationService.dailyDuaTime },
                                set: { newVal in
                                    notificationService.dailyDuaTime = newVal
                                    notificationService.scheduleDailyDuaNotifications()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
            }
        }
    }

    private var remindersSection: some View {
        SettingsCard(title: "Kişisel Hatırlatmalar", icon: "bell.badge.fill", iconColor: Color(red: 1.0, green: 0.6, blue: 0.2)) {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Sabah Hatırlatıcı",
                    subtitle: "Güne zikirle başlayın",
                    tintColor: Color(red: 1.0, green: 0.6, blue: 0.2),
                    isOn: Binding(
                        get: { notificationService.morningReminderEnabled },
                        set: { newValue in
                            withAnimation(.spring(duration: 0.35)) {
                                notificationService.morningReminderEnabled = newValue
                            }
                            Task {
                                await ensureAuth(enabled: newValue)
                                notificationService.scheduleMorningReminder()
                            }
                        }
                    )
                )

                if notificationService.morningReminderEnabled {
                    Divider().padding(.leading, 16)
                    HStack {
                        Text("Saat")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { notificationService.morningTime },
                                set: {
                                    notificationService.morningTime = $0
                                    notificationService.scheduleMorningReminder()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }

                Divider().padding(.leading, 16)

                SettingsToggleRow(
                    title: "Akşam Hatırlatıcı",
                    subtitle: "Günü zikirle kapatın",
                    tintColor: Color(red: 1.0, green: 0.6, blue: 0.2),
                    isOn: Binding(
                        get: { notificationService.eveningReminderEnabled },
                        set: { newValue in
                            withAnimation(.spring(duration: 0.35)) {
                                notificationService.eveningReminderEnabled = newValue
                            }
                            Task {
                                await ensureAuth(enabled: newValue)
                                notificationService.scheduleEveningReminder()
                            }
                        }
                    )
                )

                if notificationService.eveningReminderEnabled {
                    Divider().padding(.leading, 16)
                    HStack {
                        Text("Saat")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { notificationService.eveningTime },
                                set: {
                                    notificationService.eveningTime = $0
                                    notificationService.scheduleEveningReminder()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }

                Divider().padding(.leading, 16)

                SettingsToggleRow(
                    title: "Akıllı Hatırlatmalar",
                    subtitle: "Kullanım alışkanlığınıza göre",
                    tintColor: Color(red: 1.0, green: 0.6, blue: 0.2),
                    isOn: Binding(
                        get: { notificationService.smartNotificationsEnabled },
                        set: { newValue in
                            withAnimation(.spring(duration: 0.35)) {
                                notificationService.smartNotificationsEnabled = newValue
                            }
                            Task {
                                await ensureAuth(enabled: newValue)
                                notificationService.scheduleSmartNotifications()
                            }
                        }
                    )
                )
            }
        }
    }

    private var soundSection: some View {
        SettingsCard(title: "Genel Ses Ayarları", icon: "speaker.wave.2.fill", iconColor: Color(red: 0.3, green: 0.7, blue: 0.4)) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sessiz Modda Çal")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("Telefon sessizde bile ezan çalsın")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { notificationService.playEvenInSilentMode },
                        set: { notificationService.playEvenInSilentMode = $0 }
                    ))
                    .labelsHidden()
                    .tint(Color(red: 0.3, green: 0.7, blue: 0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ses Seviyesi")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("Ezan ve bildirim sesi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(
                            value: Binding(
                                get: { Double(adhanPlayer.volume) },
                                set: { adhanPlayer.volume = Float($0) }
                            ),
                            in: 0...1
                        )
                        .tint(Color(red: 0.3, green: 0.7, blue: 0.4))
                        .frame(width: 120)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private var testSection: some View {
        Button {
            Task {
                if !notificationService.isAuthorized {
                    await notificationService.requestAuthorization()
                    await notificationService.checkAuthorization()
                }
                if notificationService.isAuthorized {
                    sendTestNotification()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(teal.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(teal)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Test Bildirimi Gönder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Ayarlarınızı deneyerek kontrol edin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private func ensureAuth(enabled: Bool) async {
        guard enabled else { return }
        if !notificationService.isAuthorized {
            await notificationService.requestAuthorization()
            await notificationService.checkAuthorization()
        }
    }

    private func schedulePrayers(times: PrayerTimes) {
        notificationService.schedulePrayerNotification(prayerName: "İmsak", time: times.fajr, identifier: "prayer_fajr")
        notificationService.schedulePrayerNotification(prayerName: "Öğle", time: times.dhuhr, identifier: "prayer_dhuhr")
        notificationService.schedulePrayerNotification(prayerName: "İkindi", time: times.asr, identifier: "prayer_asr")
        notificationService.schedulePrayerNotification(prayerName: "Akşam", time: times.maghrib, identifier: "prayer_maghrib")
        notificationService.schedulePrayerNotification(prayerName: "Yatsı", time: times.isha, identifier: "prayer_isha")
    }

    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Zikrim"
        content.body = "Bildirimler aktif. Allah'ın zikriyle kalpler huzur bulur. (Ra'd, 28)"
        if notificationService.vibrationOnlyMode {
            content.sound = nil
        } else {
            content.sound = UNNotificationSound(named: AdhanPlayerService.shared.notificationSoundName)
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "notification_settings_test", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    var tintColor: Color = Color(red: 0.2, green: 0.8, blue: 0.7)
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(tintColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
