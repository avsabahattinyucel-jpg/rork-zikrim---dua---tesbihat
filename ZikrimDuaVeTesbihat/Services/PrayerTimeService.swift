import Foundation
import CoreLocation
import WidgetKit

@Observable
@MainActor
class PrayerTimeService: NSObject, CLLocationManagerDelegate {
    var prayerTimes: PrayerTimes?
    var isLoading: Bool = false
    var errorMessage: String?
    var selectedCity: TurkishCity = TurkishCities.all.first { $0.id == "istanbul" } ?? TurkishCities.all[0]
    var hijriDate: String = ""
    var gregorianWeekday: String = ""

    private let cacheKeyPrefix = "prayer_times_"
    private let selectedCityKey = "selected_prayer_city"
    private let didAutoDetectCityKey = "did_auto_detect_city"
    private let locationManager: CLLocationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        loadSelectedCity()
        loadCachedTimes()
    }

    func fetchPrayerTimes() async {
        isLoading = true
        errorMessage = nil

        let today = todayString()
        let cacheKey = "\(cacheKeyPrefix)\(selectedCity.id)_\(today)"

        if let cached = loadCached(key: cacheKey) {
            prayerTimes = cached
            isLoading = false
            return
        }

        let urlString = "https://api.aladhan.com/v1/timingsByCity/\(today)?city=\(selectedCity.englishName)&country=Turkey&method=13"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else {
            isLoading = false
            errorMessage = "Geçersiz URL"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(AladhanResponse.self, from: data)
            let timings = response.data.timings
            let times = PrayerTimes(
                fajr: String(timings.Fajr.prefix(5)),
                sunrise: String(timings.Sunrise.prefix(5)),
                dhuhr: String(timings.Dhuhr.prefix(5)),
                asr: String(timings.Asr.prefix(5)),
                maghrib: String(timings.Maghrib.prefix(5)),
                isha: String(timings.Isha.prefix(5)),
                date: today,
                city: selectedCity.name
            )
            prayerTimes = times
            hijriDate = "\(response.data.date.hijri.day) \(response.data.date.hijri.month.ar) \(response.data.date.hijri.year)"
            gregorianWeekday = turkishWeekday(response.data.date.gregorian.weekday.en)
            cacheData(times, key: cacheKey)
            UserDefaults.standard.set(nextPrayer()?.name ?? "", forKey: "widget_next_prayer_name")
            UserDefaults.standard.set(nextPrayer()?.time ?? "", forKey: "widget_next_prayer_time")
            UserDefaults.standard.set(selectedCity.name, forKey: "widget_next_prayer_city")
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = "Namaz vakitleri alınamadı. Lütfen internet bağlantınızı kontrol edin."
            loadCachedTimes()
        }

        isLoading = false
    }

    func requestAutoDetectCityIfNeeded() {
        guard UserDefaults.standard.bool(forKey: didAutoDetectCityKey) == false else { return }
        UserDefaults.standard.set(true, forKey: didAutoDetectCityKey)
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func selectCity(_ city: TurkishCity) {
        selectedCity = city
        saveSelectedCity()
        prayerTimes = nil
        Task { await fetchPrayerTimes() }
    }

    func nextPrayer() -> (name: String, time: String, systemImage: String)? {
        guard let times = prayerTimes else { return nil }
        let now = Date()
        let calendar = Calendar.current
        let h = calendar.component(.hour, from: now)
        let m = calendar.component(.minute, from: now)
        let currentMinutes = h * 60 + m

        let prayers: [(String, String, String)] = [
            ("İmsak", times.fajr, "moon.stars.fill"),
            ("Güneş", times.sunrise, "sunrise.fill"),
            ("Öğle", times.dhuhr, "sun.max.fill"),
            ("İkindi", times.asr, "sun.haze.fill"),
            ("Akşam", times.maghrib, "sunset.fill"),
            ("Yatsı", times.isha, "moon.fill")
        ]

        for prayer in prayers {
            let parts = prayer.1.split(separator: ":").map { Int($0) ?? 0 }
            guard parts.count == 2 else { continue }
            let prayerMinutes = parts[0] * 60 + parts[1]
            if prayerMinutes > currentMinutes {
                return (name: prayer.0, time: prayer.1, systemImage: prayer.2)
            }
        }
        return (name: "İmsak", time: times.fajr, systemImage: "moon.stars.fill")
    }

    func minutesUntilNextPrayer() -> Int? {
        guard let next = nextPrayer() else { return nil }
        let now = Date()
        let calendar = Calendar.current
        let h = calendar.component(.hour, from: now)
        let m = calendar.component(.minute, from: now)
        let currentMinutes = h * 60 + m
        let parts = next.time.split(separator: ":").map { Int($0) ?? 0 }
        guard parts.count == 2 else { return nil }
        var prayerMinutes = parts[0] * 60 + parts[1]
        if prayerMinutes <= currentMinutes { prayerMinutes += 24 * 60 }
        return prayerMinutes - currentMinutes
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            let geocoder = CLGeocoder()
            if let place = try? await geocoder.reverseGeocodeLocation(location).first,
               let cityName = place.administrativeArea ?? place.locality,
               let city = TurkishCities.all.first(where: { $0.name.localizedCaseInsensitiveContains(cityName) || cityName.localizedCaseInsensitiveContains($0.name) }) {
                selectCity(city)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    private func loadCachedTimes() {
        let today = todayString()
        let cacheKey = "\(cacheKeyPrefix)\(selectedCity.id)_\(today)"
        if let cached = loadCached(key: cacheKey) {
            prayerTimes = cached
        }
    }

    private func cacheData(_ times: PrayerTimes, key: String) {
        if let data = try? JSONEncoder().encode(times) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadCached(key: String) -> PrayerTimes? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PrayerTimes.self, from: data)
    }

    private func saveSelectedCity() {
        UserDefaults.standard.set(selectedCity.id, forKey: selectedCityKey)
    }

    private func loadSelectedCity() {
        if let savedId = UserDefaults.standard.string(forKey: selectedCityKey),
           let city = TurkishCities.all.first(where: { $0.id == savedId }) {
            selectedCity = city
        }
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: Date())
    }

    private func turkishWeekday(_ en: String) -> String {
        switch en.lowercased() {
        case "monday": return "Pazartesi"
        case "tuesday": return "Salı"
        case "wednesday": return "Çarşamba"
        case "thursday": return "Perşembe"
        case "friday": return "Cuma"
        case "saturday": return "Cumartesi"
        case "sunday": return "Pazar"
        default: return en
        }
    }
}

enum TurkishCities {
    static let all: [TurkishCity] = [
        TurkishCity(id: "adana", name: "Adana", englishName: "Adana"),
        TurkishCity(id: "adiyaman", name: "Adıyaman", englishName: "Adiyaman"),
        TurkishCity(id: "afyonkarahisar", name: "Afyonkarahisar", englishName: "Afyonkarahisar"),
        TurkishCity(id: "agri", name: "Ağrı", englishName: "Agri"),
        TurkishCity(id: "amasya", name: "Amasya", englishName: "Amasya"),
        TurkishCity(id: "ankara", name: "Ankara", englishName: "Ankara"),
        TurkishCity(id: "antalya", name: "Antalya", englishName: "Antalya"),
        TurkishCity(id: "artvin", name: "Artvin", englishName: "Artvin"),
        TurkishCity(id: "aydin", name: "Aydın", englishName: "Aydin"),
        TurkishCity(id: "balikesir", name: "Balıkesir", englishName: "Balikesir"),
        TurkishCity(id: "bilecik", name: "Bilecik", englishName: "Bilecik"),
        TurkishCity(id: "bingol", name: "Bingöl", englishName: "Bingol"),
        TurkishCity(id: "bitlis", name: "Bitlis", englishName: "Bitlis"),
        TurkishCity(id: "bolu", name: "Bolu", englishName: "Bolu"),
        TurkishCity(id: "burdur", name: "Burdur", englishName: "Burdur"),
        TurkishCity(id: "bursa", name: "Bursa", englishName: "Bursa"),
        TurkishCity(id: "canakkale", name: "Çanakkale", englishName: "Canakkale"),
        TurkishCity(id: "cankiri", name: "Çankırı", englishName: "Cankiri"),
        TurkishCity(id: "corum", name: "Çorum", englishName: "Corum"),
        TurkishCity(id: "denizli", name: "Denizli", englishName: "Denizli"),
        TurkishCity(id: "diyarbakir", name: "Diyarbakır", englishName: "Diyarbakir"),
        TurkishCity(id: "edirne", name: "Edirne", englishName: "Edirne"),
        TurkishCity(id: "elazig", name: "Elazığ", englishName: "Elazig"),
        TurkishCity(id: "erzincan", name: "Erzincan", englishName: "Erzincan"),
        TurkishCity(id: "erzurum", name: "Erzurum", englishName: "Erzurum"),
        TurkishCity(id: "eskisehir", name: "Eskişehir", englishName: "Eskisehir"),
        TurkishCity(id: "gaziantep", name: "Gaziantep", englishName: "Gaziantep"),
        TurkishCity(id: "giresun", name: "Giresun", englishName: "Giresun"),
        TurkishCity(id: "gumushane", name: "Gümüşhane", englishName: "Gumushane"),
        TurkishCity(id: "hakkari", name: "Hakkâri", englishName: "Hakkari"),
        TurkishCity(id: "hatay", name: "Hatay", englishName: "Hatay"),
        TurkishCity(id: "isparta", name: "Isparta", englishName: "Isparta"),
        TurkishCity(id: "mersin", name: "Mersin", englishName: "Mersin"),
        TurkishCity(id: "istanbul", name: "İstanbul", englishName: "Istanbul"),
        TurkishCity(id: "izmir", name: "İzmir", englishName: "Izmir"),
        TurkishCity(id: "kars", name: "Kars", englishName: "Kars"),
        TurkishCity(id: "kastamonu", name: "Kastamonu", englishName: "Kastamonu"),
        TurkishCity(id: "kayseri", name: "Kayseri", englishName: "Kayseri"),
        TurkishCity(id: "kirklareli", name: "Kırklareli", englishName: "Kirklareli"),
        TurkishCity(id: "kirsehir", name: "Kırşehir", englishName: "Kirsehir"),
        TurkishCity(id: "kocaeli", name: "Kocaeli", englishName: "Kocaeli"),
        TurkishCity(id: "konya", name: "Konya", englishName: "Konya"),
        TurkishCity(id: "kutahya", name: "Kütahya", englishName: "Kutahya"),
        TurkishCity(id: "malatya", name: "Malatya", englishName: "Malatya"),
        TurkishCity(id: "manisa", name: "Manisa", englishName: "Manisa"),
        TurkishCity(id: "kahramanmaras", name: "Kahramanmaraş", englishName: "Kahramanmaras"),
        TurkishCity(id: "mardin", name: "Mardin", englishName: "Mardin"),
        TurkishCity(id: "mugla", name: "Muğla", englishName: "Mugla"),
        TurkishCity(id: "mus", name: "Muş", englishName: "Mus"),
        TurkishCity(id: "nevsehir", name: "Nevşehir", englishName: "Nevsehir"),
        TurkishCity(id: "nigde", name: "Niğde", englishName: "Nigde"),
        TurkishCity(id: "ordu", name: "Ordu", englishName: "Ordu"),
        TurkishCity(id: "rize", name: "Rize", englishName: "Rize"),
        TurkishCity(id: "sakarya", name: "Sakarya", englishName: "Sakarya"),
        TurkishCity(id: "samsun", name: "Samsun", englishName: "Samsun"),
        TurkishCity(id: "siirt", name: "Siirt", englishName: "Siirt"),
        TurkishCity(id: "sinop", name: "Sinop", englishName: "Sinop"),
        TurkishCity(id: "sivas", name: "Sivas", englishName: "Sivas"),
        TurkishCity(id: "tekirdag", name: "Tekirdağ", englishName: "Tekirdag"),
        TurkishCity(id: "tokat", name: "Tokat", englishName: "Tokat"),
        TurkishCity(id: "trabzon", name: "Trabzon", englishName: "Trabzon"),
        TurkishCity(id: "tunceli", name: "Tunceli", englishName: "Tunceli"),
        TurkishCity(id: "sanliurfa", name: "Şanlıurfa", englishName: "Sanliurfa"),
        TurkishCity(id: "usak", name: "Uşak", englishName: "Usak"),
        TurkishCity(id: "van", name: "Van", englishName: "Van"),
        TurkishCity(id: "yozgat", name: "Yozgat", englishName: "Yozgat"),
        TurkishCity(id: "zonguldak", name: "Zonguldak", englishName: "Zonguldak"),
        TurkishCity(id: "aksaray", name: "Aksaray", englishName: "Aksaray"),
        TurkishCity(id: "bayburt", name: "Bayburt", englishName: "Bayburt"),
        TurkishCity(id: "karaman", name: "Karaman", englishName: "Karaman"),
        TurkishCity(id: "kirikkale", name: "Kırıkkale", englishName: "Kirikkale"),
        TurkishCity(id: "batman", name: "Batman", englishName: "Batman"),
        TurkishCity(id: "sirnak", name: "Şırnak", englishName: "Sirnak"),
        TurkishCity(id: "bartin", name: "Bartın", englishName: "Bartin"),
        TurkishCity(id: "ardahan", name: "Ardahan", englishName: "Ardahan"),
        TurkishCity(id: "igdir", name: "Iğdır", englishName: "Igdir"),
        TurkishCity(id: "yalova", name: "Yalova", englishName: "Yalova"),
        TurkishCity(id: "karabuk", name: "Karabük", englishName: "Karabuk"),
        TurkishCity(id: "kilis", name: "Kilis", englishName: "Kilis"),
        TurkishCity(id: "osmaniye", name: "Osmaniye", englishName: "Osmaniye"),
        TurkishCity(id: "duzce", name: "Düzce", englishName: "Duzce")
    ]
}
