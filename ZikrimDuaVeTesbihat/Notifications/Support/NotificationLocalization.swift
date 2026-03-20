import Foundation

enum NotificationUIKey: String, CaseIterable, Sendable {
    case settingsTitle
    case overviewTitle
    case overviewSubtitle
    case prayerSectionTitle
    case prayerSectionSubtitle
    case dailyRemindersTitle
    case dailyRemindersSubtitle
    case smartRemindersTitle
    case smartRemindersSubtitle
    case fridaySectionTitle
    case fridaySectionSubtitle
    case soundSectionTitle
    case soundSectionSubtitle
    case quietHoursTitle
    case quietHoursSubtitle
    case debugToolsTitle
    case permissionAllowed
    case permissionDenied
    case permissionNotDetermined
    case permissionProvisional
    case permissionActionAllow
    case permissionActionEnableFullAlerts
    case permissionActionOpenSettings
    case permissionQuietDeliveryMessage
    case permissionProvisionalMessage
    case permissionSoundDisabledMessage
    case permissionBannerDisabledMessage
    case permissionSoundAndBannerDisabledMessage
    case testNotification
    case rebuildNotifications
    case clearNotifications
    case printPending
    case premiumRequired
    case premiumDescription
    case prayerAtTime
    case prayer15Before
    case prayer30Before
    case prayerBoth
    case morningReminder
    case eveningReminder
    case sleepReminder
    case dailyDua
    case smartIntensity
    case fridayReminder
    case specialDays
    case vibrationOnly
    case soundOption
    case quietHoursEnabled
    case quietHoursStart
    case quietHoursEnd
    case freePlan
    case premiumPlan
    case permissionFootnote
    case summaryPrayer
    case summaryMorning
    case summaryEvening
    case summarySleep
    case summarySmart
    case summaryFriday
    case summaryQuietHours
    case summaryOff
    case summarySeparator
    case summaryTimeFormat
    case summaryPremiumNote
    case intensityLight
    case intensityBalanced
    case intensityFrequent
    case soundSystem
    case soundNur
    case soundSafa
    case soundMerve
    case soundHuzur
    case soundPrayerFixedNote
    case soundPreview
    case soundStopPreview
    case perPrayerTitle
    case notificationsDisabledMessage
    case testSent
    case rebuildCompleted
    case debugOnlyCaption
    case softAskTitle
    case softAskBody
    case softAskPrimary
    case softAskSecondary
}

struct NotificationContentVariant: Sendable {
    let id: String
    let title: String
    let body: String
}

enum NotificationContentCategory: String, CaseIterable, Sendable {
    case prayerReminder
    case prayerTimeNow
    case dailyAyah
    case morningDua
    case eveningReminder
    case sleepReminder
    case smartDhikrNudge
    case fridayBlessing
    case specialDayReminder
    case streakComebackReminder
    case dailyDua
}

struct NotificationLanguagePack: Sendable {
    let ui: [NotificationUIKey: String]
    let prayerNames: [PrayerName: String]
    let content: [NotificationContentCategory: [NotificationContentVariant]]
}

enum NotificationLocalization {
    static func text(_ key: NotificationUIKey, languageCode: String) -> String {
        let language = AppLanguage(code: languageCode)
        return packs[language]?.ui[key] ?? packs[.en]?.ui[key] ?? key.rawValue
    }

    static func prayerName(_ prayer: PrayerName, languageCode: String) -> String {
        let language = AppLanguage(code: languageCode)
        return packs[language]?.prayerNames[prayer] ?? prayer.localizedName
    }

    static func variants(for category: NotificationContentCategory, languageCode: String) -> [NotificationContentVariant] {
        let language = AppLanguage(code: languageCode)
        return packs[language]?.content[category] ?? packs[.en]?.content[category] ?? []
    }

    static func isRTLLanguage(_ languageCode: String) -> Bool {
        switch AppLanguage(code: languageCode) {
        case .ar, .fa, .ur:
            return true
        default:
            return false
        }
    }

    private static let sharedUI: [NotificationUIKey: String] = [
        .settingsTitle: "Notification Settings",
        .overviewTitle: "Your calm reminder plan",
        .overviewSubtitle: "Designed to stay respectful, useful, and easy to trust.",
        .prayerSectionTitle: "Prayer notifications",
        .prayerSectionSubtitle: "Choose which prayers should reach you and when.",
        .dailyRemindersTitle: "Daily spiritual reminders",
        .dailyRemindersSubtitle: "Gentle moments for dua, morning, evening, and rest.",
        .smartRemindersTitle: "Smart reminders",
        .smartRemindersSubtitle: "Rule-based nudges that avoid clustering and stay tasteful.",
        .fridaySectionTitle: "Friday and special days",
        .fridaySectionSubtitle: "Weekly and seasonal reminders with a calm tone.",
        .soundSectionTitle: "Sound and vibration",
        .soundSectionSubtitle: "Choose a quiet, respectful alert style.",
        .quietHoursTitle: "Quiet hours",
        .quietHoursSubtitle: "Non-prayer reminders pause during these hours.",
        .debugToolsTitle: "Debug tools",
        .permissionAllowed: "Notifications allowed",
        .permissionDenied: "Notifications blocked",
        .permissionNotDetermined: "Permission not requested",
        .permissionProvisional: "Deliver quietly",
        .permissionActionAllow: "Enable notifications",
        .permissionActionEnableFullAlerts: "Enable full alerts",
        .permissionActionOpenSettings: "Open Settings",
        .permissionQuietDeliveryMessage: "iPhone is currently delivering this app's notifications quietly. Open Settings to enable sound and banners.",
        .permissionProvisionalMessage: "Notifications are currently in quiet delivery mode. Allow full alerts so prayer times and reminders can play sound.",
        .permissionSoundDisabledMessage: "Notification sounds are turned off for this app in iPhone Settings. Enable sounds so prayer times and reminders can be heard.",
        .permissionBannerDisabledMessage: "Notification banners are limited for this app in iPhone Settings. Turn banners back on so reminders are easier to notice.",
        .permissionSoundAndBannerDisabledMessage: "Notification sounds and banners are limited for this app in iPhone Settings. Re-enable both so reminders arrive normally.",
        .testNotification: "Send test notification",
        .rebuildNotifications: "Rebuild schedule",
        .clearNotifications: "Clear all notifications",
        .printPending: "Print pending requests",
        .premiumRequired: "Premium required",
        .premiumDescription: "Smart reminders, sleep reminders, and Friday/special day plans are part of Premium.",
        .prayerAtTime: "At prayer time",
        .prayer15Before: "15 min before",
        .prayer30Before: "30 min before",
        .prayerBoth: "15 min before and at time",
        .morningReminder: "Morning reminder",
        .eveningReminder: "Evening reminder",
        .sleepReminder: "Sleep reminder",
        .dailyDua: "Daily dua reminder",
        .smartIntensity: "Reminder intensity",
        .fridayReminder: "Friday reminder",
        .specialDays: "Special Islamic days",
        .vibrationOnly: "Vibration only",
        .soundOption: "Sound option",
        .quietHoursEnabled: "Quiet hours",
        .quietHoursStart: "Starts",
        .quietHoursEnd: "Ends",
        .freePlan: "Free",
        .premiumPlan: "Premium",
        .permissionFootnote: "Prayer reminders stay highest priority. Calm reminders follow your quiet hours.",
        .summaryPrayer: "Prayer reminders",
        .summaryMorning: "Morning",
        .summaryEvening: "Evening",
        .summarySleep: "Sleep",
        .summarySmart: "Smart reminders",
        .summaryFriday: "Friday",
        .summaryQuietHours: "Quiet hours",
        .summaryOff: "Off",
        .summarySeparator: " • ",
        .summaryTimeFormat: "%@ %@",
        .summaryPremiumNote: "Premium unlocks a richer reminder plan.",
        .intensityLight: "Light",
        .intensityBalanced: "Balanced",
        .intensityFrequent: "Frequent",
        .soundSystem: "System",
        .soundNur: "Nur",
        .soundSafa: "Safa",
        .soundMerve: "Marwa",
        .soundHuzur: "Huzur",
        .soundPrayerFixedNote: "Prayer-time notifications always play the adhan.",
        .soundPreview: "Preview sound",
        .soundStopPreview: "Stop preview",
        .perPrayerTitle: "Per prayer",
        .notificationsDisabledMessage: "Allow notifications to activate your plan.",
        .testSent: "Test notification scheduled.",
        .rebuildCompleted: "Notification plan refreshed.",
        .debugOnlyCaption: "Visible only in debug builds.",
        .softAskTitle: "Stay gently informed",
        .softAskBody: "Enable notifications for prayer times and a calm spiritual rhythm through the day.",
        .softAskPrimary: "Continue",
        .softAskSecondary: "Not now"
    ]

    private static let packs: [AppLanguage: NotificationLanguagePack] = [
        .en: NotificationLanguagePack(
            ui: sharedUI,
            prayerNames: [
                .fajr: "Fajr",
                .dhuhr: "Dhuhr",
                .asr: "Asr",
                .maghrib: "Maghrib",
                .isha: "Isha"
            ],
            content: [
                .dailyDua: [
                    .init(id: "en_daily_1", title: "A quiet dua moment", body: "Take a brief pause and return to a dua that softens the heart."),
                    .init(id: "en_daily_2", title: "A gentle dua reminder", body: "A short dua can bring calm back into the day.")
                ],
                .morningDua: [
                    .init(id: "en_morning_1", title: "A peaceful morning start", body: "Begin the day with a short remembrance and a clear intention."),
                    .init(id: "en_morning_2", title: "Morning calm", body: "A few quiet moments of dhikr can set the tone for the day.")
                ],
                .eveningReminder: [
                    .init(id: "en_evening_1", title: "A calm evening pause", body: "The evening is a good time for a short remembrance."),
                    .init(id: "en_evening_2", title: "Ease into the evening", body: "Take one peaceful minute for dhikr before the night deepens.")
                ],
                .sleepReminder: [
                    .init(id: "en_sleep_1", title: "A restful close", body: "Before sleep, a short dua can help the day end gently."),
                    .init(id: "en_sleep_2", title: "A quiet night reminder", body: "Close the day with a short remembrance and a calm heart.")
                ],
                .smartDhikrNudge: [
                    .init(id: "en_smart_1", title: "A gentle nudge", body: "If it fits this moment, take a brief pause for dhikr."),
                    .init(id: "en_smart_2", title: "A calm reminder", body: "One small moment of remembrance can soften a busy day."),
                    .init(id: "en_smart_3", title: "A thoughtful pause", body: "A short return to dhikr can quietly reset the day.")
                ],
                .fridayBlessing: [
                    .init(id: "en_friday_1", title: "Friday reminder", body: "Set aside a calm moment today for Friday reflection and prayer."),
                    .init(id: "en_friday_2", title: "A gentle Friday note", body: "Take a quiet pause for salawat, dua, and reflection today.")
                ],
                .specialDayReminder: [
                    .init(id: "en_special_1", title: "A special day is here", body: "Today carries a special meaning. A quiet dua may be enough."),
                    .init(id: "en_special_2", title: "A meaningful day", body: "Take a gentle pause for dua and remembrance today.")
                ],
                .streakComebackReminder: [
                    .init(id: "en_streak_1", title: "Return gently", body: "You can come back with one small remembrance."),
                    .init(id: "en_streak_2", title: "A quiet restart", body: "There is still room in the day for one calm moment of dhikr.")
                ]
            ]
        ),
        .tr: NotificationLanguagePack(
            ui: sharedUI.merging([
                .settingsTitle: "Bildirim Ayarları",
                .overviewTitle: "Sakin bildirim planın",
                .overviewSubtitle: "Saygılı, faydalı ve güven veren bir deneyim için tasarlandı.",
                .prayerSectionTitle: "Namaz bildirimleri",
                .prayerSectionSubtitle: "Hangi namazlar için ve ne zaman hatırlatma alacağını seç.",
                .dailyRemindersTitle: "Günlük manevi hatırlatmalar",
                .dailyRemindersSubtitle: "Dua, sabah, akşam ve dinlenme için zarif hatırlatmalar.",
                .smartRemindersTitle: "Akıllı hatırlatmalar",
                .smartRemindersSubtitle: "Yakın aralıklı olmayan, ölçülü ve kural tabanlı hatırlatmalar.",
                .fridaySectionTitle: "Cuma ve özel günler",
                .fridaySectionSubtitle: "Haftalık ve dönemsel hatırlatmalar sakin bir tonda sunulur.",
                .soundSectionTitle: "Ses ve titreşim",
                .soundSectionSubtitle: "Sessiz ve saygılı bir uyarı stili seç.",
                .quietHoursTitle: "Sessiz saatler",
                .quietHoursSubtitle: "Namaz dışı hatırlatmalar bu saatlerde duraklar.",
                .debugToolsTitle: "Geliştirici araçları",
                .permissionAllowed: "Bildirim izni açık",
                .permissionDenied: "Bildirim izni kapalı",
                .permissionNotDetermined: "İzin henüz istenmedi",
                .permissionProvisional: "Sessiz teslim",
                .permissionActionAllow: "Bildirimleri aç",
                .permissionActionEnableFullAlerts: "Tam Bildirimi Aç",
                .permissionActionOpenSettings: "Ayarları Aç",
                .permissionQuietDeliveryMessage: "iPhone şu anda bu uygulamanın bildirimlerini sessiz teslim ediyor. Ses ve banner ayarlarını açmak için Ayarlar'ı kullan.",
                .permissionProvisionalMessage: "Bildirimler şu anda sessiz teslim modunda. Namaz ve hatırlatma bildirimlerinin sesle gelmesi için tam bildirimi açın.",
                .permissionSoundDisabledMessage: "Bu uygulama için bildirim sesi iPhone Ayarları'nda kapalı görünüyor. Namaz ve hatırlatma sesleri için sesi açın.",
                .permissionBannerDisabledMessage: "Bu uygulama için banner bildirimi iPhone Ayarları'nda kısıtlı görünüyor. Hatırlatmaları daha görünür yapmak için banner'ı açın.",
                .permissionSoundAndBannerDisabledMessage: "Bu uygulama için bildirim sesi ve banner iPhone Ayarları'nda kısıtlı görünüyor. Bildirimlerin normal gelmesi için ikisini de açın.",
                .testNotification: "Test bildirimi gönder",
                .rebuildNotifications: "Planı yeniden kur",
                .clearNotifications: "Tüm bildirimleri temizle",
                .printPending: "Bekleyenleri yazdır",
                .premiumRequired: "Premium gerekli",
                .premiumDescription: "Akıllı hatırlatmalar, uyku hatırlatmaları ve Cuma/özel gün planları Premium'a dahildir.",
                .prayerAtTime: "Vaktinde",
                .prayer15Before: "15 dk önce",
                .prayer30Before: "30 dk önce",
                .prayerBoth: "15 dk önce ve vaktinde",
                .morningReminder: "Sabah hatırlatması",
                .eveningReminder: "Akşam hatırlatması",
                .sleepReminder: "Uyku hatırlatması",
                .dailyDua: "Günlük dua hatırlatması",
                .smartIntensity: "Hatırlatma yoğunluğu",
                .fridayReminder: "Cuma hatırlatması",
                .specialDays: "Özel İslami günler",
                .vibrationOnly: "Yalnız titreşim",
                .soundOption: "Bildirim sesi",
                .quietHoursEnabled: "Sessiz saatler",
                .quietHoursStart: "Başlangıç",
                .quietHoursEnd: "Bitiş",
                .freePlan: "Ücretsiz",
                .premiumPlan: "Premium",
                .permissionFootnote: "Namaz bildirimleri en yüksek önceliktedir. Sakin hatırlatmalar sessiz saatlere uyar.",
                .summaryPrayer: "Namaz",
                .summaryMorning: "Sabah",
                .summaryEvening: "Akşam",
                .summarySleep: "Uyku",
                .summarySmart: "Akıllı",
                .summaryFriday: "Cuma",
                .summaryQuietHours: "Sessiz saatler",
                .summaryOff: "Kapalı",
                .summaryPremiumNote: "Premium daha zengin bir bildirim planı açar.",
                .intensityLight: "Hafif",
                .intensityBalanced: "Dengeli",
                .intensityFrequent: "Sık",
                .soundSystem: "Sistem",
                .soundNur: "Nur",
                .soundSafa: "Safa",
                .soundMerve: "Merve",
                .soundHuzur: "Huzur",
                .soundPrayerFixedNote: "Namaz vakti bildirimlerinde her zaman ezan okunur.",
                .soundPreview: "Sesi dinle",
                .soundStopPreview: "Sesi durdur",
                .perPrayerTitle: "Namaz bazında",
                .notificationsDisabledMessage: "Planını etkinleştirmek için bildirim izni ver.",
                .testSent: "Test bildirimi planlandı.",
                .rebuildCompleted: "Bildirim planı yenilendi.",
                .debugOnlyCaption: "Yalnızca debug derlemelerinde görünür.",
                .softAskTitle: "Sakin bir ritimde haberdar ol",
                .softAskBody: "Namaz vakitleri ve gün içindeki manevi ritim için bildirimleri etkinleştir.",
                .softAskPrimary: "Devam et",
                .softAskSecondary: "Şimdi değil"
            ]) { _, new in new },
            prayerNames: [
                .fajr: "İmsak",
                .dhuhr: "Öğle",
                .asr: "İkindi",
                .maghrib: "Akşam",
                .isha: "Yatsı"
            ],
            content: [
                .dailyDua: [
                    .init(id: "tr_daily_1", title: "Kısa bir dua molası", body: "Kalbi yumuşatan kısa bir dua için küçük bir ara ver."),
                    .init(id: "tr_daily_2", title: "Günün duası için nazik bir hatırlatma", body: "Kısa bir dua günün akışına huzur katabilir.")
                ],
                .morningDua: [
                    .init(id: "tr_morning_1", title: "Sabaha sakin bir başlangıç", body: "Güne kısa bir zikir ve temiz bir niyetle başla."),
                    .init(id: "tr_morning_2", title: "Sabahın huzuru", body: "Birkaç dakikalık zikir günün tonunu güzelleştirebilir.")
                ],
                .eveningReminder: [
                    .init(id: "tr_evening_1", title: "Akşam için kısa bir durak", body: "Akşam saatleri kısa bir zikir için güzel bir fırsattır."),
                    .init(id: "tr_evening_2", title: "Akşama yumuşak bir geçiş", body: "Gece ilerlemeden önce bir dakikalık zikir iyi gelebilir.")
                ],
                .sleepReminder: [
                    .init(id: "tr_sleep_1", title: "Günü huzurla kapat", body: "Uyumadan önce kısa bir dua günü yumuşakça tamamlayabilir."),
                    .init(id: "tr_sleep_2", title: "Gece için sakin bir hatırlatma", body: "Günü kısa bir zikirle kapatmak kalbi sakinleştirebilir.")
                ],
                .smartDhikrNudge: [
                    .init(id: "tr_smart_1", title: "Nazik bir hatırlatma", body: "Eğer uygunsa, kısa bir zikir için küçük bir ara ver."),
                    .init(id: "tr_smart_2", title: "Sakin bir durak", body: "Yoğun bir gün içinde kısa bir zikir iyi gelebilir."),
                    .init(id: "tr_smart_3", title: "İnce bir davet", body: "Kısa bir tefekkür ve zikir günü yumuşatabilir.")
                ],
                .fridayBlessing: [
                    .init(id: "tr_friday_1", title: "Cuma hatırlatması", body: "Bugün salavat, dua ve tefekkür için kısa bir vakit ayır."),
                    .init(id: "tr_friday_2", title: "Cuma için nazik bir not", body: "Bugün kısa bir dua, salavat ve tefekkür kalbe iyi gelebilir.")
                ],
                .specialDayReminder: [
                    .init(id: "tr_special_1", title: "Özel bir gün", body: "Bugün anlamlı bir gün. Kısa bir dua bile yeterli olabilir."),
                    .init(id: "tr_special_2", title: "Manalı bir hatırlatma", body: "Bugünü dua, zikir ve güzel bir niyetle karşılamak güzel olabilir.")
                ],
                .streakComebackReminder: [
                    .init(id: "tr_streak_1", title: "Sakin bir dönüş", body: "Bir küçük zikirle yeniden başlayabilirsin."),
                    .init(id: "tr_streak_2", title: "Kısa bir yeniden başlangıç", body: "Bugünde hâlâ kısa bir zikir için yer var.")
                ]
            ]
        ),
        .ar: NotificationLanguagePack(ui: sharedUI, prayerNames: [.fajr: "الفجر", .dhuhr: "الظهر", .asr: "العصر", .maghrib: "المغرب", .isha: "العشاء"], content: [.dailyDua: [.init(id: "ar_daily_1", title: "لحظة دعاء هادئة", body: "خذ وقفة قصيرة وعد إلى دعاء يلين القلب.")], .morningDua: [.init(id: "ar_morning_1", title: "بداية صباح هادئة", body: "ابدأ يومك بذكر قصير ونية صافية.")], .eveningReminder: [.init(id: "ar_evening_1", title: "وقفة مسائية لطيفة", body: "المساء وقت مناسب لذكر قصير يهدئ القلب.")], .sleepReminder: [.init(id: "ar_sleep_1", title: "ختام مريح", body: "قبل النوم، دعاء قصير قد يمنح ليلتك سكينة.")], .smartDhikrNudge: [.init(id: "ar_smart_1", title: "تذكير لطيف", body: "إن كان الوقت مناسباً، خذ لحظة قصيرة للذكر."), .init(id: "ar_smart_2", title: "وقفة هادئة", body: "لحظة ذكر واحدة قد تلطف زحمة اليوم.")], .fridayBlessing: [.init(id: "ar_friday_1", title: "تذكير الجمعة", body: "خصص اليوم لحظة هادئة للصلاة على النبي والدعاء.")], .specialDayReminder: [.init(id: "ar_special_1", title: "يوم مميز", body: "لهذا اليوم معنى خاص. يكفيه دعاء هادئ." )], .streakComebackReminder: [.init(id: "ar_streak_1", title: "عودة هادئة", body: "يمكنك العودة بذكر صغير ولطيف.")]]),
        .fr: NotificationLanguagePack(ui: sharedUI, prayerNames: [.fajr: "Fajr", .dhuhr: "Dhuhr", .asr: "Asr", .maghrib: "Maghrib", .isha: "Isha"], content: [.dailyDua: [.init(id: "fr_daily_1", title: "Un moment de doua", body: "Une courte pause pour une doua peut apaiser le coeur.")], .morningDua: [.init(id: "fr_morning_1", title: "Un matin paisible", body: "Commencez la journée avec un rappel bref et une intention claire.")], .eveningReminder: [.init(id: "fr_evening_1", title: "Une pause du soir", body: "Le soir est un bon moment pour un court dhikr.")], .sleepReminder: [.init(id: "fr_sleep_1", title: "Une fin de journée douce", body: "Avant le sommeil, une courte doua peut fermer la journée avec calme.")], .smartDhikrNudge: [.init(id: "fr_smart_1", title: "Un rappel doux", body: "Si le moment s'y prête, accordez-vous une courte pause de dhikr.")], .fridayBlessing: [.init(id: "fr_friday_1", title: "Rappel du vendredi", body: "Prenez aujourd'hui un moment calme pour l'invocation et la réflexion.")], .specialDayReminder: [.init(id: "fr_special_1", title: "Un jour particulier", body: "Aujourd'hui a une valeur particulière. Une doua discrète suffit.")], .streakComebackReminder: [.init(id: "fr_streak_1", title: "Revenir en douceur", body: "Vous pouvez revenir avec un seul petit dhikr.")]]),
        .de: NotificationLanguagePack(ui: sharedUI, prayerNames: [.fajr: "Fajr", .dhuhr: "Dhuhr", .asr: "Asr", .maghrib: "Maghrib", .isha: "Isha"], content: [.dailyDua: [.init(id: "de_daily_1", title: "Ein ruhiger Dua-Moment", body: "Eine kurze Pause fuer Dua kann den Tag sanft ordnen.")], .morningDua: [.init(id: "de_morning_1", title: "Ein friedlicher Morgen", body: "Beginne den Tag mit kurzem Dhikr und klarer Absicht.")], .eveningReminder: [.init(id: "de_evening_1", title: "Eine ruhige Abendpause", body: "Der Abend ist eine gute Zeit fuer einen kurzen Dhikr.")], .sleepReminder: [.init(id: "de_sleep_1", title: "Ein sanfter Tagesabschluss", body: "Vor dem Schlafen kann ein kurzes Dua den Tag ruhig schliessen.")], .smartDhikrNudge: [.init(id: "de_smart_1", title: "Ein sanfter Impuls", body: "Wenn es passt, nimm dir kurz Zeit fuer Dhikr.")], .fridayBlessing: [.init(id: "de_friday_1", title: "Freitags-Erinnerung", body: "Nimm dir heute einen ruhigen Moment fuer Salawat und Dua.")], .specialDayReminder: [.init(id: "de_special_1", title: "Ein besonderer Tag", body: "Dieser Tag hat eine besondere Bedeutung. Ein stilles Dua genuegt.")], .streakComebackReminder: [.init(id: "de_streak_1", title: "Sanft zurueckkehren", body: "Du kannst mit einem kleinen Dhikr wieder anknuepfen.")]]),
        .id: NotificationLanguagePack(ui: sharedUI, prayerNames: [.fajr: "Subuh", .dhuhr: "Dzuhur", .asr: "Ashar", .maghrib: "Maghrib", .isha: "Isya"], content: [.dailyDua: [.init(id: "id_daily_1", title: "Saat hening untuk doa", body: "Luangkan jeda singkat untuk doa yang menenangkan hati.")], .morningDua: [.init(id: "id_morning_1", title: "Awal pagi yang tenang", body: "Mulailah hari dengan dzikir singkat dan niat yang jernih.")], .eveningReminder: [.init(id: "id_evening_1", title: "Jeda sore yang lembut", body: "Sore hari cocok untuk dzikir singkat yang menenangkan.")], .sleepReminder: [.init(id: "id_sleep_1", title: "Penutup hari yang damai", body: "Sebelum tidur, doa singkat dapat menutup hari dengan lembut.")], .smartDhikrNudge: [.init(id: "id_smart_1", title: "Pengingat lembut", body: "Jika waktunya pas, ambil sebentar untuk berdzikir.")], .fridayBlessing: [.init(id: "id_friday_1", title: "Pengingat Jumat", body: "Sisihkan waktu tenang hari ini untuk salawat dan doa.")], .specialDayReminder: [.init(id: "id_special_1", title: "Hari yang istimewa", body: "Hari ini bermakna khusus. Doa singkat sudah cukup.")], .streakComebackReminder: [.init(id: "id_streak_1", title: "Kembali dengan lembut", body: "Kamu bisa kembali dengan satu dzikir kecil.")]]),
        .ms: NotificationLanguagePack(ui: sharedUI, prayerNames: [.fajr: "Subuh", .dhuhr: "Zohor", .asr: "Asar", .maghrib: "Maghrib", .isha: "Isyak"], content: [.dailyDua: [.init(id: "ms_daily_1", title: "Saat doa yang tenang", body: "Luangkan seketika untuk doa yang menenangkan hati.")], .morningDua: [.init(id: "ms_morning_1", title: "Permulaan pagi yang damai", body: "Mulakan hari dengan zikir ringkas dan niat yang bersih.")], .eveningReminder: [.init(id: "ms_evening_1", title: "Jeda petang yang lembut", body: "Petang sesuai untuk zikir ringkas yang menenangkan.")], .sleepReminder: [.init(id: "ms_sleep_1", title: "Penutup hari yang lembut", body: "Sebelum tidur, doa ringkas boleh menutup hari dengan tenang.")], .smartDhikrNudge: [.init(id: "ms_smart_1", title: "Peringatan lembut", body: "Jika sesuai, ambil seketika untuk berzikir.")], .fridayBlessing: [.init(id: "ms_friday_1", title: "Peringatan Jumaat", body: "Sisihkan masa yang tenang hari ini untuk selawat dan doa.")], .specialDayReminder: [.init(id: "ms_special_1", title: "Hari yang istimewa", body: "Hari ini mempunyai makna khas. Doa ringkas sudah memadai.")], .streakComebackReminder: [.init(id: "ms_streak_1", title: "Kembali dengan tenang", body: "Anda boleh kembali dengan satu zikir kecil.")]]),
        .fa: NotificationLanguagePack(ui: sharedUI, prayerNames: [.fajr: "فجر", .dhuhr: "ظهر", .asr: "عصر", .maghrib: "مغرب", .isha: "عشا"], content: [.dailyDua: [.init(id: "fa_daily_1", title: "لحظه ای آرام برای دعا", body: "یک مکث کوتاه برای دعا می تواند دل را آرام کند.")], .morningDua: [.init(id: "fa_morning_1", title: "آغاز آرام صبح", body: "روز را با ذکری کوتاه و نیتی روشن آغاز کن.")], .eveningReminder: [.init(id: "fa_evening_1", title: "درنگی آرام در عصر", body: "عصر زمان خوبی برای یک ذکر کوتاه است.")], .sleepReminder: [.init(id: "fa_sleep_1", title: "پایان آرام روز", body: "پیش از خواب، دعایی کوتاه می تواند روز را آرام ببندد.")], .smartDhikrNudge: [.init(id: "fa_smart_1", title: "یادآوری لطیف", body: "اگر مناسب است، لحظه ای کوتاه برای ذکر بردار.")], .fridayBlessing: [.init(id: "fa_friday_1", title: "یادآوری جمعه", body: "امروز زمانی آرام برای صلوات و دعا کنار بگذار.")], .specialDayReminder: [.init(id: "fa_special_1", title: "روزی ویژه", body: "امروز معنای خاصی دارد. یک دعای آرام کافی است.")], .streakComebackReminder: [.init(id: "fa_streak_1", title: "بازگشتی آرام", body: "می توانی با یک ذکر کوچک دوباره برگردی.")]]),
        .ru: NotificationLanguagePack(ui: sharedUI, prayerNames: [.fajr: "Фаджр", .dhuhr: "Зухр", .asr: "Аср", .maghrib: "Магриб", .isha: "Иша"], content: [.dailyDua: [.init(id: "ru_daily_1", title: "Тихий момент для дуа", body: "Короткая пауза для дуа может мягко успокоить сердце.")], .morningDua: [.init(id: "ru_morning_1", title: "Спокойное утро", body: "Начните день с короткого зикра и ясного намерения.")], .eveningReminder: [.init(id: "ru_evening_1", title: "Спокойная вечерняя пауза", body: "Вечер подходит для короткого зикра.")], .sleepReminder: [.init(id: "ru_sleep_1", title: "Мягкое завершение дня", body: "Перед сном короткая дуа может завершить день спокойно.")], .smartDhikrNudge: [.init(id: "ru_smart_1", title: "Мягкое напоминание", body: "Если момент подходит, сделайте короткую паузу для зикра.")], .fridayBlessing: [.init(id: "ru_friday_1", title: "Напоминание о пятнице", body: "Найдите сегодня тихий момент для салавата и дуа.")], .specialDayReminder: [.init(id: "ru_special_1", title: "Особый день", body: "Сегодня особенный день. Небольшой тихой дуа достаточно.")], .streakComebackReminder: [.init(id: "ru_streak_1", title: "Вернуться мягко", body: "Можно вернуться с одним небольшим зикром.")]]),
        .es: NotificationLanguagePack(ui: sharedUI, prayerNames: [.fajr: "Fajr", .dhuhr: "Dhuhr", .asr: "Asr", .maghrib: "Maghrib", .isha: "Isha"], content: [.dailyDua: [.init(id: "es_daily_1", title: "Un momento de dua", body: "Una breve pausa para la dua puede traer calma al dia.")], .morningDua: [.init(id: "es_morning_1", title: "Una manana serena", body: "Empieza el dia con un dhikr breve y una intencion clara.")], .eveningReminder: [.init(id: "es_evening_1", title: "Una pausa al atardecer", body: "La tarde es un buen momento para un dhikr corto.")], .sleepReminder: [.init(id: "es_sleep_1", title: "Un cierre tranquilo", body: "Antes de dormir, una dua breve puede cerrar el dia con suavidad.")], .smartDhikrNudge: [.init(id: "es_smart_1", title: "Un recordatorio suave", body: "Si el momento acompana, toma una breve pausa para el dhikr.")], .fridayBlessing: [.init(id: "es_friday_1", title: "Recordatorio del viernes", body: "Reserva hoy un momento sereno para salawat y dua.")], .specialDayReminder: [.init(id: "es_special_1", title: "Un dia especial", body: "Hoy tiene un significado especial. Una dua tranquila puede ser suficiente.")], .streakComebackReminder: [.init(id: "es_streak_1", title: "Volver con calma", body: "Puedes volver con un pequeno dhikr.")]]),
        .ur: NotificationLanguagePack(ui: sharedUI, prayerNames: [.fajr: "فجر", .dhuhr: "ظہر", .asr: "عصر", .maghrib: "مغرب", .isha: "عشاء"], content: [.dailyDua: [.init(id: "ur_daily_1", title: "دعا کے لئے ایک پُرسکون لمحہ", body: "مختصر دعا دل کو نرمی دے سکتی ہے۔")], .morningDua: [.init(id: "ur_morning_1", title: "پرسکون صبح", body: "دن کا آغاز مختصر ذکر اور صاف نیت سے کریں۔")], .eveningReminder: [.init(id: "ur_evening_1", title: "شام کی نرم یاددہانی", body: "شام مختصر ذکر کے لئے اچھا وقت ہے۔")], .sleepReminder: [.init(id: "ur_sleep_1", title: "دن کا پُرسکون اختتام", body: "سونے سے پہلے مختصر دعا دن کو نرمی سے مکمل کر سکتی ہے۔")], .smartDhikrNudge: [.init(id: "ur_smart_1", title: "نرم یاددہانی", body: "اگر مناسب ہو تو ذکر کے لئے ایک مختصر وقفہ لیں۔")], .fridayBlessing: [.init(id: "ur_friday_1", title: "جمعہ کی یاددہانی", body: "آج درود اور دعا کے لئے ایک پرسکون لمحہ نکالیں۔")], .specialDayReminder: [.init(id: "ur_special_1", title: "ایک خاص دن", body: "آج خاص معنی رکھتا ہے۔ مختصر دعا بھی کافی ہو سکتی ہے۔")], .streakComebackReminder: [.init(id: "ur_streak_1", title: "نرمی سے واپسی", body: "آپ ایک چھوٹے ذکر سے دوبارہ آغاز کر سکتے ہیں۔")]])
    ]
}
