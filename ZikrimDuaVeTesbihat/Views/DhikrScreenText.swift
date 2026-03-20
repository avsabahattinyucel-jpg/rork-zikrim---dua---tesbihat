import Foundation

enum DhikrScreenTextKey {
    case resetConfirmationTitle
    case resetConfirmationMessage
    case deleteConfirmationTitle
    case deleteConfirmationMessage
    case stepHeaderFormat
    case countFractionFormat
    case freeModeActive
    case freeTargetShort
    case freeTargetAccessibility
    case detailsAccessibility
    case calendarAccessibility
    case milestoneReachedFormat
    case counterAccessibilityFormat
    case counterAccessibilityHint
    case manageAccessibility
    case emptyStateTitle
    case emptyStateMessage
    case openCalendarAction
    case calendarTitle
    case previousMonthAccessibility
    case nextMonthAccessibility
    case selectedDayDhikrTitle
    case selectedDayDhikrEmptyTitle
    case selectedDayDhikrEmptyMessage
    case selectedDayTopDhikrTitle
    case selectedDayAllDhikrsTitle
    case selectedDaySessionsTitle
    case selectedDayDistinctTitle
    case selectedDayGoalTitle
    case selectedDayCountAccessibilityFormat
}

enum DhikrScreenText {
    static func string(_ key: DhikrScreenTextKey) -> String {
        let code = languageBucket(RabiaAppLanguage.currentCode())

        switch key {
        case .resetConfirmationTitle:
            return localized(code, tr: "Sayaç sıfırlansın mı?", en: "Reset count?", ar: "هل تريد تصفير العدّ؟", fr: "Réinitialiser le compteur ?", de: "Zähler zurücksetzen?", id: "Atur ulang hitungan?", ms: "Tetapkan semula kiraan?", fa: "شمارنده بازنشانی شود؟", ru: "Сбросить счетчик?", es: "¿Restablecer el contador?", ur: "کیا گنتی ری سیٹ کرنی ہے؟")
        case .resetConfirmationMessage:
            return localized(code, tr: "Bu işlem mevcut zikir oturumunun ilerlemesini temizler.", en: "This clears the current dhikr progress for this session.", ar: "سيؤدي هذا إلى مسح تقدّم الذكر الحالي لهذه الجلسة.", fr: "Cela efface la progression actuelle du dhikr pour cette session.", de: "Dadurch wird der aktuelle Dhikr-Fortschritt dieser Sitzung gelöscht.", id: "Ini akan menghapus progres dzikir saat ini untuk sesi ini.", ms: "Ini akan memadam kemajuan zikir semasa untuk sesi ini.", fa: "این کار پیشرفت فعلی ذکر را برای این جلسه پاک می‌کند.", ru: "Это очистит текущий прогресс зикра для этой сессии.", es: "Esto borrará el progreso actual del dhikr en esta sesión.", ur: "یہ اس نشست کے موجودہ ذکر کی پیش رفت کو صاف کر دے گا۔")
        case .deleteConfirmationTitle:
            return localized(code, tr: "Zikir silinsin mi?", en: "Delete dhikr?", ar: "هل تريد حذف الذكر؟", fr: "Supprimer ce dhikr ?", de: "Dhikr löschen?", id: "Hapus dzikir?", ms: "Padam zikir ini?", fa: "ذکر حذف شود؟", ru: "Удалить зикр?", es: "¿Eliminar este dhikr?", ur: "کیا یہ ذکر حذف کرنا ہے؟")
        case .deleteConfirmationMessage:
            return localized(code, tr: "Bu işlem seçili zikir sayacını cihazından kaldırır.", en: "This removes the selected dhikr counter from your device.", ar: "سيؤدي هذا إلى إزالة عدّاد الذكر المحدد من جهازك.", fr: "Cela supprime le compteur de dhikr sélectionné de votre appareil.", de: "Dadurch wird der ausgewählte Dhikr-Zähler von deinem Gerät entfernt.", id: "Ini akan menghapus penghitung dzikir yang dipilih dari perangkat Anda.", ms: "Ini akan membuang kaunter zikir yang dipilih daripada peranti anda.", fa: "این کار شمارنده ذکر انتخاب‌شده را از دستگاه شما حذف می‌کند.", ru: "Это удалит выбранный счетчик зикра с вашего устройства.", es: "Esto eliminará el contador de dhikr seleccionado de tu dispositivo.", ur: "یہ آپ کے آلے سے منتخب ذکر کاؤنٹر کو حذف کر دے گا۔")
        case .stepHeaderFormat:
            return localized(code, tr: "%1$lld / %2$lld adım", en: "Step %1$lld of %2$lld", ar: "الخطوة %1$lld من %2$lld", fr: "Étape %1$lld sur %2$lld", de: "Schritt %1$lld von %2$lld", id: "Langkah %1$lld dari %2$lld", ms: "Langkah %1$lld daripada %2$lld", fa: "مرحله %1$lld از %2$lld", ru: "Шаг %1$lld из %2$lld", es: "Paso %1$lld de %2$lld", ur: "مرحلہ %1$lld از %2$lld")
        case .countFractionFormat:
            return "%1$lld / %2$lld"
        case .freeModeActive:
            return localized(code, tr: "Serbest mod", en: "Free mode", ar: "الوضع الحر", fr: "Mode libre", de: "Freier Modus", id: "Mode bebas", ms: "Mod bebas", fa: "حالت آزاد", ru: "Свободный режим", es: "Modo libre", ur: "فری موڈ")
        case .freeTargetShort:
            return localized(code, tr: "Serbest", en: "Free", ar: "حر", fr: "Libre", de: "Frei", id: "Bebas", ms: "Bebas", fa: "آزاد", ru: "Свободно", es: "Libre", ur: "آزاد")
        case .freeTargetAccessibility:
            return localized(code, tr: "serbest mod", en: "free mode", ar: "الوضع الحر", fr: "mode libre", de: "freier Modus", id: "mode bebas", ms: "mod bebas", fa: "حالت آزاد", ru: "свободный режим", es: "modo libre", ur: "فری موڈ")
        case .detailsAccessibility:
            return localized(code, tr: "Zikir detayları", en: "Dhikr details", ar: "تفاصيل الذكر", fr: "Détails du dhikr", de: "Dhikr-Details", id: "Detail dzikir", ms: "Butiran zikir", fa: "جزئیات ذکر", ru: "Подробности зикра", es: "Detalles del dhikr", ur: "ذکر کی تفصیلات")
        case .calendarAccessibility:
            return localized(code, tr: "Takvimi aç", en: "Open calendar", ar: "افتح التقويم", fr: "Ouvrir le calendrier", de: "Kalender öffnen", id: "Buka kalender", ms: "Buka kalendar", fa: "باز کردن تقویم", ru: "Открыть календарь", es: "Abrir calendario", ur: "کیلنڈر کھولیں")
        case .milestoneReachedFormat:
            return localized(code, tr: "%lld tamamlandı", en: "%lld reached", ar: "تم الوصول إلى %lld", fr: "%lld atteint", de: "%lld erreicht", id: "%lld tercapai", ms: "%lld dicapai", fa: "%lld تکمیل شد", ru: "достигнуто %lld", es: "%lld alcanzado", ur: "%lld مکمل")
        case .counterAccessibilityFormat:
            return localized(code, tr: "Zikir sayacı, %1$lld, hedef %2$@", en: "Dhikr counter, %1$lld, target %2$@", ar: "عداد الذكر، %1$lld، الهدف %2$@", fr: "Compteur de dhikr, %1$lld, objectif %2$@", de: "Dhikr-Zähler, %1$lld, Ziel %2$@", id: "Penghitung dzikir, %1$lld, target %2$@", ms: "Kaunter zikir, %1$lld, sasaran %2$@", fa: "شمارنده ذکر، %1$lld، هدف %2$@", ru: "Счетчик зикра: %1$lld, цель %2$@", es: "Contador de dhikr, %1$lld, objetivo %2$@", ur: "ذکر کاؤنٹر، %1$lld، ہدف %2$@")
        case .counterAccessibilityHint:
            return localized(code, tr: "Bir zikir daha eklemek için çift dokun.", en: "Double tap to add one dhikr.", ar: "اضغط مرتين لإضافة ذكر واحد.", fr: "Touchez deux fois pour ajouter un dhikr.", de: "Doppeltippen, um einen Dhikr hinzuzufügen.", id: "Ketuk dua kali untuk menambah satu dzikir.", ms: "Ketik dua kali untuk menambah satu zikir.", fa: "برای افزودن یک ذکر دوبار ضربه بزنید.", ru: "Дважды нажмите, чтобы добавить один зикр.", es: "Toca dos veces para añadir un dhikr.", ur: "ایک ذکر شامل کرنے کے لیے دو بار ٹیپ کریں۔")
        case .manageAccessibility:
            return localized(code, tr: "Zikirleri yönet", en: "Manage dhikrs", ar: "إدارة الأذكار", fr: "Gérer les dhikrs", de: "Dhikrs verwalten", id: "Kelola dzikir", ms: "Urus zikir", fa: "مدیریت اذکار", ru: "Управление зикрами", es: "Gestionar dhikrs", ur: "اذکار کا نظم")
        case .emptyStateTitle:
            return localized(code, tr: "Huşû ile zikre başla", en: "Begin dhikr with khushu", ar: "ابدأ الذكر بخشوع", fr: "Commence le dhikr avec recueillement", de: "Beginne den Dhikr mit Khuschu", id: "Mulailah dzikir dengan khusyuk", ms: "Mulakan zikir dengan khusyuk", fa: "ذکر را با خشوع آغاز کن", ru: "Начни зикр с хушу", es: "Comienza el dhikr con recogimiento", ur: "خشوع کے ساتھ ذکر شروع کریں")
        case .emptyStateMessage:
            return localized(code, tr: "İlk zikrini ekle; tesbihatını huşû ile yapıp kalbini Allah'ı anmaya yönelt.", en: "Add your first dhikr, complete your tasbih with khushu, and turn your heart to the remembrance of Allah.", ar: "أضف ذكرك الأول، وأدِّ تسبيحك بخشوع، ووجّه قلبك إلى ذكر الله.", fr: "Ajoute ton premier dhikr, fais ton tasbih avec recueillement et tourne ton cœur vers le rappel d’Allah.", de: "Füge deinen ersten Dhikr hinzu, verrichte deinen Tasbih mit Khuschu und richte dein Herz auf das Gedenken Allahs.", id: "Tambahkan dzikir pertamamu, lakukan tasbih dengan khusyuk, dan arahkan hatimu kepada mengingat Allah.", ms: "Tambahkan zikir pertama anda, lakukan tasbih dengan khusyuk, dan arahkan hati kepada mengingati Allah.", fa: "اولین ذکر خود را اضافه کن، تسبیح را با خشوع به جا آور و دل خود را به یاد خدا متوجه کن.", ru: "Добавьте свой первый зикр, совершайте тасбих с хушу и обратите сердце к поминанию Аллаха.", es: "Anade tu primer dhikr, realiza tu tasbih con recogimiento y orienta tu corazon al recuerdo de Allah.", ur: "اپنا پہلا ذکر شامل کریں، خشوع کے ساتھ تسبیح کریں اور اپنے دل کو اللہ کے ذکر کی طرف متوجہ کریں۔")
        case .openCalendarAction:
            return localized(code, tr: "Takvimi Aç", en: "Open Calendar", ar: "افتح التقويم", fr: "Ouvrir le calendrier", de: "Kalender öffnen", id: "Buka Kalender", ms: "Buka Kalendar", fa: "باز کردن تقویم", ru: "Открыть календарь", es: "Abrir calendario", ur: "کیلنڈر کھولیں")
        case .calendarTitle:
            return localized(code, tr: "Takvim", en: "Calendar", ar: "التقويم", fr: "Calendrier", de: "Kalender", id: "Kalender", ms: "Kalendar", fa: "تقویم", ru: "Календарь", es: "Calendario", ur: "کیلنڈر")
        case .previousMonthAccessibility:
            return localized(code, tr: "Önceki ay", en: "Previous month", ar: "الشهر السابق", fr: "Mois précédent", de: "Vorheriger Monat", id: "Bulan sebelumnya", ms: "Bulan sebelumnya", fa: "ماه قبل", ru: "Предыдущий месяц", es: "Mes anterior", ur: "پچھلا مہینہ")
        case .nextMonthAccessibility:
            return localized(code, tr: "Sonraki ay", en: "Next month", ar: "الشهر التالي", fr: "Mois suivant", de: "Nächster Monat", id: "Bulan berikutnya", ms: "Bulan seterusnya", fa: "ماه بعد", ru: "Следующий месяц", es: "Mes siguiente", ur: "اگلا مہینہ")
        case .selectedDayDhikrTitle:
            return localized(code, tr: "Günün zikir detayı", en: "Day's dhikr details", ar: "تفاصيل ذكر هذا اليوم", fr: "Détails du dhikr du jour", de: "Dhikr-Details des Tages", id: "Detail dzikir hari ini", ms: "Butiran zikir hari ini", fa: "جزئیات ذکر روز", ru: "Подробности зикра за день", es: "Detalles del dhikr del día", ur: "دن کے ذکر کی تفصیل")
        case .selectedDayDhikrEmptyTitle:
            return localized(code, tr: "Bu gün için zikir kaydı yok", en: "No dhikr recorded for this day", ar: "لا يوجد ذكر مسجل لهذا اليوم", fr: "Aucun dhikr enregistré pour ce jour", de: "Für diesen Tag wurde kein Dhikr erfasst", id: "Tidak ada dzikir yang tercatat untuk hari ini", ms: "Tiada zikir direkodkan untuk hari ini", fa: "برای این روز ذکری ثبت نشده است", ru: "За этот день зикр не записан", es: "No hay dhikr registrado para este día", ur: "اس دن کے لیے کوئی ذکر ریکارڈ نہیں")
        case .selectedDayDhikrEmptyMessage:
            return localized(code, tr: "Bir zikir tamamlandığında burada o güne ait toplam ve dağılım görünecek.", en: "When dhikr is completed, the day's total and breakdown will appear here.", ar: "عند إتمام الذكر سيظهر هنا إجمالي اليوم وتفصيله.", fr: "Lorsqu’un dhikr est accompli, le total et la répartition du jour apparaîtront ici.", de: "Sobald Dhikr abgeschlossen wurde, erscheinen hier die Tagessumme und die Aufteilung.", id: "Saat dzikir diselesaikan, total dan rincian hari itu akan tampil di sini.", ms: "Apabila zikir diselesaikan, jumlah dan pecahan hari itu akan dipaparkan di sini.", fa: "وقتی ذکر انجام شود، مجموع و جزئیات آن روز اینجا دیده می‌شود.", ru: "Когда зикр будет совершен, здесь появятся итог и разбивка за день.", es: "Cuando se complete un dhikr, aquí aparecerán el total y el desglose del día.", ur: "جب ذکر مکمل ہوگا تو اس دن کی کل تعداد اور تفصیل یہاں نظر آئے گی۔")
        case .selectedDayTopDhikrTitle:
            return localized(code, tr: "En çok okunan", en: "Most recited", ar: "الأكثر تكرارًا", fr: "Le plus récité", de: "Am häufigsten rezitiert", id: "Paling banyak dibaca", ms: "Paling banyak dibaca", fa: "بیشترین تکرار", ru: "Чаще всего читали", es: "Más recitado", ur: "سب سے زیادہ پڑھا گیا")
        case .selectedDayAllDhikrsTitle:
            return localized(code, tr: "Tüm zikirler", en: "All dhikrs", ar: "جميع الأذكار", fr: "Tous les dhikrs", de: "Alle Dhikrs", id: "Semua dzikir", ms: "Semua zikir", fa: "همه اذکار", ru: "Все зикры", es: "Todos los dhikrs", ur: "تمام اذکار")
        case .selectedDaySessionsTitle:
            return localized(code, tr: "Oturum", en: "Sessions", ar: "الجلسات", fr: "Séances", de: "Sitzungen", id: "Sesi", ms: "Sesi", fa: "جلسه", ru: "Сессии", es: "Sesiones", ur: "سیشنز")
        case .selectedDayDistinctTitle:
            return localized(code, tr: "Farklı zikir", en: "Distinct dhikrs", ar: "أذكار مختلفة", fr: "Dhikrs distincts", de: "Verschiedene Dhikrs", id: "Dzikir berbeda", ms: "Zikir berbeza", fa: "اذکار متفاوت", ru: "Разных зикров", es: "Dhikrs distintos", ur: "مختلف اذکار")
        case .selectedDayGoalTitle:
            return localized(code, tr: "Hedef", en: "Goal", ar: "الهدف", fr: "Objectif", de: "Ziel", id: "Target", ms: "Sasaran", fa: "هدف", ru: "Цель", es: "Objetivo", ur: "ہدف")
        case .selectedDayCountAccessibilityFormat:
            return localized(code, tr: "%1$@, %2$lld tekrar", en: "%1$@, %2$lld recitations", ar: "%1$@، %2$lld تكرارًا", fr: "%1$@, %2$lld répétitions", de: "%1$@, %2$lld Wiederholungen", id: "%1$@, %2$lld kali", ms: "%1$@, %2$lld ulangan", fa: "%1$@، %2$lld بار", ru: "%1$@, %2$lld повторений", es: "%1$@, %2$lld repeticiones", ur: "%1$@، %2$lld بار")
        }
    }

    private static func localized(
        _ code: String,
        tr: String,
        en: String,
        ar: String,
        fr: String,
        de: String,
        id: String,
        ms: String,
        fa: String,
        ru: String,
        es: String,
        ur: String
    ) -> String {
        switch code {
        case "tr": return tr
        case "ar": return ar
        case "fr": return fr
        case "de": return de
        case "id": return id
        case "ms": return ms
        case "fa": return fa
        case "ru": return ru
        case "es": return es
        case "ur": return ur
        default: return en
        }
    }

    private static func languageBucket(_ code: String) -> String {
        let lowered = code.lowercased()
        let supported = ["tr", "ar", "en", "fr", "de", "id", "ms", "fa", "ru", "es", "ur"]
        return supported.first(where: { lowered.hasPrefix($0) }) ?? "en"
    }
}
