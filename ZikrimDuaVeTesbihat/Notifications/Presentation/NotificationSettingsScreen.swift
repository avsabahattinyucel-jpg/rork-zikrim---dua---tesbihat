import SwiftUI

struct NotificationSettingsScreen: View {
    @StateObject private var viewModel: NotificationSettingsViewModel
    @StateObject private var soundPreviewPlayer = NotificationSoundPreviewPlayer()

    init(viewModel: NotificationSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                prayerSection
                dailySection
                smartSection
                fridaySection
                soundSection
                quietHoursSection
                #if DEBUG
                debugSection
                #endif
            }
            .padding(18)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(viewModel.text(.settingsTitle))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            soundPreviewPlayer.stop()
        }
        .task {
            await viewModel.refresh()
        }
        .sheet(isPresented: $viewModel.showSoftAsk) {
            NotificationPermissionSoftAskView(
                title: viewModel.text(.softAskTitle),
                message: viewModel.text(.softAskBody),
                primaryTitle: viewModel.text(.softAskPrimary),
                secondaryTitle: viewModel.text(.softAskSecondary),
                primaryAction: {
                    Task { await viewModel.requestPermissionAfterSoftAsk() }
                },
                secondaryAction: {
                    viewModel.showSoftAsk = false
                }
            )
            .presentationDetents([.medium])
        }
        .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var prayerSection: some View {
        NotificationSectionCard(
            title: viewModel.text(.prayerSectionTitle),
            subtitle: viewModel.text(.prayerSectionSubtitle),
            icon: "moon.stars.fill",
            tint: Color(red: 0.10, green: 0.46, blue: 0.55)
        ) {
            NotificationToggleRow(
                title: viewModel.text(.summaryPrayer),
                subtitle: nil,
                isOn: viewModel.binding(
                    get: { $0.prayerNotificationsEnabled },
                    set: { $0.prayerNotificationsEnabled = $1 }
                )
            )

            if viewModel.settings.prayerNotificationsEnabled {
                Divider()
                Text(viewModel.text(.perPrayerTitle))
                    .font(.subheadline.weight(.semibold))

                prayerToggle(prayer: .fajr)
                prayerToggle(prayer: .dhuhr)
                prayerToggle(prayer: .asr)
                prayerToggle(prayer: .maghrib)
                prayerToggle(prayer: .isha)

                Divider()
                Picker(
                    selection: viewModel.binding(
                        get: { $0.reminderTimingMode },
                        set: { $0.reminderTimingMode = $1 }
                    )
                ) {
                    Text(viewModel.text(.prayerAtTime)).tag(PrayerReminderTimingMode.atTime)
                    Text(viewModel.text(.prayer15Before)).tag(PrayerReminderTimingMode.fifteenMinutesBefore)
                    Text(viewModel.text(.prayer30Before)).tag(PrayerReminderTimingMode.thirtyMinutesBefore)
                    Text(viewModel.text(.prayerBoth)).tag(PrayerReminderTimingMode.bothBeforeAndAtTime)
                } label: {
                    Text(viewModel.text(.summaryPrayer))
                        .font(.subheadline.weight(.medium))
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var dailySection: some View {
        NotificationSectionCard(
            title: viewModel.text(.dailyRemindersTitle),
            subtitle: viewModel.text(.dailyRemindersSubtitle),
            icon: "sun.max.fill",
            tint: Color(red: 0.88, green: 0.58, blue: 0.17)
        ) {
            reminderRow(title: viewModel.text(.dailyDua), time: viewModel.binding(get: { $0.dailyDuaTime }, set: { $0.dailyDuaTime = $1 }), enabled: viewModel.binding(get: { $0.dailyDuaEnabled }, set: { $0.dailyDuaEnabled = $1 }))
            reminderRow(title: viewModel.text(.morningReminder), time: viewModel.binding(get: { $0.morningReminderTime }, set: { $0.morningReminderTime = $1 }), enabled: viewModel.binding(get: { $0.morningReminderEnabled }, set: { $0.morningReminderEnabled = $1 }))
            reminderRow(title: viewModel.text(.eveningReminder), time: viewModel.binding(get: { $0.eveningReminderTime }, set: { $0.eveningReminderTime = $1 }), enabled: viewModel.binding(get: { $0.eveningReminderEnabled }, set: { $0.eveningReminderEnabled = $1 }))
            reminderRow(title: viewModel.text(.sleepReminder), time: viewModel.binding(get: { $0.sleepReminderTime }, set: { $0.sleepReminderTime = $1 }), enabled: viewModel.binding(get: { $0.sleepReminderEnabled }, set: { $0.sleepReminderEnabled = $1 }), premiumOnly: true)
        }
    }

    private var smartSection: some View {
        NotificationSectionCard(
            title: viewModel.text(.smartRemindersTitle),
            subtitle: viewModel.text(.smartRemindersSubtitle),
            icon: "sparkles",
            tint: Color(red: 0.25, green: 0.54, blue: 0.44)
        ) {
            HStack {
                NotificationToggleRow(
                    title: viewModel.text(.smartRemindersTitle),
                    subtitle: nil,
                    isOn: viewModel.binding(
                        get: { $0.smartRemindersEnabled },
                        set: { $0.smartRemindersEnabled = $1 }
                    ),
                    isDisabled: !viewModel.settings.premiumEnabled
                )
                if !viewModel.settings.premiumEnabled {
                    NotificationPremiumBadge(text: viewModel.text(.premiumPlan))
                }
            }

            if !viewModel.settings.premiumEnabled {
                Text(viewModel.text(.premiumDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Picker(
                viewModel.text(.smartIntensity),
                selection: viewModel.binding(
                    get: { $0.smartReminderIntensity },
                    set: { $0.smartReminderIntensity = $1 }
                )
            ) {
                Text(viewModel.text(.intensityLight)).tag(SmartReminderIntensity.light)
                Text(viewModel.text(.intensityBalanced)).tag(SmartReminderIntensity.balanced)
                Text(viewModel.text(.intensityFrequent)).tag(SmartReminderIntensity.frequent)
            }
            .pickerStyle(.segmented)
            .disabled(!viewModel.settings.premiumEnabled)
        }
    }

    private var fridaySection: some View {
        NotificationSectionCard(
            title: viewModel.text(.fridaySectionTitle),
            subtitle: viewModel.text(.fridaySectionSubtitle),
            icon: "calendar",
            tint: Color(red: 0.48, green: 0.34, blue: 0.70)
        ) {
            reminderRow(title: viewModel.text(.fridayReminder), time: viewModel.binding(get: { $0.fridayReminderTime }, set: { $0.fridayReminderTime = $1 }), enabled: viewModel.binding(get: { $0.fridayReminderEnabled }, set: { $0.fridayReminderEnabled = $1 }), premiumOnly: true)
            reminderRow(title: viewModel.text(.specialDays), time: viewModel.binding(get: { $0.specialIslamicDayReminderTime }, set: { $0.specialIslamicDayReminderTime = $1 }), enabled: viewModel.binding(get: { $0.specialIslamicDaysEnabled }, set: { $0.specialIslamicDaysEnabled = $1 }), premiumOnly: true)
        }
    }

    private var soundSection: some View {
        NotificationSectionCard(
            title: viewModel.text(.soundSectionTitle),
            subtitle: viewModel.text(.soundSectionSubtitle),
            icon: "speaker.wave.2.fill",
            tint: Color(red: 0.80, green: 0.40, blue: 0.18)
        ) {
            NotificationToggleRow(
                title: viewModel.text(.vibrationOnly),
                subtitle: nil,
                isOn: viewModel.binding(
                    get: { $0.vibrationOnly },
                    set: { $0.vibrationOnly = $1 }
                )
            )

            Picker(
                viewModel.text(.soundOption),
                selection: viewModel.binding(
                    get: { $0.soundSelection.preset },
                    set: { settings, preset in
                        settings.soundSelection.preset = preset.normalizedForCurrentCatalog
                    }
                )
            ) {
                Text(viewModel.text(.soundSystem)).tag(NotificationSoundPreset.system)
                Text(viewModel.text(.soundNur)).tag(NotificationSoundPreset.nur)
                Text(viewModel.text(.soundSafa)).tag(NotificationSoundPreset.safa)
                Text(viewModel.text(.soundMerve)).tag(NotificationSoundPreset.merve)
                Text(viewModel.text(.soundHuzur)).tag(NotificationSoundPreset.huzur)
            }
            .pickerStyle(.menu)
            .disabled(viewModel.settings.vibrationOnly)

            Text(viewModel.text(.soundPrayerFixedNote))
                .font(.caption)
                .foregroundStyle(.secondary)

            NotificationActionButton(
                title: soundPreviewPlayer.isPlaying ? viewModel.text(.soundStopPreview) : viewModel.text(.soundPreview),
                icon: soundPreviewPlayer.isPlaying ? "stop.fill" : "play.fill",
                prominent: false
            ) {
                soundPreviewPlayer.togglePreview(for: viewModel.settings.soundSelection)
            }

            Divider()

            if viewModel.shouldShowPermissionAction {
                NotificationActionButton(
                    title: permissionButtonTitle,
                    icon: permissionIcon,
                    prominent: true
                ) {
                    Task {
                        if viewModel.permissionState == .denied {
                            viewModel.openSystemSettings()
                        } else {
                            await viewModel.requestPermission()
                        }
                    }
                }
            }

            if viewModel.shouldShowQuietDeliveryWarning {
                Text(viewModel.permissionWarningMessage ?? viewModel.text(.permissionQuietDeliveryMessage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                NotificationActionButton(
                    title: viewModel.text(.rebuildNotifications),
                    icon: "arrow.clockwise",
                    prominent: false
                ) {
                    Task { await viewModel.rebuildNow() }
                }
            }
        }
    }

    private var quietHoursSection: some View {
        NotificationSectionCard(
            title: viewModel.text(.quietHoursTitle),
            subtitle: viewModel.text(.quietHoursSubtitle),
            icon: "bed.double.fill",
            tint: Color(red: 0.16, green: 0.34, blue: 0.59)
        ) {
            NotificationToggleRow(
                title: viewModel.text(.quietHoursEnabled),
                subtitle: nil,
                isOn: viewModel.binding(
                    get: { $0.quietHours.isEnabled },
                    set: { $0.quietHours.isEnabled = $1 }
                )
            )

            if viewModel.settings.quietHours.isEnabled {
                timePickerRow(
                    title: viewModel.text(.quietHoursStart),
                    time: viewModel.binding(get: { $0.quietHours.start }, set: { $0.quietHours.start = $1 })
                )
                timePickerRow(
                    title: viewModel.text(.quietHoursEnd),
                    time: viewModel.binding(get: { $0.quietHours.end }, set: { $0.quietHours.end = $1 })
                )
            }
        }
    }

    #if DEBUG
    private var debugSection: some View {
        NotificationSectionCard(
            title: viewModel.text(.debugToolsTitle),
            subtitle: viewModel.text(.debugOnlyCaption),
            icon: "ladybug.fill",
            tint: .red
        ) {
            NotificationActionButton(title: viewModel.text(.rebuildNotifications), icon: "arrow.clockwise", prominent: false) {
                Task { await viewModel.rebuildNow() }
            }
            NotificationActionButton(title: viewModel.text(.clearNotifications), icon: "trash", prominent: false) {
                Task { await viewModel.clearAll() }
            }
            NotificationActionButton(title: viewModel.text(.testNotification), icon: "paperplane.fill", prominent: false) {
                Task { await viewModel.sendTestNotification() }
            }
            NotificationActionButton(title: viewModel.text(.printPending), icon: "doc.text.magnifyingglass", prominent: false) {
                Task { await viewModel.printPending() }
            }
        }
    }
    #endif

    private func prayerToggle(prayer: PrayerName) -> some View {
        NotificationToggleRow(
            title: NotificationLocalization.prayerName(prayer, languageCode: viewModel.languageCode),
            subtitle: nil,
            isOn: viewModel.binding(
                get: { $0.prayerPreferences[prayer] },
                set: { $0.prayerPreferences[prayer] = $1 }
            )
        )
    }

    private func reminderRow(
        title: String,
        time: Binding<ClockTime>,
        enabled: Binding<Bool>,
        premiumOnly: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                NotificationToggleRow(
                    title: title,
                    subtitle: nil,
                    isOn: enabled,
                    isDisabled: premiumOnly && !viewModel.settings.premiumEnabled
                )
                if premiumOnly {
                    NotificationPremiumBadge(text: viewModel.text(.premiumPlan))
                }
            }
            if enabled.wrappedValue && (!premiumOnly || viewModel.settings.premiumEnabled) {
                timePickerRow(title: title, time: time)
            }
        }
    }

    private func timePickerRow(title: String, time: Binding<ClockTime>) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            DatePicker(
                "",
                selection: Binding(
                    get: {
                        Calendar.autoupdatingCurrent.date(from: time.wrappedValue.dateComponents()) ?? Date()
                    },
                    set: {
                        let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: $0)
                        time.wrappedValue = ClockTime(hour: components.hour ?? 0, minute: components.minute ?? 0)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
    }

    private var permissionButtonTitle: String {
        switch viewModel.permissionState {
        case .authorized, .ephemeral:
            return viewModel.shouldShowQuietDeliveryWarning
                ? viewModel.text(.permissionActionOpenSettings)
                : viewModel.text(.permissionAllowed)
        case .provisional:
            return viewModel.text(.permissionActionEnableFullAlerts)
        case .denied:
            return viewModel.text(.permissionActionOpenSettings)
        case .notDetermined:
            return viewModel.text(.permissionActionAllow)
        }
    }

    private var permissionIcon: String {
        switch viewModel.permissionState {
        case .authorized, .ephemeral:
            return viewModel.shouldShowQuietDeliveryWarning ? "gearshape.fill" : "bell.badge.fill"
        case .provisional:
            return "bell.badge.fill"
        case .denied:
            return "gearshape.fill"
        case .notDetermined:
            return "bell.fill"
        }
    }
}

struct NotificationPermissionSoftAskView: View {
    let title: String
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    let primaryAction: () -> Void
    let secondaryAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.secondary.opacity(0.18))
                .frame(width: 48, height: 5)
                .padding(.top, 12)

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                NotificationActionButton(title: primaryTitle, icon: "arrow.right.circle.fill", prominent: true, action: primaryAction)
                NotificationActionButton(title: secondaryTitle, icon: "xmark.circle", prominent: false, action: secondaryAction)
            }

            Spacer()
        }
        .padding(24)
        .background(Color(.systemGroupedBackground))
    }
}

struct NotificationSpecialDayView: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.largeTitle.weight(.semibold))
            Text("Bu mübarek gün için kısa bir dua, samimi bir zikir ve içten bir niyet yeterli olabilir.")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
