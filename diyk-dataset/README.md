# diyk-dataset

Din İşleri Yüksek Kurulu'nun kamuya açık resmi içeriklerini taramak, ayrıştırmak, normalize etmek ve sürümlenebilir veri seti olarak dışa aktarmak için üretim odaklı Node.js/TypeScript projesi.

Bu proje özellikle şu içerik sınıflarını hedefler:

- Resmi soru-cevap sayfaları
- Sıkça sorulan sorular / öne çıkan kamuya açık içerikler
- Karar sayfaları
- Mütalaa sayfaları

Ürün notu:

> official public content is exported with source attribution and without altering official wording

## Amaç

Mobil uygulama içinde resmi kaynak tabanı olarak kullanılabilecek temiz, izlenebilir ve tekrar üretilebilir bir JSONL veri kümesi oluşturmak.

Temel ilkeler:

- Resmi metin yeniden yazılmaz
- Kaynak URL ve alan adı korunur
- Ham HTML ve temiz metin birlikte saklanır
- Uygulama tarafından sonradan üretilecek açıklama alanları, resmi metinden ayrı tutulur
- Crawl durumu SQLite ile izlenir; yeniden çalıştırma güvenlidir

## Teknoloji

- Node.js 20+
- TypeScript
- pnpm
- Playwright
- Cheerio
- Zod
- Pino
- Better-SQLite3

## Kurulum

```bash
corepack enable
corepack pnpm install
```

## Ortam Değişkenleri

`.env.example` dosyasını `.env` olarak çoğaltıp gerekirse düzenleyin.

Desteklenen değişkenler:

- `START_URLS`
- `MAX_CONCURRENCY`
- `REQUEST_DELAY_MS`
- `USE_PLAYWRIGHT`
- `OUTPUT_DIR`
- `USER_AGENT`
- `RESPECT_ROBOTS`
- `FETCH_TIMEOUT_MS`
- `MAX_RETRIES`
- `LOG_LEVEL`

Varsayılan başlangıç URL'leri:

- `https://kurul.diyanet.gov.tr/Dini-Soru-Cevap-Arama`
- `https://kurul.diyanet.gov.tr/DiyanetSikcaTiklananlarSorular`
- `https://kurul.diyanet.gov.tr/Karar-Mutalaa-Cevap`

## Komutlar

```bash
corepack pnpm crawl
corepack pnpm parse
corepack pnpm export
corepack pnpm publish:remote
corepack pnpm refresh
corepack pnpm doctor
```

Akış sırası:

1. `pnpm crawl`
2. `pnpm parse`
3. `pnpm export`
4. `pnpm publish:remote`

## Remote Yayın Akışı

Uygulamanın yeni Diyanet içeriklerini app update olmadan alabilmesi için export çıktıları manifest tabanlı remote bundle olarak hazırlanabilir.

Hazırlanan ana dosyalar:

- `diyk-dataset-payload.json`
- `diyk-manifest.json`
- `diyk-summary.json`
- `diyk-dataset.jsonl`
- `diyk-dataset.csv`

Yayın hazırlığı:

```bash
OUTPUT_DIR=data-full corepack pnpm export
DIYK_OUTPUT_DIR=data-full corepack pnpm publish:remote
```

İsteğe bağlı ortam değişkenleri:

- `DIYK_PUBLISH_DIR`
- `DIYK_PUBLISH_BASE_URL`

Varsayılan çıktı:

- `diyk-dataset/published/diyanet/latest/`
- `diyk-dataset/published/diyanet/versions/<dataset-version>/`

Mobil uygulama tarafında:

- `DIYKDatasetManifestURL` alanına `latest/diyk-manifest.json` URL'i verilir
- uygulama önce manifest'i okur
- manifest değişmişse payload dosyasını indirir
- hash doğrulaması yapıp cache'e yazar
- remote erişilemezse bundle/cache fallback kullanır

## Mimari

### 1. Discovery

- Seed URL'ler kuyruklanır
- `robots.txt` okunur
- Mümkünse sitemap ipuçları değerlendirilir
- Liste ve konu sayfalarındaki linkler çıkarılır
- URL'ler `qa`, `faq`, `karar`, `mutalaa`, `unknown` olarak tahminlenir
- Her URL SQLite durum tablosuna yazılır

### 2. Fetch

- Önce hafif HTTP fetch denenir
- Güvenlik sayfası / engel / eksik içerik algılanırsa Playwright fallback devreye girer
- Ham HTML `data/raw/` altına tarih bazlı snapshot olarak yazılır
- Yanına fetch metadata JSON dosyası bırakılır
- Non-HTML ve binary içerikler atlanır

Not:

Hedef sitenin düz HTTP isteklerine güvenlik duvarı sayfası döndürme ihtimali bulunduğundan `USE_PLAYWRIGHT=true` varsayılan olarak daha güvenlidir.

### 3. Parse

- Breadcrumb
- Başlık
- Soru
- Cevap HTML
- Cevap metni
- Karar/Mütalaa metadata alanları

katmanlı fallback stratejisiyle çıkarılır.

Seçiciler merkezi config içinde tutulur; yalnızca tekil kırılgan selector'lara dayanılmaz.

### 4. Normalize

- Unicode normalize edilir
- HTML entity çözülür
- Gereksiz whitespace temizlenir
- Bilinen boilerplate satırları kaldırılır
- Arama anahtar kelimeleri üretilir
- `content_hash` hesaplanır
- Şüpheli kısa / kirli sonuçlar `low_confidence=true` ile işaretlenir
- `Kayıt Bulunamadı` ve benzeri bozuk içerikler reddedilir

### 5. Export

Üretilen dosyalar:

- `data/exports/diyk-dataset.jsonl`
- `data/exports/diyk-summary.json`
- `data/exports/diyk-dataset.csv`
- `data/exports/diyk-rejected.jsonl`
- `data/exports/diyk-crawl-report.json`

## SQLite Durum Yönetimi

Ana tablo:

- `urls`

Ek izleme tabloları:

- `fetch_runs`
- `parse_runs`
- `export_runs`
- `errors`

Tutulan önemli alanlar:

- `status`
- `page_type_guess`
- `retry_count`
- `last_error`
- `canonical_url`
- `fetch_content_hash`
- `record_content_hash`
- `raw_path`
- `discovery_processed_at`

Bu sayede süreç çökse bile kaldığı yerden devam eder.

## Refresh Stratejisi

`pnpm refresh` şu işi yapar:

- Bilinen URL'leri yeniden ziyaret eder
- Ham içerik hash'i değişmemiş kayıtları atlar
- Değişen kayıtları tekrar fetch eder
- Yalnızca değişen detail kayıtlarını yeniden parse eder
- Sonra export'u günceller

## Veri Modeli

Ana accepted record alanları:

- `id`
- `type`
- `title`
- `title_clean`
- `question`
- `question_clean`
- `answer_html`
- `answer_text`
- `answer_text_clean`
- `category_path`
- `tags`
- `source_name`
- `source_url`
- `source_domain`
- `language`
- `is_official`
- `content_hash`
- `search_keywords`
- `search_document`
- `discovered_at`
- `fetched_at`
- `parsed_at`
- `decision_kind`
- `decision_year`
- `decision_no`
- `subject`

## Örnek JSONL Kayıtı

```json
{
  "id": "diyk_qa_1106",
  "type": "qa",
  "title": "Dua ederken tevessül caiz midir?",
  "title_clean": "Dua ederken tevessül caiz midir?",
  "question": "Dua ederken tevessül caiz midir?",
  "question_clean": "Dua ederken tevessül caiz midir?",
  "answer_html": "<p>Dua ibadeti yalnız Allah'a yapılır.</p>",
  "answer_text": "Dua ibadeti yalnız Allah'a yapılır.",
  "answer_text_clean": "Dua ibadeti yalnız Allah'a yapılır.",
  "category_path": ["İNANÇ", "DUA"],
  "tags": ["İNANÇ", "DUA", "dua", "tevessül", "caiz", "midir"],
  "source_name": "Din İşleri Yüksek Kurulu",
  "source_url": "https://kurul.diyanet.gov.tr/soru/1106/dua-ederken-tevessul-caiz-midir",
  "source_domain": "kurul.diyanet.gov.tr",
  "language": "tr",
  "is_official": true,
  "content_hash": "sha256:...",
  "search_keywords": ["dua", "tevessül", "caiz", "midir"],
  "search_document": "Başlık: Dua ederken tevessül caiz midir? Soru: Dua ederken tevessül caiz midir? Cevap: Dua ibadeti yalnız Allah'a yapılır. Kategori: İNANÇ > DUA",
  "discovered_at": "2026-03-16T00:00:00.000Z",
  "fetched_at": "2026-03-16T00:00:01.000Z",
  "parsed_at": "2026-03-16T00:00:02.000Z",
  "canonical_identifier": "1106",
  "low_confidence": false,
  "decision_kind": null,
  "decision_year": null,
  "decision_no": null,
  "subject": null
}
```

## Testler

```bash
corepack pnpm test
corepack pnpm typecheck
```

Kapsanan ana başlıklar:

- Türkçe unicode normalize etme
- Boilerplate temizleme
- Geçersiz sayfa tespiti
- QA parser fixture
- Karar fixture
- Mütalaa fixture
- Hash kararlılığı
- Stable ID üretimi

## Hukuki / Ürün Notu

Bu proje yalnızca kamuya açık resmi içeriği, kaynak atfını koruyarak ve resmi ifadeyi değiştirmeden dışa aktarmak için tasarlanmıştır. İçerik üzerinde teolojik yorum veya yeniden yazım yapılmaz.
