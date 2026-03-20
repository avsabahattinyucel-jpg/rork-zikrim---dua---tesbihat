import Foundation

enum QuranReaderStrings {
    static let title = localized("quran_reader_title", "Quran Reader")
    static let settingsTitle = localized("quran_reader_settings_title", "Reading Settings")
    static let appearanceSection = localized("quran_reader_section_appearance", "Appearance")
    static let quickSettingsTitle = localized("quran_reader_quick_settings_title", "Quick Settings")
    static let advancedSettingsTitle = localized("quran_reader_advanced_settings_title", "Advanced Settings")
    static let arabicTypographySection = localized("quran_reader_section_arabic_typography", "Arabic Text")
    static let translationSection = localized("quran_reader_section_translation", "Text & Spacing")
    static let layoutSection = localized("quran_reader_section_layout", "Layout")
    static let behaviorSection = localized("quran_reader_section_behavior", "Behavior")
    static let audioSection = localized("quran_reader_section_audio", "Audio")
    static let tafsirSection = localized("quran_reader_section_tafsir", "Tafsir")
    static let mushafTextStyle = localized("quran_reader_mushaf_text_style", "Mushaf Text")
    static let mushafTextStyleHint = localized("quran_reader_mushaf_text_style_hint", "This text style is only used in mushaf mode.")
    static let showTranslation = localized("quran_reader_show_translation", "Show Translation")
    static let showTransliteration = localized("quran_reader_show_transliteration", "Show Transliteration")
    static let showWordByWord = localized("quran_reader_show_word_by_word", "Show Word by Word")
    static let wordByWord = localized("quran_reader_word_by_word", "Word by Word")
    static let arabicFontSize = localized("quran_reader_arabic_font_size", "Arabic Size")
    static let arabicLineSpacing = localized("quran_reader_arabic_line_spacing", "Arabic Spacing")
    static let translationFontSize = localized("quran_reader_translation_font_size", "Translation Size")
    static let transliterationFontSize = localized("quran_reader_transliteration_font_size", "Transliteration Size")
    static let translationLineSpacing = localized("quran_reader_translation_line_spacing", "Translation Spacing")
    static let keepScreenAwake = localized("quran_reader_keep_screen_awake", "Keep screen awake while reading")
    static let autoHideChrome = localized("quran_reader_auto_hide_chrome", "Auto-hide chrome in mushaf mode")
    static let rememberLastPosition = localized("quran_reader_remember_last_position", "Remember last position")
    static let showAyahNumbers = localized("quran_reader_show_ayah_numbers", "Show ayah numbers")
    static let compactMode = localized("quran_reader_compact_mode", "Comfortable Density")
    static let preferredTafsirSource = localized("quran_reader_preferred_tafsir_source", "Default Source")
    static let showShortExplanationChip = localized("quran_reader_show_short_explanation_chip", "Show short tafsir")
    static let inlineTafsirPreview = localized("quran_reader_inline_tafsir_preview", "Show inline preview")
    static let tafsirFallbackLanguage = localized("quran_reader_tafsir_fallback_language", "Fallback language")
    static let settingsDone = localized("quran_reader_settings_done", "Done")
    static let audioResume = localized("quran_reader_audio_resume", "Resume")
    static let audioPause = localized("quran_reader_audio_pause", "Pause")
    static let audioPlay = localized("quran_reader_audio_play", "Play")
    static let bookmark = localized("quran_reader_bookmark", "Save")
    static let share = localized("quran_reader_share", "Share")
    static let copy = localized("quran_reader_copy", "Copy")
    static let note = localized("quran_reader_note", "Add Note")
    static let editNote = localized("quran_reader_edit_note", "Edit Note")
    static let personalNoteTitle = localized("quran_reader_personal_note_title", "Your Note")
    static let noteSheetTitle = localized("quran_reader_note_sheet_title", "Verse Note")
    static let noteSheetSubtitle = localized("quran_reader_note_sheet_subtitle", "Write what this ayah stirred in your heart.")
    static let notePlaceholder = localized("quran_reader_note_placeholder", "Capture a reflection, intention, dua, or reminder linked to this ayah...")
    static let noteSave = localized("quran_reader_note_save", "Save Note")
    static let noteDelete = localized("quran_reader_note_delete", "Delete Note")
    static let noteEmptyState = localized("quran_reader_note_empty_state", "A small, sincere note can turn revisiting this ayah into a more personal reading.")
    static let noteSaved = localized("quran_reader_note_saved", "Note saved")
    static let noteDeleted = localized("quran_reader_note_deleted", "Note deleted")
    static let openTafsir = localized("quran_reader_open_tafsir", "Open Tafsir")
    static let shortExplanation = localized("quran_reader_short_explanation", "Short Explanation")
    static let revealTranslation = localized("quran_reader_reveal_translation", "Reveal Translation")
    static let hideTranslation = localized("quran_reader_hide_translation", "Hide Translation")
    static let exitMushafMode = localized("quran_reader_exit_mushaf_mode", "Exit Mushaf Mode")
    static let mushafQuickControls = localized("quran_reader_mushaf_quick_controls", "Quick Controls")
    static let readingMood = localized("quran_reader_reading_mood", "Focused Reading")
    static let currentLayout = localized("quran_reader_current_layout", "Layout")
    static let currentContentMode = localized("quran_reader_current_content_mode", "Content")
    static let currentFont = localized("quran_reader_current_font", "Arabic Font")
    static let currentScript = localized("quran_reader_current_script", "Mushaf Text")
    static let fallbackTafsirMessage = localized("quran_reader_tafsir_unavailable", "Tafsir is not available for this ayah yet.")
    static let sourceAttribution = localized("quran_reader_source_attribution", "Source")
    static let license = localized("quran_reader_license", "Source Note")
    static let openFullTafsir = localized("quran_reader_open_full_tafsir", "Open full tafsir")
    static let close = localized("quran_reader_close", "Close")
    static let immersiveSubtitle = localized("quran_reader_immersive_subtitle", "Quiet, focused reading")
    static let pageModeTitleFormat = localized("quran_reader_page_mode_title_format", "Reading page %lld")
    static let copied = localized("quran_reader_copied", "Copied")
    static let loading = localized("quran_reader_loading", "Preparing verses...")
    static let retry = localized("quran_reader_retry", "Try Again")
    static let openAppearance = localized("quran_reader_open_appearance", "Reading settings")
    static let openAudio = localized("quran_reader_open_audio", "Open audio")
    static let audioExperienceTitle = localized("quran_reader_audio_experience_title", "Listening")
    static let audioProgress = localized("quran_reader_audio_progress", "Progress")
    static let audioCurrentTrack = localized("quran_reader_audio_current_track", "Current recitation")
    static let readingModeTitle = localized("quran_reader_reading_mode_title", "Reading Mode")
    static let translationSource = localized("quran_reader_translation_source", "Translation Source")
    static let proBadge = localized("quran_reader_pro_badge", "PRO")
    static let surahFallbackTitle = localized("quran_reader_surah_fallback_title", "Surah")

    static func languageName(_ language: AppLanguage) -> String {
        switch language {
        case .tr: return localized("quran_reader_language_turkish", "Turkish")
        case .en: return localized("quran_reader_language_english", "English")
        case .de: return localized("quran_reader_language_german", "German")
        case .ar: return localized("quran_reader_language_arabic", "Arabic")
        case .fr: return localized("quran_reader_language_french", "French")
        case .es: return localized("quran_reader_language_spanish", "Spanish")
        case .id: return localized("quran_reader_language_indonesian", "Indonesian")
        case .ur: return localized("quran_reader_language_urdu", "Urdu")
        case .ms: return localized("quran_reader_language_malay", "Malay")
        case .ru: return localized("quran_reader_language_russian", "Russian")
        case .fa: return localized("quran_reader_language_persian", "Persian")
        }
    }

    static func tafsirSourceDetail(_ source: QuranTafsirSource) -> String? {
        if AppLanguage.current == .tr {
            switch source.id {
            case QuranTafsirSource.zikrimShortExplanation.id:
                return "Uygulamadaki yerel tefsir içeriğinden derlenen kısa ve sade bir açıklama."
            case QuranTafsirSource.remoteMultiLanguageTafsir.id:
                return "Uygulamaya gömülü çok dilli kaynaklardan sunulan ayrıntılı tefsir metni."
            default:
                break
            }
        }

        return source.attribution.detailText
    }

    static func tafsirSourceLicense(_ source: QuranTafsirSource) -> String? {
        if AppLanguage.current == .tr {
            switch source.id {
            case QuranTafsirSource.zikrimShortExplanation.id:
                return "Bu kısa açıklama, ayetin anlamını hızlıca kavramaya yardımcı olan okuma notu olarak sunulur."
            case QuranTafsirSource.remoteMultiLanguageTafsir.id:
                return "Gösterilen metin, uygulamanın içindeki yerel kaynak dosyalarından okunur."
            default:
                break
            }
        }

        return source.attribution.licenseNote
    }

    static func localized(_ key: String, _ defaultValue: String) -> String {
        if let fontLocalization = localizedFontText(for: key, language: AppLanguage.current) {
            return fontLocalization
        }

        if AppLanguage.current == .tr {
            switch key {
            case "quran_reader_title": return "Kur'an"
            case "quran_reader_settings_title": return "Kur'an Okuma Ayarları"
            case "quran_reader_quick_settings_title": return "Hızlı Ayarlar"
            case "quran_reader_advanced_settings_title": return "Gelişmiş Ayarlar"
            case "quran_reader_section_appearance": return "Görünüm"
            case "quran_reader_section_arabic_typography": return "Arapça Metin"
            case "quran_reader_section_translation": return "Metin ve Aralık"
            case "quran_reader_section_layout": return "Yerleşim"
            case "quran_reader_section_behavior": return "Davranış"
            case "quran_reader_section_audio": return "Ses"
            case "quran_reader_section_tafsir": return "Tefsir"
            case "quran_reader_mushaf_text_style": return "Mushaf Metni"
            case "quran_reader_mushaf_text_style_hint": return "Sadece mushaf modunda uygulanır."
            case "quran_reader_show_translation": return "Meali Göster"
            case "quran_reader_show_transliteration": return "Okunuşu Göster"
            case "quran_reader_show_word_by_word": return "Kelime Kelime Göster"
            case "quran_reader_word_by_word": return "Kelime Kelime"
            case "quran_reader_arabic_font_size": return "Arapça Boyutu"
            case "quran_reader_arabic_line_spacing": return "Arapça Satır Aralığı"
            case "quran_reader_translation_font_size": return "Meal Boyutu"
            case "quran_reader_transliteration_font_size": return "Okunuş Boyutu"
            case "quran_reader_translation_line_spacing": return "Meal Satır Aralığı"
            case "quran_reader_keep_screen_awake": return "Okurken ekran açık kalsın"
            case "quran_reader_auto_hide_chrome": return "Mushaf modunda üst çubuğu gizle"
            case "quran_reader_remember_last_position": return "Son konumu hatırla"
            case "quran_reader_show_ayah_numbers": return "Ayet numaralarını göster"
            case "quran_reader_compact_mode": return "Yoğun görünüm"
            case "quran_reader_preferred_tafsir_source": return "Varsayılan kaynak"
            case "quran_reader_show_short_explanation_chip": return "Kısa açıklamayı göster"
            case "quran_reader_inline_tafsir_preview": return "Satır içi önizleme"
            case "quran_reader_tafsir_fallback_language": return "Yedek dil"
            case "quran_reader_settings_done": return "Tamam"
            case "quran_reader_audio_resume": return "Sürdür"
            case "quran_reader_audio_pause": return "Duraklat"
            case "quran_reader_audio_play": return "Dinle"
            case "quran_reader_bookmark": return "Kaydet"
            case "quran_reader_share": return "Paylaş"
            case "quran_reader_copy": return "Kopyala"
            case "quran_reader_note": return "Not Ekle"
            case "quran_reader_edit_note": return "Notu Düzenle"
            case "quran_reader_personal_note_title": return "Kişisel Notun"
            case "quran_reader_note_sheet_title": return "Ayet Notu"
            case "quran_reader_note_sheet_subtitle": return "Bu ayetin sende uyandırdığı manayı yaz."
            case "quran_reader_note_placeholder": return "Bu ayete bağlı bir tefekkür, niyet, dua ya da hatırlatma bırak..."
            case "quran_reader_note_save": return "Notu Kaydet"
            case "quran_reader_note_delete": return "Notu Sil"
            case "quran_reader_note_empty_state": return "Kısa ama samimi bir not, bu ayete her dönüşünü daha kişisel hale getirebilir."
            case "quran_reader_note_saved": return "Not kaydedildi"
            case "quran_reader_note_deleted": return "Not silindi"
            case "quran_reader_open_tafsir": return "Tefsir"
            case "quran_reader_short_explanation": return "Kısa açıklama"
            case "quran_reader_reveal_translation": return "Meali Göster"
            case "quran_reader_hide_translation": return "Meali Gizle"
            case "quran_reader_exit_mushaf_mode": return "Mushaf Modundan Çık"
            case "quran_reader_mushaf_quick_controls": return "Hızlı Kontroller"
            case "quran_reader_reading_mood": return "Odaklı Okuma"
            case "quran_reader_current_layout": return "Yerleşim"
            case "quran_reader_current_content_mode": return "İçerik"
            case "quran_reader_current_font": return "Arapça Font"
            case "quran_reader_current_script": return "Mushaf Metni"
            case "quran_reader_tafsir_unavailable": return "Bu ayet için henüz tefsir bulunmuyor."
            case "quran_reader_source_attribution": return "Kaynak"
            case "quran_reader_license": return "Kaynak notu"
            case "quran_reader_open_full_tafsir": return "Tam tefsiri aç"
            case "quran_reader_close": return "Kapat"
            case "quran_reader_immersive_subtitle": return "Sakin ve odaklı okuma"
            case "quran_reader_page_mode_title_format": return "Okuma sayfası %lld"
            case "quran_reader_copied": return "Kopyalandı"
            case "quran_reader_loading": return "Ayetler hazırlanıyor..."
            case "quran_reader_retry": return "Tekrar Dene"
            case "quran_reader_open_appearance": return "Kur'an okuma ayarları"
            case "quran_reader_open_audio": return "Ses ekranını aç"
            case "quran_reader_audio_experience_title": return "Dinleme"
            case "quran_reader_audio_progress": return "İlerleme"
            case "quran_reader_audio_current_track": return "Geçerli tilavet"
            case "quran_reader_reading_mode_title": return "Okuma Modu"
            case "quran_reader_translation_source": return "Meal kaynağı"
            case "quran_reader_pro_badge": return "PRO"
            case "quran_reader_surah_fallback_title": return "Sure"
            case "quran_reader_language_turkish": return "Türkçe"
            case "quran_reader_language_english": return "İngilizce"
            case "quran_reader_language_german": return "Almanca"
            case "quran_reader_language_arabic": return "Arapça"
            case "quran_reader_language_french": return "Fransızca"
            case "quran_reader_language_spanish": return "İspanyolca"
            case "quran_reader_language_indonesian": return "Endonezce"
            case "quran_reader_language_urdu": return "Urduca"
            case "quran_reader_language_malay": return "Malayca"
            case "quran_reader_language_russian": return "Rusça"
            case "quran_reader_language_persian": return "Farsça"
            case "quran_reader_appearance_standard_dark": return "Standart Koyu"
            case "quran_reader_appearance_mushaf": return "Mushaf Modu"
            case "quran_reader_appearance_sepia": return "Sepya"
            case "quran_reader_appearance_night_focus": return "Gece Odağı"
            case "quran_reader_appearance_translation_focus": return "Meal Odağı"
            case "quran_reader_appearance_standard_dark_subtitle": return "Zarif karanlık zemin ve rafine kontrast."
            case "quran_reader_appearance_mushaf_subtitle": return "Minimal arayüz ve Arapça merkezli sakin odak."
            case "quran_reader_appearance_sepia_subtitle": return "Uzun okumalar için yumuşak kâğıt hissi."
            case "quran_reader_appearance_night_focus_subtitle": return "Uzun gece okumaları için daha yumuşak karanlık palet."
            case "quran_reader_appearance_translation_focus_subtitle": return "Anlamaya odaklanan daha dengeli satır akışı."
            case "quran_reader_display_arabic_only": return "Sadece Arapça"
            case "quran_reader_display_arabic_translation": return "Arapça ve Meal"
            case "quran_reader_display_arabic_transliteration_translation": return "Arapça, Okunuş ve Meal"
            case "quran_reader_display_translation_only": return "Sadece Meal"
            case "quran_reader_layout_verse_by_verse": return "Ayet Ayet"
            case "quran_reader_layout_page_mode": return "Sayfa Modu"
            case "quran_reader_layout_mushaf_focused": return "Mushaf Odaklı"
            case "quran_reader_mode_mushaf": return "Mushaf Modu"
            case "quran_reader_mode_reading": return "Okuma Modu"
            case "quran_reader_mode_study": return "Çalışma Modu"
            case "quran_reader_content_mode": return "İçerik Modu"
            case "quran_reader_layout_picker": return "Yerleşim Stili"
            case "quran_reader_script_standard_uthmani": return "Standart Osmanî"
            case "quran_reader_script_indopak_mushaf": return "IndoPak Mushafı"
            case "quran_reader_tafsir_source_zikrim_short_explanation": return "Kısa Açıklama"
            case "quran_reader_tafsir_source_remote_multi_language_tafsir": return "Çok Dilli Tefsir"
            case "quran_reader_ayah_accessibility_format": return "Ayet %lld"
            case "quran_reader_tafsir_title_format": return "%@ Tefsiri"
            default:
                break
            }
        }
        return Bundle.main.localizedString(forKey: key, value: defaultValue, table: nil)
    }

    static func readingModeTitle(_ mode: QuranReadingMode) -> String {
        localized(mode.localizationKey, mode.defaultTitle)
    }

    private static func localizedFontText(for key: String, language: AppLanguage) -> String? {
        switch language {
        case .tr:
            switch key {
            case "quran_reader_font_standard_naskh": return "Tilavet"
            case "quran_reader_font_classic_mushaf": return "Mushaf"
            case "quran_reader_font_traditional_naskh": return "Miras"
            case "quran_reader_font_standard_naskh_detail": return "Günlük okuma için sade ve dengeli."
            case "quran_reader_font_classic_mushaf_detail": return "Klasik mushaf hissi daha güçlü."
            case "quran_reader_font_traditional_naskh_detail": return "Daha köklü ve geleneği güçlü bir görünüm."
            case "quran_reader_font_active_format": return "Etkin yazı stili: %@"
            case "quran_reader_font_fallback_note": return "Bu stile en yakın Arapça yazı tipi kullanılıyor."
            default: return nil
            }
        case .en:
            switch key {
            case "quran_reader_font_standard_naskh": return "Recitation"
            case "quran_reader_font_classic_mushaf": return "Mushaf"
            case "quran_reader_font_traditional_naskh": return "Heritage"
            case "quran_reader_font_standard_naskh_detail": return "Clear and balanced for everyday reading."
            case "quran_reader_font_classic_mushaf_detail": return "A classic mushaf feel with more character."
            case "quran_reader_font_traditional_naskh_detail": return "A deeper traditional tone with rooted forms."
            case "quran_reader_font_active_format": return "Current style: %@"
            case "quran_reader_font_fallback_note": return "Using the closest available Arabic font for this style."
            default: return nil
            }
        case .de:
            switch key {
            case "quran_reader_font_standard_naskh": return "Rezitation"
            case "quran_reader_font_classic_mushaf": return "Mushaf"
            case "quran_reader_font_traditional_naskh": return "Tradition"
            case "quran_reader_font_standard_naskh_detail": return "Klar und ausgewogen für das tägliche Lesen."
            case "quran_reader_font_classic_mushaf_detail": return "Mit einem stärkeren klassischen Mushaf-Gefühl."
            case "quran_reader_font_traditional_naskh_detail": return "Tiefer, ruhiger und nah an der überlieferten Form."
            case "quran_reader_font_active_format": return "Aktiver Schriftstil: %@"
            case "quran_reader_font_fallback_note": return "Die passendste arabische Schrift für diesen Stil wird verwendet."
            default: return nil
            }
        case .ar:
            switch key {
            case "quran_reader_font_standard_naskh": return "تلاوة"
            case "quran_reader_font_classic_mushaf": return "مصحف"
            case "quran_reader_font_traditional_naskh": return "تراث"
            case "quran_reader_font_standard_naskh_detail": return "واضح ومتوازن للقراءة اليومية."
            case "quran_reader_font_classic_mushaf_detail": return "إحساس مصحفي كلاسيكي بحضور أوضح."
            case "quran_reader_font_traditional_naskh_detail": return "طابع أعمق وأقرب إلى الجذور التقليدية."
            case "quran_reader_font_active_format": return "النمط الحالي: %@"
            case "quran_reader_font_fallback_note": return "يتم استخدام أقرب خط عربي متاح لهذا النمط."
            default: return nil
            }
        case .fr:
            switch key {
            case "quran_reader_font_standard_naskh": return "Récitation"
            case "quran_reader_font_classic_mushaf": return "Mushaf"
            case "quran_reader_font_traditional_naskh": return "Héritage"
            case "quran_reader_font_standard_naskh_detail": return "Clair et équilibré pour la lecture quotidienne."
            case "quran_reader_font_classic_mushaf_detail": return "Un ressenti de mushaf plus classique et plus présent."
            case "quran_reader_font_traditional_naskh_detail": return "Un ton plus profond, proche de la tradition."
            case "quran_reader_font_active_format": return "Style actif : %@"
            case "quran_reader_font_fallback_note": return "La police arabe la plus proche est utilisée pour ce style."
            default: return nil
            }
        case .es:
            switch key {
            case "quran_reader_font_standard_naskh": return "Recitación"
            case "quran_reader_font_classic_mushaf": return "Mushaf"
            case "quran_reader_font_traditional_naskh": return "Tradición"
            case "quran_reader_font_standard_naskh_detail": return "Claro y equilibrado para la lectura diaria."
            case "quran_reader_font_classic_mushaf_detail": return "Con una sensación más clásica de mushaf."
            case "quran_reader_font_traditional_naskh_detail": return "Un tono más profundo y cercano a la tradición."
            case "quran_reader_font_active_format": return "Estilo activo: %@"
            case "quran_reader_font_fallback_note": return "Se usa la fuente árabe más cercana disponible para este estilo."
            default: return nil
            }
        case .id:
            switch key {
            case "quran_reader_font_standard_naskh": return "Tilawah"
            case "quran_reader_font_classic_mushaf": return "Mushaf"
            case "quran_reader_font_traditional_naskh": return "Warisan"
            case "quran_reader_font_standard_naskh_detail": return "Jernih dan seimbang untuk bacaan harian."
            case "quran_reader_font_classic_mushaf_detail": return "Nuansa mushaf klasik yang lebih terasa."
            case "quran_reader_font_traditional_naskh_detail": return "Lebih dalam dan dekat dengan bentuk tradisi."
            case "quran_reader_font_active_format": return "Gaya aktif: %@"
            case "quran_reader_font_fallback_note": return "Font Arab terdekat digunakan untuk gaya ini."
            default: return nil
            }
        case .ur:
            switch key {
            case "quran_reader_font_standard_naskh": return "تلاوت"
            case "quran_reader_font_classic_mushaf": return "مصحف"
            case "quran_reader_font_traditional_naskh": return "روایت"
            case "quran_reader_font_standard_naskh_detail": return "روزمرہ تلاوت کے لئے صاف اور متوازن."
            case "quran_reader_font_classic_mushaf_detail": return "کلاسیکی مصحف کا احساس زیادہ نمایاں."
            case "quran_reader_font_traditional_naskh_detail": return "زیادہ گہرا اور روایتی انداز کے قریب."
            case "quran_reader_font_active_format": return "فعال انداز: %@"
            case "quran_reader_font_fallback_note": return "اس انداز کے لئے قریب ترین عربی فونٹ استعمال ہو رہا ہے."
            default: return nil
            }
        case .ms:
            switch key {
            case "quran_reader_font_standard_naskh": return "Tilawah"
            case "quran_reader_font_classic_mushaf": return "Mushaf"
            case "quran_reader_font_traditional_naskh": return "Warisan"
            case "quran_reader_font_standard_naskh_detail": return "Jelas dan seimbang untuk bacaan harian."
            case "quran_reader_font_classic_mushaf_detail": return "Rasa mushaf klasik yang lebih kuat."
            case "quran_reader_font_traditional_naskh_detail": return "Lebih mendalam dan dekat dengan bentuk tradisi."
            case "quran_reader_font_active_format": return "Gaya aktif: %@"
            case "quran_reader_font_fallback_note": return "Fon Arab yang paling hampir digunakan untuk gaya ini."
            default: return nil
            }
        case .ru:
            switch key {
            case "quran_reader_font_standard_naskh": return "Тилават"
            case "quran_reader_font_classic_mushaf": return "Мусхаф"
            case "quran_reader_font_traditional_naskh": return "Наследие"
            case "quran_reader_font_standard_naskh_detail": return "Четкий и уравновешенный стиль для ежедневного чтения."
            case "quran_reader_font_classic_mushaf_detail": return "Более выраженное классическое ощущение мусхафа."
            case "quran_reader_font_traditional_naskh_detail": return "Более глубокий стиль, близкий к традиции."
            case "quran_reader_font_active_format": return "Текущий стиль: %@"
            case "quran_reader_font_fallback_note": return "Для этого стиля используется ближайший доступный арабский шрифт."
            default: return nil
            }
        case .fa:
            switch key {
            case "quran_reader_font_standard_naskh": return "تلاوت"
            case "quran_reader_font_classic_mushaf": return "مصحف"
            case "quran_reader_font_traditional_naskh": return "میراث"
            case "quran_reader_font_standard_naskh_detail": return "روشن و متعادل برای خواندن روزانه."
            case "quran_reader_font_classic_mushaf_detail": return "حال و هوای کلاسیک مصحف را پررنگ تر می کند."
            case "quran_reader_font_traditional_naskh_detail": return "عمیق تر و نزدیک تر به فرم های ریشه دار."
            case "quran_reader_font_active_format": return "سبک فعال: %@"
            case "quran_reader_font_fallback_note": return "نزدیک ترین قلم عربی برای این سبک استفاده می شود."
            default: return nil
            }
        }
    }

    static func ayahAccessibilityLabel(_ ayahNumber: Int) -> String {
        String.localizedStringWithFormat(
            localized("quran_reader_ayah_accessibility_format", "Ayah %lld"),
            Int64(ayahNumber)
        )
    }

    static func tafsirTitle(_ reference: AyahReference) -> String {
        String.localizedStringWithFormat(
            localized("quran_reader_tafsir_title_format", "Tafsir %@"),
            reference.id
        )
    }
}
