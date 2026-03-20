# Quran Reader Integration Notes

## Mimari Ozet

Yeni Quran Reader katmani, mevcut Zikrim tema sisteminin ustune oturan ikinci bir gorunum katmani olarak tasarlandi.

- Uygulama temasi degismedi.
- Navigation, toolbar, accent ve shell kimligi mevcut `ThemeManager` tarafinda kaldi.
- Quran okuyucu icindeki canvas, tipografi ve miniplayer yuzeyi `QuranReaderAppearanceEngine` ile ayri yonetiliyor.
- Veri akisi dogrudan view icine gomulmedi; repository ve provider arayuzleri uzerinden okunuyor.

## Ana Dosyalar

- `Models/QuranReaderAppearance.swift`
  Quran okuyucuya ozel gorunum modlari ve canvas renk tokenlari.
- `Models/QuranFontOption.swift`
  Arapca font secenekleri ve premium hook bilgisi.
- `Models/QuranDisplayMode.swift`
  Icerik gosterim modlari, layout modlari ve verse/page abstraction tipleri.
- `Models/QuranReaderPreferences.swift`
  Tum kalici okuyucu tercihleri.
- `Models/QuranTafsirSource.swift`
  Tafsir kaynak metadatasi, attribution ve availability modeli.
- `Store/QuranReaderPreferencesStore.swift`
  Yerel preference persistence katmani.
- `Support/QuranFontResolver.swift`
  Arapca font fallback ve resolver mantigi.
- `Support/QuranReaderAppearanceEngine.swift`
  App theme + Quran reader appearance katmanini birlestiren stil motoru.
- `Data/QuranReaderRepositories.swift`
  Text, translation, transliteration, audio, bookmark ve progress protokolleri.
- `Data/ZikrimQuranRepositories.swift`
  Mevcut app servislerine baglanan adapter implementasyonlari.
- `Data/MockQuranTafsirProvider.swift`
  Cache, fallback chain ve extensible tafsir provider ornegi.
- `ViewModels/QuranReaderViewModel.swift`
  Reader state, persistence, progress, tafsir, bookmark ve toolbar mantigi.
- `Views/QuranReaderAppearanceSheet.swift`
  Ayarlar alt sheet giris noktasi.
- `Views/QuranVerseBlockView.swift`
  Verse-by-verse ayah block UI.
- `Views/QuranTafsirDetailView.swift`
  Full tafsir detay sheet'i.
- `Views/QuranReaderMiniPlayerCard.swift`
  Audio aktifken yapiskan mini player yuzeyi.
- `Views/Quran/QuranReaderScreen.swift`
  Reader ana ekran compositing ve layout kararlari.
- `Views/SurahDetailView.swift`
  Mevcut app navigation akisindan yeni reader'a baglanan entegrasyon noktasi.

## Mevcut Uygulama Entegrasyonu

- `ZikrimQuranTextRepository`
  Once embedded `QuranSurahData.offlineVerses` kullanir, gerekli olursa mevcut remote Arabic fetch yoluna duser.
- `ZikrimQuranTranslationRepository`
  Mevcut `QuranTranslationService` katmanini kullanir.
- `ZikrimQuranBookmarksRepository`
  Mevcut `QuranService` ve `StorageService` ile bookmark/favorite davranisini korur.
- `ZikrimQuranProgressRepository`
  Son okunan konumu hem yeni anchor modeliyle hem de mevcut `QuranService.saveLastRead` ile yazar.
- `QuranAudioReaderViewModel`
  Eski audio reader mantigi korunarak yeni ekrana baglandi.

## TODO Adaptasyon Noktalari

- `ZikrimQuranTransliterationRepository`
  Gercek embedded transliteration dataset'i geldiginde buraya baglanmali.
- `MockQuranTafsirProvider`
  `diyanetTurkishTafsir` ve `remoteMultiLanguageTafsir` case'leri icin gercek adapter implementasyonlari eklenmeli.
- `QuranFontResolver`
  Uretim font asset dosyalari app bundle'a eklendiginde `Noto Naskh Arabic`, `Amiri Quran` ve `Scheherazade New` icin kesin family adlari burada dogrulanmali.
- `QuranReaderFeatureGating`
  Mevcut premium/entitlement altyapisi ile baglanarak font, tafsir source ve gelismis layout kararlarini merkezi olarak yonetmeli.
- Verse action row
  Note/highlight gibi ileride premium olabilecek aksiyonlar mevcut altyapiya hook'lanmali.

## Lokalizasyon

Tum reader UI string'leri `QuranReaderStrings.swift` icinde key + English default value seklinde tanimlandi.

- Yeni dil eklerken sadece mevcut localization sistemine bu key'ler map edilmesi yeterli.
- Varsayilan English degerler gelistirme ve fallback icin yerinde duruyor.

## Son Kontrol Listesi

- Arapca font dosyalarinin bundle'a eklendigini dogrula.
- Transliteration datasini repository'ye bagla.
- Diyanet ve remote tafsir attribution/license metinlerini netlestir.
- Premium feature gating'i mevcut entitlement servisinden besle.
- Reader ayarlarini cihazda ac-kapat test et:
  - appearance
  - font
  - compact mode
  - keep screen awake
  - remember last position
- Audio aktifken mini player, scroll restore ve toolbar gizlenmesi akisini QA et.
