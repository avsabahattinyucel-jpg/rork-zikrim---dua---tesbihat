# Diyanet Rehber Mimarisi

Bu doküman, Din İşleri Yüksek Kurulu veri setinin Zikrim uygulamasına nasıl yerleştirileceğini özetler.

## Neden Rehber?

Diyanet soru-cevap, karar ve mütalaa içerikleri:

- ibadet akışının parçası değil
- resmi kaynak referansı niteliğinde
- arama ve okuma davranışına daha yakın

Bu yüzden en doğal yer `Rehber` sekmesi içindeki ayrı bir modüldür.

## Bilgi Mimarisi

Önerilen akış:

1. `Rehber`
2. `Diyanet Kaynakları`
3. `Liste / Arama`
4. `Detay`

Detay ekranı iki ana bloğa ayrılmalı:

- `Resmi Metin`
- `Uygulama Açıklaması`

Bu iki alan aynı görsel blokta karıştırılmamalı.

## Uygulama Katmanları

### 1. Dataset Katmanı

Kaynak:

- bundle içindeki snapshot JSON
- manifest tabanlı remote refresh
- cache fallback

İçerik:

- yalnızca resmi metin
- kaynak URL
- kategori
- karar/mütalaa metadata
- arama alanları

### 2. Domain Katmanı

Ana tipler:

- `DiyanetKnowledgeRecord`
- `DiyanetKnowledgeSection`
- `DiyanetKnowledgePayload`

Bu katman uygulamadaki diğer `RehberEntry` modellerinden ayrı tutulmalı; çünkü veri semantiği farklı.

### 3. Presentation Katmanı

İlk aşamada:

- `Rehber` içinde giriş kartı
- `DiyanetKnowledgeHubView`
- boş durum / kaynak özeti / bölüm kartları

İkinci aşamada:

- liste ekranı
- filtreler: `Soru-Cevap`, `SSS`, `Karar`, `Mütalaa`
- tam metin arama

Üçüncü aşamada:

- detay ekranı
- kaynak açma
- favorileme / son okunanlar

## Önerilen Dosya Yapısı

- `ZikrimDuaVeTesbihat/Models/DiyanetKnowledgeModels.swift`
- `ZikrimDuaVeTesbihat/Services/DiyanetKnowledgeStore.swift`
- `ZikrimDuaVeTesbihat/Views/DiyanetKnowledgeHubView.swift`
- `ZikrimDuaVeTesbihat/Data/diyanet_official_dataset.json`

## Kademeli Yol Haritası

### Adım 1

- Rehber içine resmi kaynaklar girişini ekle
- boş dataset ile çalışan hub ekranı oluştur

### Adım 2

- gerçek export edilmiş dataset JSON’unu bundle’a al
- liste + arama ekranını bağla

### Adım 3

- detay ekranında resmi metin + kaynak alanını göster

### Adım 4

- opsiyonel açıklama / özet katmanını resmi metinden ayrı blokta sun

## Remote Güncelleme

Dataset artık şu mantıkla çalışabilir:

1. uygulama önce bundle veya cache içindeki resmi paketi açar
2. sonra `DIYKDatasetManifestURL` üzerinden küçük manifest dosyasını kontrol eder
3. versiyon değişmişse payload dosyasını indirir
4. hash doğrulaması yapar
5. cache'i günceller

Önerilen yayın URL yapısı:

- `.../diyanet/latest/diyk-manifest.json`
- `.../diyanet/latest/diyk-dataset-payload.json`
- `.../diyanet/versions/<dataset-version>/...`

Bu repo için GitHub Pages akışı hazırlanmıştır.

## UI İlkeleri

- “fetva veriyor” hissi vermemeli
- resmi metin görsel olarak nötr ve güven veren biçimde sunulmalı
- kaynak atfı açık olmalı
- kullanıcı resmi metni uygulama yorumundan kolayca ayırabilmeli
