import Foundation
import UserNotifications

struct AppNotificationContent: Sendable {
    let contentID: String
    let category: NotificationContentCategory
    let title: String
    let subtitle: String?
    let body: String
    let route: NotificationRoute
    let sound: UNNotificationSound?
    let interruptionLevel: UNNotificationInterruptionLevel
    let relevanceScore: Double?
}

struct NotificationContentContext: Sendable {
    var settings: NotificationSettings
    var scheduledDate: Date
    var requestKey: String
    var prayer: PrayerName?
    var offsetMinutes: Int?
    var specialDayTitle: String?
}

struct NotificationContentFactory {
    private struct GuidedDuaEntry {
        let id: String
        let title: String
        let arabic: String
        let meaning: String
    }

    private let historyStore: NotificationContentHistoryStore

    init(historyStore: NotificationContentHistoryStore = NotificationContentHistoryStore()) {
        self.historyStore = historyStore
    }

    func makeContent(
        category: NotificationContentCategory,
        context: NotificationContentContext
    ) -> AppNotificationContent {
        switch category {
        case .prayerReminder, .prayerTimeNow:
            return makePrayerContent(category: category, context: context)
        case .dailyAyah:
            return makeDailyAyahContent(context: context)
        case .dailyDua, .morningDua, .eveningReminder, .sleepReminder, .smartDhikrNudge, .streakComebackReminder:
            return makeGuidedDuaContent(category: category, context: context)
        case .fridayBlessing, .specialDayReminder:
            return makePooledContent(category: category, context: context)
        }
    }

    func makeUNContent(from content: AppNotificationContent) -> UNMutableNotificationContent {
        let mutable = UNMutableNotificationContent()
        mutable.title = content.title
        mutable.subtitle = content.subtitle ?? ""
        mutable.body = content.body
        mutable.userInfo = content.route.userInfo
        mutable.sound = content.sound
        if #available(iOS 15.0, *) {
            mutable.interruptionLevel = content.interruptionLevel
            if let relevanceScore = content.relevanceScore {
                mutable.relevanceScore = relevanceScore
            }
        }
        return mutable
    }

    private func makePrayerContent(
        category: NotificationContentCategory,
        context: NotificationContentContext
    ) -> AppNotificationContent {
        let prayer = context.prayer ?? .fajr
        let languageCode = context.settings.currentLanguageCode
        let language = AppLanguage(code: languageCode)
        let prayerName = NotificationLocalization.prayerName(prayer, languageCode: languageCode)
        let selectedPrayerText = selectedPrayerText(
            for: prayer,
            category: category,
            language: language,
            requestKey: context.requestKey
        )

        let title = prayerNotificationTitle(
            prayerName: prayerName,
            scheduledDate: context.scheduledDate,
            settings: context.settings,
            language: language
        )
        let body: String
        let contentID = selectedPrayerText.map { "\(category.rawValue)_\($0.id)" }
            ?? "\(category.rawValue)_\(prayer.rawValue)_\(context.offsetMinutes ?? 0)"

        if category == .prayerReminder, let offsetMinutes = context.offsetMinutes, offsetMinutes > 0 {
            if let localizedBody = PrayerNotificationTextCatalog.localizedBody(
                prayerName: prayerName,
                language: language,
                offsetMinutes: offsetMinutes,
                spiritualText: selectedPrayerText?.text
            ) {
                body = localizedBody
            } else {
                switch language {
                case .tr:
                    body = "\(offsetMinutes) dakika sonra \(prayerName) vakti girecek. Hazirligini sakince yapip namaza niyet edebilirsin."
                case .ar:
                    body = "يتبقى \(offsetMinutes) دقيقة على \(prayerName). يمكنك الاستعداد بهدوء."
                case .fr:
                    body = "Il reste \(offsetMinutes) min avant \(prayerName). Vous pouvez vous preparer avec calme."
                case .de:
                    body = "Noch \(offsetMinutes) Min bis \(prayerName). Du kannst dich in Ruhe vorbereiten."
                case .id:
                    body = "\(offsetMinutes) menit lagi menuju \(prayerName). Kamu bisa bersiap dengan tenang."
                case .ms:
                    body = "Tinggal \(offsetMinutes) minit lagi sebelum \(prayerName). Bersedialah dengan tenang."
                case .fa:
                    body = "\(offsetMinutes) دقیقه تا \(prayerName) باقی مانده است. می توانی با آرامش آماده شوی."
                case .ru:
                    body = "До \(prayerName) осталось \(offsetMinutes) мин. Можно спокойно подготовиться."
                case .es:
                    body = "Faltan \(offsetMinutes) min para \(prayerName). Puedes prepararte con calma."
                case .ur:
                    body = "\(prayerName) میں \(offsetMinutes) منٹ باقی ہیں۔ آپ سکون کے ساتھ تیاری کر سکتے ہیں۔"
                case .en:
                    body = "\(offsetMinutes) min left until \(prayerName). You can get ready with calm and intention."
                }
            }
        } else {
            if let localizedBody = PrayerNotificationTextCatalog.localizedBody(
                prayerName: prayerName,
                language: language,
                offsetMinutes: nil,
                spiritualText: selectedPrayerText?.text
            ) {
                body = localizedBody
            } else {
                switch language {
                case .tr:
                    body = "\(prayerName) vakti girdi. Huzurlu bir baslangic icin simdi namaza yonelebilirsin."
                case .ar:
                    body = "حان وقت \(prayerName). يمكنك التوجه إلى الصلاة الآن بهدوء."
                case .fr:
                    body = "C'est l'heure de \(prayerName). Vous pouvez maintenant revenir a la priere avec calme."
                case .de:
                    body = "Es ist Zeit fuer \(prayerName). Du kannst dich jetzt in Ruhe dem Gebet zuwenden."
                case .id:
                    body = "Waktu \(prayerName) telah masuk. Saatnya kembali berdoa dengan tenang."
                case .ms:
                    body = "Waktu \(prayerName) telah masuk. Kini masa untuk kembali kepada solat dengan tenang."
                case .fa:
                    body = "وقت \(prayerName) فرا رسيد. اکنون می توانی با آرامش به نماز برگردی."
                case .ru:
                    body = "Наступило время \(prayerName). Сейчас можно спокойно вернуться к молитве."
                case .es:
                    body = "Es la hora de \(prayerName). Puedes volver a la oracion con calma."
                case .ur:
                    body = "\(prayerName) کا وقت ہو گیا ہے۔ اب آپ سکون کے ساتھ نماز کی طرف لوٹ سکتے ہیں۔"
                case .en:
                    body = "It is time for \(prayerName). You can turn to prayer now with calm and intention."
                }
            }
        }

        return AppNotificationContent(
            contentID: contentID,
            category: category,
            title: title,
            subtitle: nil,
            body: body,
            route: .prayerDetail(prayer),
            sound: resolveSound(settings: context.settings, isPrayer: true),
            interruptionLevel: .timeSensitive,
            relevanceScore: 1
        )
    }

    private func selectedPrayerText(
        for prayer: PrayerName,
        category: NotificationContentCategory,
        language: AppLanguage,
        requestKey: String
    ) -> PrayerNotificationTextVariant? {
        let variants = PrayerNotificationTextCatalog.variants(for: prayer, language: language).map {
            NotificationContentVariant(id: $0.id, title: "", body: $0.text)
        }

        guard !variants.isEmpty else { return nil }

        let scopedRequestKey = "\(prayer.rawValue)|\(requestKey)"
        let selected = selectVariant(
            variants,
            category: category,
            requestKey: scopedRequestKey
        )
        historyStore.saveContentID(selected.id, for: "\(category.rawValue)|\(scopedRequestKey)")
        return PrayerNotificationTextVariant(id: selected.id, text: selected.body)
    }

    private func makeDailyAyahContent(context: NotificationContentContext) -> AppNotificationContent {
        let language = AppLanguage(code: context.settings.currentLanguageCode)
        let verse = DailyVerseProvider.shared.verseForDate(context.scheduledDate)
        let title = dailyAyahTitle(for: language)
        let body: String
        let contentID: String

        if let verse {
            body = "\(verse.translation) • \(verse.metadataText)"
            contentID = "daily_ayah_\(verse.id)"
        } else {
            body = dailyAyahFallbackBody(for: language)
            contentID = "daily_ayah_fallback"
        }

        return AppNotificationContent(
            contentID: contentID,
            category: .dailyAyah,
            title: title,
            subtitle: nil,
            body: body,
            route: .dailyAyah,
            sound: resolveSound(settings: context.settings, isPrayer: false),
            interruptionLevel: .active,
            relevanceScore: nil
        )
    }

    private func makeGuidedDuaContent(
        category: NotificationContentCategory,
        context: NotificationContentContext
    ) -> AppNotificationContent {
        let language = AppLanguage(code: context.settings.currentLanguageCode)
        let dua = guidedDuaEntry(for: category, language: language)
        let body = "\(dua.arabic) • \(dua.meaning)"

        return AppNotificationContent(
            contentID: dua.id,
            category: category,
            title: dua.title,
            subtitle: nil,
            body: body,
            route: .guideHome,
            sound: resolveSound(settings: context.settings, isPrayer: false),
            interruptionLevel: .active,
            relevanceScore: nil
        )
    }

    private func makePooledContent(
        category: NotificationContentCategory,
        context: NotificationContentContext
    ) -> AppNotificationContent {
        let variants = NotificationLocalization.variants(for: category, languageCode: context.settings.currentLanguageCode)
        let selected = selectVariant(
            variants,
            category: category,
            requestKey: context.requestKey
        )

        let route: NotificationRoute
        switch category {
        case .dailyAyah:
            route = .dailyAyah
        case .dailyDua, .morningDua, .eveningReminder, .sleepReminder, .smartDhikrNudge, .streakComebackReminder:
            route = .guideHome
        case .fridayBlessing:
            route = .fridayContent
        case .specialDayReminder:
            route = .specialDay(id: context.requestKey, title: context.specialDayTitle)
        case .prayerReminder, .prayerTimeNow:
            route = .notificationsSettings
        }

        let title = context.specialDayTitle.map { "\(selected.title): \($0)" } ?? selected.title

        historyStore.saveContentID(selected.id, for: "\(category.rawValue)|\(context.requestKey)")

        return AppNotificationContent(
            contentID: selected.id,
            category: category,
            title: title,
            subtitle: nil,
            body: selected.body,
            route: route,
            sound: resolveSound(settings: context.settings, isPrayer: false),
            interruptionLevel: .active,
            relevanceScore: nil
        )
    }

    private func selectVariant(
        _ variants: [NotificationContentVariant],
        category: NotificationContentCategory,
        requestKey: String
    ) -> NotificationContentVariant {
        guard !variants.isEmpty else {
            return NotificationContentVariant(id: "fallback", title: AppName.short, body: AppName.short)
        }

        let key = "\(category.rawValue)|\(requestKey)"
        if let existingID = historyStore.recordedContentID(for: key),
           let existing = variants.first(where: { $0.id == existingID }) {
            return existing
        }

        let recent = Set(historyStore.recentContentIDs(category: category, excluding: key))
        let seed = abs(key.hashValue)
        let startIndex = seed % variants.count

        for offset in 0..<variants.count {
            let candidate = variants[(startIndex + offset) % variants.count]
            if !recent.contains(candidate.id) {
                return candidate
            }
        }

        return variants[startIndex]
    }

    private func guidedDuaEntry(for category: NotificationContentCategory, language: AppLanguage) -> GuidedDuaEntry {
        let id: String
        let arabic: String

        switch category {
        case .dailyDua:
            id = "dua_daily_rabbana_atina"
            arabic = "ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار"
        case .morningDua:
            id = "dua_morning_asbahna"
            arabic = "اللهم بك اصبحنا وبك امسينا وبك نحيا وبك نموت واليك النشور"
        case .eveningReminder:
            id = "dua_evening_amsayna"
            arabic = "اللهم بك امسينا وبك اصبحنا وبك نحيا وبك نموت واليك المصير"
        case .sleepReminder:
            id = "dua_sleep_bismika"
            arabic = "باسمك اللهم اموت واحيا"
        case .smartDhikrNudge:
            id = "dhikr_hawqala"
            arabic = "لا حول ولا قوة الا بالله"
        case .streakComebackReminder:
            id = "dhikr_istighfar"
            arabic = "استغفر الله واتوب اليه"
        case .prayerReminder, .prayerTimeNow, .fridayBlessing, .specialDayReminder, .dailyAyah:
            id = "dua_daily_rabbana_atina"
            arabic = "ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار"
        }

        return GuidedDuaEntry(
            id: id,
            title: guidedDuaTitle(for: category, language: language),
            arabic: arabic,
            meaning: guidedDuaMeaning(for: category, language: language)
        )
    }

    private func dailyAyahTitle(for language: AppLanguage) -> String {
        switch language {
        case .tr: return "Gunun ayeti"
        case .en: return "Verse of the day"
        case .de: return "Vers des Tages"
        case .ar: return "آية اليوم"
        case .fr: return "Verset du jour"
        case .es: return "Verso del dia"
        case .id, .ms: return "Ayat hari ini"
        case .ur: return "آج کی آیت"
        case .ru: return "Аят дня"
        case .fa: return "آیه روز"
        }
    }

    private func dailyAyahFallbackBody(for language: AppLanguage) -> String {
        switch language {
        case .tr: return "Bugun icin secilen ayeti acmak icin Kur'an bolumune bak."
        case .en: return "Open the Quran section for today's selected verse."
        case .de: return "Oeffne den Quran-Bereich fuer den heutigen Vers."
        case .ar: return "افتح قسم القرآن لقراءة آية اليوم."
        case .fr: return "Ouvrez la section Coran pour le verset du jour."
        case .es: return "Abre la seccion del Coran para ver el verso de hoy."
        case .id: return "Buka bagian Al-Quran untuk ayat hari ini."
        case .ur: return "آج کی آیت دیکھنے کے لئے قرآن حصے کو کھولیں۔"
        case .ms: return "Buka bahagian Al-Quran untuk ayat hari ini."
        case .ru: return "Откройте раздел Корана, чтобы прочитать аят дня."
        case .fa: return "بخش قرآن را برای آیه امروز باز کنید."
        }
    }

    private func guidedDuaTitle(for category: NotificationContentCategory, language: AppLanguage) -> String {
        switch category {
        case .dailyDua:
            switch language {
            case .tr: return "Gunun duasi"
            case .en: return "Today's dua"
            case .de: return "Dua des Tages"
            case .ar: return "دعاء اليوم"
            case .fr: return "Dua du jour"
            case .es: return "Dua del dia"
            case .id: return "Doa hari ini"
            case .ur: return "آج کی دعا"
            case .ms: return "Doa hari ini"
            case .ru: return "Дуа дня"
            case .fa: return "دعای روز"
            }
        case .morningDua:
            switch language {
            case .tr: return "Sabah duasi"
            case .en: return "Morning dua"
            case .de: return "Morgengebet"
            case .ar: return "دعاء الصباح"
            case .fr: return "Dua du matin"
            case .es: return "Dua de la manana"
            case .id: return "Doa pagi"
            case .ur: return "صبح کی دعا"
            case .ms: return "Doa pagi"
            case .ru: return "Утреннее дуа"
            case .fa: return "دعای صبح"
            }
        case .eveningReminder:
            switch language {
            case .tr: return "Aksam duasi"
            case .en: return "Evening dua"
            case .de: return "Abendgebet"
            case .ar: return "دعاء المساء"
            case .fr: return "Dua du soir"
            case .es: return "Dua de la tarde"
            case .id: return "Doa petang"
            case .ur: return "شام کی دعا"
            case .ms: return "Doa petang"
            case .ru: return "Вечернее дуа"
            case .fa: return "دعای عصر"
            }
        case .sleepReminder:
            switch language {
            case .tr: return "Uyku oncesi dua"
            case .en: return "Before sleep"
            case .de: return "Vor dem Schlaf"
            case .ar: return "دعاء قبل النوم"
            case .fr: return "Avant le sommeil"
            case .es: return "Antes de dormir"
            case .id: return "Sebelum tidur"
            case .ur: return "سونے سے پہلے"
            case .ms: return "Sebelum tidur"
            case .ru: return "Перед сном"
            case .fa: return "پیش از خواب"
            }
        case .smartDhikrNudge:
            switch language {
            case .tr: return "Kisa bir zikir"
            case .en: return "A brief dhikr"
            case .de: return "Ein kurzer Dhikr"
            case .ar: return "ذكر قصير"
            case .fr: return "Un bref dhikr"
            case .es: return "Un dhikr breve"
            case .id: return "Dzikir singkat"
            case .ur: return "مختصر ذکر"
            case .ms: return "Zikir ringkas"
            case .ru: return "Короткий зикр"
            case .fa: return "ذکری کوتاه"
            }
        case .streakComebackReminder:
            switch language {
            case .tr: return "Yeniden basla"
            case .en: return "Return gently"
            case .de: return "Kehre sanft zurueck"
            case .ar: return "عد بلطف"
            case .fr: return "Reviens doucement"
            case .es: return "Vuelve con calma"
            case .id: return "Kembali perlahan"
            case .ur: return "نرمی سے واپس آئیں"
            case .ms: return "Kembali dengan lembut"
            case .ru: return "Вернись мягко"
            case .fa: return "آرام برگرد"
            }
        case .prayerReminder, .prayerTimeNow, .fridayBlessing, .specialDayReminder, .dailyAyah:
            return dailyAyahTitle(for: language)
        }
    }

    private func guidedDuaMeaning(for category: NotificationContentCategory, language: AppLanguage) -> String {
        switch category {
        case .dailyDua:
            switch language {
            case .tr: return "Rabbimiz, bize dunyada da iyilik ver, ahirette de iyilik ver ve bizi ates azabindan koru."
            case .en: return "Our Lord, grant us good in this world and good in the Hereafter, and protect us from the punishment of the Fire."
            case .de: return "Unser Herr, gib uns Gutes im Diesseits und im Jenseits und schuetze uns vor dem Feuer."
            case .ar: return "ربنا امنحنا الخير في الدنيا والآخرة وقنا عذاب النار."
            case .fr: return "Notre Seigneur, accorde-nous un bien ici-bas, un bien dans l'au-dela et preserve-nous du Feu."
            case .es: return "Senor nuestro, concedenos bien en esta vida, bien en la otra y protegenos del castigo del Fuego."
            case .id: return "Ya Tuhan kami, berilah kami kebaikan di dunia, kebaikan di akhirat, dan lindungi kami dari azab neraka."
            case .ur: return "اے ہمارے رب، ہمیں دنیا میں بھلائی دے، آخرت میں بھی بھلائی دے اور آگ کے عذاب سے بچا۔"
            case .ms: return "Wahai Tuhan kami, berilah kami kebaikan di dunia, kebaikan di akhirat, dan peliharalah kami daripada azab neraka."
            case .ru: return "Господь наш, даруй нам благо в этом мире, благо в мире вечном и защити нас от наказания Огня."
            case .fa: return "پروردگارا، در دنيا و آخرت به ما نيکی عطا کن و ما را از عذاب آتش حفظ فرما."
            }
        case .morningDua:
            switch language {
            case .tr: return "Allahim, bu sabaha Seninle girdik; bugunu huzurla, imanla ve emniyetle tamamlamayi nasip et."
            case .en: return "O Allah, by You we enter this morning; grant us peace, faith, and safety through this day."
            case .de: return "O Allah, mit Dir erreichen wir den Morgen; schenke uns heute Frieden, Glauben und Sicherheit."
            case .ar: return "اللهم بك دخلنا هذا الصباح، فارزقنا اليوم طمأنينة وإيمانا وأمنا."
            case .fr: return "Allah, c'est par Toi que nous entrons dans ce matin; accorde-nous paix, foi et securite aujourd'hui."
            case .es: return "Allah, por Ti amanecemos; concedenos paz, fe y seguridad durante este dia."
            case .id: return "Ya Allah, dengan-Mu kami memasuki pagi; anugerahkan ketenangan, iman, dan keselamatan hari ini."
            case .ur: return "اے اللہ، تیرے ہی سہارے ہم نے صبح پائی؛ آج کے دن ہمیں سکون، ایمان اور حفاظت عطا فرما۔"
            case .ms: return "Ya Allah, dengan-Mu kami memasuki pagi; kurniakan ketenangan, iman, dan keselamatan pada hari ini."
            case .ru: return "О Аллах, с Тобой мы встретили утро; даруй нам сегодня спокойствие, веру и безопасность."
            case .fa: return "خدايا، به ياری تو به صبح رسيديم؛ امروز به ما آرامش، ايمان و امنيت عطا فرما."
            }
        case .eveningReminder:
            switch language {
            case .tr: return "Allahim, bu aksami Seninle karsiliyoruz; gecemize huzur, koruma ve guven ver."
            case .en: return "O Allah, by You we enter this evening; bless our night with peace, protection, and trust."
            case .de: return "O Allah, mit Dir erreichen wir den Abend; schenke unserer Nacht Frieden, Schutz und Vertrauen."
            case .ar: return "اللهم بك دخلنا هذا المساء، فاجعل ليلتنا سكينة وحفظا وأمنا."
            case .fr: return "Allah, c'est par Toi que nous entrons dans ce soir; accorde a notre nuit paix, protection et confiance."
            case .es: return "Allah, por Ti entramos en esta tarde; concede a nuestra noche paz, proteccion y confianza."
            case .id: return "Ya Allah, dengan-Mu kami memasuki petang; limpahkan malam kami dengan ketenangan, perlindungan, dan tawakal."
            case .ur: return "اے اللہ، تیرے ہی سہارے ہم نے شام پائی؛ ہماری رات کو سکون، حفاظت اور بھروسہ عطا فرما۔"
            case .ms: return "Ya Allah, dengan-Mu kami memasuki petang; limpahkan malam kami dengan ketenangan, perlindungan, dan tawakal."
            case .ru: return "О Аллах, с Тобой мы встретили вечер; даруй нашей ночи покой, защиту и упование."
            case .fa: return "خدايا، با ياری تو به اين شام رسيديم؛ به شب ما آرامش، حفاظت و اطمينان عطا فرما."
            }
        case .sleepReminder:
            switch language {
            case .tr: return "Allahim, Senin adinla uyur ve Senin adinla uyaniriz; gecemizi rahmetinle koru."
            case .en: return "O Allah, in Your name we sleep and in Your name we rise; guard our night with mercy."
            case .de: return "O Allah, in Deinem Namen schlafen wir und in Deinem Namen erwachen wir; behuete unsere Nacht mit Barmherzigkeit."
            case .ar: return "اللهم باسمك ننام وباسمك نقوم، فاحفظ ليلتنا برحمتك."
            case .fr: return "Allah, en Ton nom nous dormons et en Ton nom nous nous relevons; garde notre nuit par Ta misericorde."
            case .es: return "Allah, en Tu nombre dormimos y en Tu nombre despertamos; cuida nuestra noche con Tu misericordia."
            case .id: return "Ya Allah, dengan nama-Mu kami tidur dan dengan nama-Mu kami bangun; jagalah malam kami dengan rahmat-Mu."
            case .ur: return "اے اللہ، تیرے نام سے ہم سوتے ہیں اور تیرے نام سے جاگتے ہیں؛ اپنی رحمت سے ہماری رات کی حفاظت فرما۔"
            case .ms: return "Ya Allah, dengan nama-Mu kami tidur dan dengan nama-Mu kami bangun; peliharalah malam kami dengan rahmat-Mu."
            case .ru: return "О Аллах, с Твоим именем мы засыпаем и с Твоим именем встаем; сохрани нашу ночь Своей милостью."
            case .fa: return "خدايا، به نام تو می خوابيم و به نام تو برمی خيزيم؛ شب ما را با رحمت خود حفظ فرما."
            }
        case .smartDhikrNudge:
            switch language {
            case .tr: return "Guc ve kuvvet ancak Allah'in yardimiyladir; bu zikri kisa bir nefes gibi tekrar et."
            case .en: return "There is no power and no strength except through Allah; repeat this dhikr like a short breath of calm."
            case .de: return "Es gibt keine Kraft und keine Macht ausser durch Allah; wiederhole diesen Dhikr wie einen kurzen Atemzug der Ruhe."
            case .ar: return "لا قوة ولا قدرة إلا بالله؛ ردد هذا الذكر بهدوء ليرق قلبك."
            case .fr: return "Il n'y a de force et de puissance qu'en Allah; repete ce dhikr comme un court souffle d'apaisement."
            case .es: return "No hay fuerza ni poder sino en Allah; repite este dhikr como un breve respiro de calma."
            case .id: return "Tiada daya dan kekuatan kecuali dengan pertolongan Allah; ulangi dzikir ini sebagai jeda yang menenangkan."
            case .ur: return "طاقت اور قوت صرف اللہ کی مدد سے ہے؛ اس ذکر کو سکون کی ایک سانس کی طرح دہرا لیں۔"
            case .ms: return "Tiada daya dan kekuatan melainkan dengan pertolongan Allah; ulangi zikir ini sebagai hela nafas yang menenangkan."
            case .ru: return "Нет силы и мощи ни у кого, кроме как от Аллаха; повтори этот зикр как короткий вдох спокойствия."
            case .fa: return "هيچ نيرو و توانی جز به ياری خدا نيست؛ اين ذکر را مانند نفسی آرام تکرار کن."
            }
        case .streakComebackReminder:
            switch language {
            case .tr: return "Allah'tan bagislanma dile; kisa bir istigfar bile kalbi yeniden yumusatir."
            case .en: return "Ask Allah for forgiveness; even a brief istighfar can soften the heart again."
            case .de: return "Bitte Allah um Vergebung; selbst ein kurzes Istighfar kann das Herz wieder weich machen."
            case .ar: return "اطلب المغفرة من الله؛ فاستغفار قصير قد يلين القلب من جديد."
            case .fr: return "Demande pardon a Allah; meme un court istighfar peut adoucir le coeur a nouveau."
            case .es: return "Pide perdon a Allah; incluso un breve istighfar puede suavizar de nuevo el corazon."
            case .id: return "Mohon ampun kepada Allah; istighfar yang singkat pun dapat melembutkan hati kembali."
            case .ur: return "اللہ سے بخشش مانگو؛ مختصر استغفار بھی دل کو پھر نرم کر سکتا ہے۔"
            case .ms: return "Mohon keampunan kepada Allah; istighfar yang ringkas pun boleh melembutkan hati semula."
            case .ru: return "Проси у Аллаха прощения; даже короткий истигфар снова смягчает сердце."
            case .fa: return "از خدا آمرزش بخواه؛ حتی استغفاری کوتاه می تواند دل را دوباره نرم کند."
            }
        case .prayerReminder, .prayerTimeNow, .fridayBlessing, .specialDayReminder, .dailyAyah:
            return dailyAyahFallbackBody(for: language)
        }
    }

    private func resolveSound(settings: NotificationSettings, isPrayer: Bool) -> UNNotificationSound? {
        guard !settings.vibrationOnly else {
            return nil
        }
        return NotificationSoundCatalog.sound(for: settings.soundSelection, isPrayer: isPrayer)
    }

    private func prayerNotificationTitle(
        prayerName: String,
        scheduledDate: Date,
        settings: NotificationSettings,
        language: AppLanguage
    ) -> String {
        let timeText = formattedPrayerTime(scheduledDate, timezoneIdentifier: settings.currentTimezoneIdentifier, language: language)
        let locationSuffix = compactLocationTitle(from: settings.currentLocation).map { " (\($0))" } ?? ""

        switch language {
        case .tr:
            return "\(prayerName) saat \(timeText)\(locationSuffix)"
        case .ar:
            return "\(prayerName) الساعة \(timeText)\(locationSuffix)"
        case .fr:
            return "\(prayerName) a \(timeText)\(locationSuffix)"
        case .de:
            return "\(prayerName) um \(timeText)\(locationSuffix)"
        case .id:
            return "\(prayerName) pukul \(timeText)\(locationSuffix)"
        case .ms:
            return "\(prayerName) pada \(timeText)\(locationSuffix)"
        case .fa:
            return "\(prayerName) ساعت \(timeText)\(locationSuffix)"
        case .ru:
            return "\(prayerName) в \(timeText)\(locationSuffix)"
        case .es:
            return "\(prayerName) a las \(timeText)\(locationSuffix)"
        case .ur:
            return "\(prayerName) \(timeText)\(locationSuffix)"
        case .en:
            return "\(prayerName) at \(timeText)\(locationSuffix)"
        }
    }

    private func compactLocationTitle(from location: NotificationLocationSnapshot) -> String? {
        let candidates = [location.cityName, location.administrativeArea, location.country]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return candidates.first
    }

    private func formattedPrayerTime(_ date: Date, timezoneIdentifier: String, language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .autoupdatingCurrent
        formatter.locale = Locale(identifier: language.rawValue)
        formatter.dateFormat = language == .en ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }
}
