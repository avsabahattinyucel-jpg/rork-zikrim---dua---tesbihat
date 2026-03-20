# Zikrim Hisnul Muslim Dua Content System

## Mimari Özet

Bu sistem, **Hisnul Muslim duasını kaynak odaklı JSON veri seti** olarak saklar, çok dilli çıktı üretir, doğrulama durumunu açıkça taşır ve aynı içeriği hem **Vercel/Node API** tarafına hem de **SwiftUI Guide** tarafına besler.

Temel yaklaşım:

- Kaynak veri `content/` altında tutulur.
- Doğrulama, normalize etme ve export işlemleri `scripts/` altında çalışır.
- TypeScript API ve yardımcı katman `src/` altında yer alır.
- iOS tarafı, export edilen `ZikrimDuaVeTesbihat/Data/hisnul_muslim_guide_bundle.json` dosyasını okuyarak Guide içinde Hisnul Muslim içeriklerini gösterir.

## Dizin Yapısı

```text
/content
  /duas
    hisnul-muslim.json
  /categories
    dua-categories.json
  /guides
    guide-tabs.json
    guide-category-mapping.json
  /translations
    /tr/guide-bundle.json
    /en/guide-bundle.json
    /ar/guide-bundle.json
    ...
  /validation
    schema.json

/scripts
  parseHisnulMuslim.ts
  normalizeDuaDataset.ts
  validateDuaDataset.ts
  enrichDuaExplanations.ts
  exportLocalizedBundles.ts

/src
  /types
    dua.ts
    http.ts
  /lib
    constants.ts
    language.ts
    fallback.ts
    verification.ts
    search.ts
    explanations.ts
    content-store.ts
  /api
    duas.ts
    duaById.ts
    featuredDuas.ts
    duaCategories.ts
    searchDuas.ts

/api
  duas.ts
  /duas/[id].ts
  featured-duas.ts
  dua-categories.ts
  search-duas.ts

/ZikrimDuaVeTesbihat
  /Models
    GuideContentModels.swift
  /Services
    GuideContentStore.swift
  /Data
    hisnul_muslim_guide_bundle.json
    guide_tabs.json
    guide_category_mapping.json
```

## Dini Güvenlik Kuralları

Bu katman özellikle aşağıdaki güvenlik çizgilerini korumak için tasarlandı:

- Yeni dua metni üretilmez.
- Arapça dua metni yalnızca veri kaynağından gelir.
- Açıklama katmanı dua metnini yeniden yazmaz.
- Kaynak belirsizse `verification.status = "needs_review"` veya `"unknown"` kullanılır.
- Güçlü isnad/doğrulama iddiası, editoryal teyit olmadan gösterilmez.
- Kullanıcıya “kesin garanti”, “kesin emir”, “şu sonucu mutlaka verir” gibi ifadeler sunulmaz.

Kod içi üretim rehberi:

- `src/lib/explanations.ts` içindeki prompt şablonu yalnızca anlam, bağlam ve manevi tema için kullanılmalıdır.
- “Do not hallucinate isnad/source.”
- “Do not rewrite Arabic text without source verification.”

## Çok Dilli Davranış

Dil zinciri:

1. İstenen dil
2. İngilizce
3. Arapça

Transliterasyon zinciri:

1. İstenen dil transliterasyonu
2. İngilizce transliterasyon
3. Türkçe transliterasyon

İlgili yardımcılar:

- `resolveLanguageFallback`
- `getLocalizedField`
- `getLocalizedDua`

## Guide Entegrasyonu

Hisnul Muslim veri seti backend’de ayrı kalmaz; Guide içine şu şekilde eklenir:

- `content/guides/guide-category-mapping.json` dua kategori kimliklerini mevcut Guide sekmelerine bağlar.
- `scripts/exportLocalizedBundles.ts` iOS bundle dosyasını üretir.
- `GuideContentStore.swift` bu bundle’ı okur ve `RehberEntry` nesnelerine dönüştürür.
- `HisnulMuslimData.swift` artık sabit Swift listesi yerine JSON export’unu kullanır.
- `ZikirRehberiView.swift` kaynak etiketi ve doğrulama rozeti gösterecek şekilde genişletildi.

Mevcut Guide sekmelerine yapılan örnek eşlemeler:

- `morning_evening_adhkar` -> `gunluk_rutinler`
- `sleep_duas` -> `gunluk_rutinler`
- `daily_life` -> `hayat_durumlari`
- `forgiveness` -> `hayat_durumlari`
- `difficult_times` -> `duygusal_durumlar`

Bu yaklaşım **mevcut Guide navigasyonunu bozmadan** Hisnul Muslim içeriklerini doğru sekmelere taşır.

## API Uçları

- `GET /api/duas`
- `GET /api/duas/:id`
- `GET /api/featured-duas`
- `GET /api/dua-categories`
- `GET /api/search-duas?q=...`

Tüm cevaplar:

- normalize JSON döner,
- fallback metadata içerir,
- verification bloklarını taşır,
- mobil tüketim için cache header ekler.

## Komutlar

```bash
npm run normalize:duas
npm run validate:duas
npm run export:duas
npm run typecheck
```

## Editöryal Akış

Önerilen üretim akışı:

1. Ham kaynak `parseHisnulMuslim.ts` ile içeri alınır.
2. İçerik editörü kategori ve kaynak alanlarını gözden geçirir.
3. Açıklama taslakları güvenli prompt ile üretilir.
4. `enrichDuaExplanations.ts` ile veri setine işlenir.
5. `validateDuaDataset.ts` kritik hatalarda build’i durdurur.
6. `exportLocalizedBundles.ts` hem API hem iOS bundle çıktısını üretir.

## Migration Notları

- Swift tarafında eski `HisnulMuslimData.swift` sabit listesi kaldırıldı.
- Guide ekranı mevcut enum/kategori mantığını korur; ancak Hisnul Muslim içerikleri artık JSON export’tan gelir.
- İleride Guide tam anlamıyla dinamik sekmelere taşınmak istenirse `GuideContentModels.swift` ve `guide-tabs.json` doğrudan genişletilebilir.
- Şu anki örnek veri seti 5 dua ile sınırlıdır; uzman incelemesi sonrası binlerce kayda ölçeklenebilir.
