import Foundation

struct IslamicWorkCompletionQuote: Equatable {
    let text: String
    let reference: String
}

enum IslamicWorkCompletionQuotePool {
    static let quotes: [IslamicWorkCompletionQuote] = [
        IslamicWorkCompletionQuote(
            text: "Insan icin ancak calistiginin karsiligi vardir.",
            reference: "Necm 53:39"
        ),
        IslamicWorkCompletionQuote(
            text: "Bir isi bitirdiginde hemen diger hayirli ise koyul.",
            reference: "Insirah 94:7"
        ),
        IslamicWorkCompletionQuote(
            text: "Calisin; Allah, Resulu ve muminler yaptiklarinizi gorecektir.",
            reference: "Tevbe 9:105"
        ),
        IslamicWorkCompletionQuote(
            text: "Allah, hanginizin daha guzel amel yapacagini sinamak icin hayati ve olumu yaratandir.",
            reference: "Mulk 67:2"
        ),
        IslamicWorkCompletionQuote(
            text: "Allah'a en sevimli gelen amel, az da olsa devamli olandir.",
            reference: "Sahih al-Bukhari 6465"
        ),
        IslamicWorkCompletionQuote(
            text: "Sana fayda verene yonel, Allah'tan yardim iste ve gevseme.",
            reference: "Sahih Muslim 2664"
        )
    ]

    static func quote(for date: Date = Date(), calendar: Calendar = .current) -> IslamicWorkCompletionQuote {
        guard !quotes.isEmpty else {
            return IslamicWorkCompletionQuote(
                text: "Allah'a en sevimli gelen amel, az da olsa devamli olandir.",
                reference: "Sahih al-Bukhari 6465"
            )
        }

        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let index = abs((year * 37 + dayOfYear) % quotes.count)
        return quotes[index]
    }
}
