import Foundation

enum LegalContent {
    private static let dataControllerName = "Sabahattin Ali YÜCEL"

    static func document(
        for type: LegalDocumentType,
        languageCode: String = RabiaAppLanguage.currentCode()
    ) -> LegalDocument {
        let language = AppLanguage(code: languageCode)
        let template = templates[type] ?? LegalDocumentTemplate(version: nil, lastUpdated: Date(), sections: [])

        return LegalDocument(
            type: type,
            title: L10n.string(type.titleKey),
            version: template.version,
            lastUpdated: template.lastUpdated,
            sections: template.sections.map { section in
                LegalSection(
                    id: section.id,
                    heading: section.heading.resolve(for: language),
                    paragraphs: section.paragraphs.map { $0.resolve(for: language) }
                )
            }
        )
    }

    private static let templates: [LegalDocumentType: LegalDocumentTemplate] = [
        .kvkk: LegalDocumentTemplate(
            version: "1.1",
            lastUpdated: legalDate(year: 2026, month: 3, day: 17),
            sections: [
                section(
                    id: "controller",
                    trHeading: "Veri Sorumlusu ve Kapsam",
                    enHeading: "Data Controller and Scope",
                    trParagraphs: [
                        "\(AppName.short) mobil uygulaması kapsamında işlenen kişisel verilere ilişkin bu aydınlatma metni, 6698 sayılı Kişisel Verilerin Korunması Kanunu’nun 10. maddesi uyarınca hazırlanmıştır.",
                        "Bu metin bakımından veri sorumlusu, \(AppName.short) uygulamasının yayın ve işletim süreçlerinden sorumlu kişi olan \(dataControllerName)’dir. Veri koruma talepleri ve başvurular için temel iletişim kanalı \(LegalLinks.supportEmail) adresidir."
                    ],
                    enParagraphs: [
                        "This information notice has been prepared under Article 10 of Turkish Personal Data Protection Law No. 6698 for personal data processed within the scope of the \(AppName.short) mobile application.",
                        "For the purposes of this notice, the data controller is \(dataControllerName), the person responsible for the publication and operation of the \(AppName.short) application. The main contact channel for data protection requests is \(LegalLinks.supportEmail)."
                    ]
                ),
                section(
                    id: "categories",
                    trHeading: "İşlenen Veri Kategorileri",
                    enHeading: "Categories of Personal Data Processed",
                    trParagraphs: [
                        "Uygulamanın kullanım şekline göre kimlik ve hesap verileri, e-posta adresi, kullanıcı adı, Apple veya Google ile oturum açma bilgilerine ilişkin sınırlı kimlik doğrulama kayıtları, cihaz ve uygulama sürümü bilgileri, hata ve teknik log kayıtları işlenebilir.",
                        "Namaz vakitleri, kıble, hatırlatıcılar ve kişiselleştirme özellikleri kullanıldığında yaklaşık veya kesin konum verileri, bildirim tercihleri, seçilen dil, tema ve kullanım ayarları işlenebilir. Premium, bulut yedekleme ve yapay zekâ destekli özelliklerin kullanılması halinde abonelik durumu, iCloud senkronizasyon kayıtları ve kullanıcının ilgili alanlara yazdığı içerikler de işleme konusu olabilir.",
                        "Ödeme kartı verileri uygulama tarafından doğrudan tutulmaz; uygulama içi satın alma süreçleri Apple App Store ve ilgili ödeme altyapıları üzerinden yürütülür."
                    ],
                    enParagraphs: [
                        "Depending on how the application is used, identity and account data, email address, username, limited authentication logs related to Sign in with Apple or Google, device and app version information, and error or technical logs may be processed.",
                        "When prayer times, qibla, reminders, and personalization features are used, approximate or precise location data, notification preferences, selected language, theme, and usage settings may also be processed. If premium, cloud backup, or AI-assisted features are used, subscription status, iCloud sync records, and content entered by the user in related fields may also be processed.",
                        "Payment card data is not stored directly by the application; in-app purchase processes are handled through Apple App Store and related payment infrastructures."
                    ]
                ),
                section(
                    id: "collection-method",
                    trHeading: "Toplama Yöntemleri",
                    enHeading: "Methods of Collection",
                    trParagraphs: [
                        "Kişisel veriler; kullanıcı tarafından doğrudan girilen bilgiler, cihaz üzerinden verilen izinler, uygulama içi tercihler, oturum açma sağlayıcıları, Apple sistem servisleri, push bildirim servisleri, bulut senkronizasyon mekanizmaları ve uygulamanın güvenli şekilde çalışması için oluşan teknik kayıtlar aracılığıyla elektronik ortamda toplanabilir.",
                        "Bazı veriler doğrudan ilgili kişiden; bazı veriler ise Apple, Google, Firebase kimlik doğrulama servisleri, abonelik altyapısı sağlayıcıları veya işletim sistemi servisleri gibi üçüncü taraf teknik altyapılardan elde edilebilir."
                    ],
                    enParagraphs: [
                        "Personal data may be collected electronically through information entered directly by the user, permissions granted on the device, in-app preferences, sign-in providers, Apple system services, push notification services, cloud sync mechanisms, and technical records created for the secure functioning of the application.",
                        "Some data is obtained directly from the data subject, while some may be obtained from third-party technical infrastructures such as Apple, Google, Firebase authentication services, subscription infrastructure providers, or operating system services."
                    ]
                ),
                section(
                    id: "purposes",
                    trHeading: "İşleme Amaçları",
                    enHeading: "Purposes of Processing",
                    trParagraphs: [
                        "Kişisel veriler; kullanıcı hesabının oluşturulması ve yönetilmesi, oturum açma işlemlerinin yürütülmesi, zikir/dua geçmişi ve tercihlerin korunması, bulut yedekleme ve geri yükleme işlemlerinin sağlanması, premium haklarının doğrulanması ve uygulama deneyiminin kişiselleştirilmesi amaçlarıyla işlenebilir.",
                        "Ayrıca namaz vakti, kıble ve bildirim özelliklerinin çalıştırılması, güvenlik ve suistimal önleme kontrollerinin yürütülmesi, teknik hataların tespiti ve giderilmesi, destek taleplerinin cevaplanması, yapay zekâ destekli özelliklerin sunulması ve mevzuattan doğan yükümlülüklerin yerine getirilmesi için işleme yapılabilir."
                    ],
                    enParagraphs: [
                        "Personal data may be processed to create and manage the user account, run sign-in flows, preserve dhikr or dua history and preferences, enable cloud backup and restore, verify premium entitlements, and personalize the application experience.",
                        "Processing may also take place to operate prayer time, qibla, and notification features, perform security and abuse-prevention checks, detect and resolve technical issues, respond to support requests, provide AI-assisted features, and comply with legal obligations."
                    ]
                ),
                section(
                    id: "legal-bases",
                    trHeading: "Hukuki Sebepler",
                    enHeading: "Legal Bases",
                    trParagraphs: [
                        "Kişisel veriler; bir sözleşmenin kurulması veya ifasıyla doğrudan ilgili olması, veri sorumlusunun hukuki yükümlülüklerini yerine getirmesi, bir hakkın tesisi, kullanılması veya korunması, veri sorumlusunun meşru menfaatleri ve gerektiği hallerde açık rıza hukuki sebeplerine dayanılarak işlenebilir.",
                        "Konum, bildirim, bulut yedekleme ya da üçüncü taraf oturum açma gibi belirli fonksiyonlar bakımından kullanıcıya cihaz veya uygulama düzeyinde tercih ve izin sunulabilir; ilgili özelliğin kapatılması belirli işlevleri sınırlayabilir."
                    ],
                    enParagraphs: [
                        "Personal data may be processed on legal bases such as necessity for the establishment or performance of a contract, compliance with legal obligations, establishment, exercise or protection of a right, legitimate interests of the data controller, and explicit consent where required.",
                        "For certain functions such as location, notifications, cloud backup, or third-party sign-in, the user may be offered permissions and preferences at device or app level; disabling the relevant feature may limit certain functionalities."
                    ]
                ),
                section(
                    id: "transfers",
                    trHeading: "Aktarım ve Yurt Dışına Veri Aktarımı",
                    enHeading: "Transfers and International Data Transfers",
                    trParagraphs: [
                        "Kişisel veriler; uygulamanın güvenli ve sürekli şekilde işletilebilmesi amacıyla kimlik doğrulama, barındırma, bildirim, abonelik yönetimi, yapay zekâ altyapısı, teknik destek ve bulut yedekleme hizmeti sunan tedarikçilere, işleme amacıyla sınırlı olmak üzere aktarılabilir.",
                        "Kullanılan servis sağlayıcıların bir kısmı yurt dışında bulunabilir veya verileri yurt dışındaki sunucularda işleyebilir. Bu durumda aktarım süreçleri, yürürlükteki KVKK düzenlemeleri, özellikle 6698 sayılı Kanun’un 9. maddesi ve uygulanabilir güvenceler çerçevesinde yürütülür."
                    ],
                    enParagraphs: [
                        "Personal data may be transferred, limited to the relevant processing purpose, to suppliers providing authentication, hosting, notifications, subscription management, AI infrastructure, technical support, and cloud backup services required for the secure and continuous operation of the application.",
                        "Some service providers used by the application may be located abroad or may process data on servers outside Turkey. In such cases, transfer processes are handled in accordance with applicable Turkish data protection rules, especially Article 9 of Law No. 6698 and relevant safeguards."
                    ]
                ),
                section(
                    id: "retention",
                    trHeading: "Saklama Süresi ve İmha",
                    enHeading: "Retention and Disposal",
                    trParagraphs: [
                        "Kişisel veriler, ilgili işleme amacının gerektirdiği süre boyunca ve tabi olunan yasal saklama yükümlülükleri ölçüsünde muhafaza edilir. Hesap kapatma, abonelik sona ermesi veya kullanıcının belirli verileri silmesi talepleri değerlendirilirken teknik kayıtlar, yedekler ve mevzuat gereği saklanması gereken veriler bakımından makul saklama süreleri uygulanabilir.",
                        "Saklama süresi sona eren veriler, niteliğine göre silinir, yok edilir veya anonim hale getirilir."
                    ],
                    enParagraphs: [
                        "Personal data is retained for as long as required by the relevant processing purpose and to the extent necessary under applicable legal retention obligations. When account closure, subscription end, or user deletion requests are evaluated, reasonable retention periods may still apply for technical logs, backups, and data that must be retained under law.",
                        "Once the retention period ends, data is deleted, destroyed, or anonymized depending on its nature."
                    ]
                ),
                section(
                    id: "rights",
                    trHeading: "İlgili Kişi Hakları ve Başvuru Usulü",
                    enHeading: "Data Subject Rights and Application Procedure",
                    trParagraphs: [
                        "İlgili kişiler, KVKK’nın 11. maddesi kapsamında kişisel verilerinin işlenip işlenmediğini öğrenme, işlenmişse buna ilişkin bilgi talep etme, işleme amacını ve amaca uygun kullanılıp kullanılmadığını öğrenme, yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme, eksik veya yanlış işlenmiş olması halinde düzeltilmesini isteme ve şartları varsa silme veya yok edilmesini talep etme haklarına sahiptir.",
                        "Ayrıca yapılan düzeltme, silme veya yok etme işlemlerinin verilerin aktarıldığı üçüncü kişilere bildirilmesini isteme, işlenen verilerin münhasıran otomatik sistemler aracılığıyla analiz edilmesi sebebiyle aleyhe bir sonucun ortaya çıkmasına itiraz etme ve kanuna aykırı işleme sebebiyle zarara uğranması halinde zararın giderilmesini talep etme hakları da bulunmaktadır.",
                        "Başvurular, kimliği doğrulanabilir şekilde \(LegalLinks.supportEmail) adresine iletilebilir. Başvurular, niteliğine göre KVKK ve ikincil düzenlemelerde öngörülen süreler içinde değerlendirilir."
                    ],
                    enParagraphs: [
                        "Under Article 11 of the KVKK, data subjects have the right to learn whether their personal data is processed, request information if it has been processed, learn the purpose of processing and whether it is used accordingly, know the third parties to whom data is transferred domestically or abroad, request correction if data is incomplete or inaccurate, and request deletion or destruction where conditions are met.",
                        "They also have the right to request notification of correction, deletion, or destruction to third parties receiving the data, object to adverse consequences arising exclusively from automated analysis, and claim compensation if they suffer damage due to unlawful processing.",
                        "Applications may be sent to \(LegalLinks.supportEmail) in a manner that allows identity verification. Requests are assessed within the periods required by Turkish data protection rules and secondary legislation."
                    ]
                )
            ]
        ),
        .termsOfUse: LegalDocumentTemplate(
            version: "1.1",
            lastUpdated: legalDate(year: 2026, month: 3, day: 17),
            sections: [
                section(
                    id: "acceptance",
                    trHeading: "Kabul ve Kapsam",
                    enHeading: "Acceptance and Scope",
                    trParagraphs: [
                        "\(AppName.short) uygulamasını indirmeniz, hesap oluşturarak veya misafir olarak kullanmanız, uygulama içi satın alma yapmanız ya da uygulama içindeki hizmetlerden yararlanmanız, işbu kullanım şartlarını kabul ettiğiniz anlamına gelir.",
                        "Bu şartlar; ücretsiz özellikler, premium abonelikler, yapay zekâ destekli alanlar, içerik görüntüleme, bildirimler, bulut yedekleme ve hesap yönetimi dahil olmak üzere uygulama içinde sunulan tüm dijital hizmetler bakımından uygulanır."
                    ],
                    enParagraphs: [
                        "By downloading \(AppName.short), using it with an account or as a guest, making in-app purchases, or benefiting from services within the app, you accept these terms of use.",
                        "These terms apply to all digital services offered within the app, including free features, premium subscriptions, AI-assisted areas, content viewing, notifications, cloud backup, and account management."
                    ]
                ),
                section(
                    id: "service-description",
                    trHeading: "Hizmetin Niteliği",
                    enHeading: "Nature of the Service",
                    trParagraphs: [
                        "Uygulama; dua, zikir, tesbihat, kıble ve namaz vakitleri gibi ibadet destekleyici araçlar, kişisel takip özellikleri, içerik arşivi ve bazı alanlarda yapay zekâ destekli yanıtlar sunabilir.",
                        "Uygulamadaki bazı özellikler internet bağlantısı, cihaz izinleri, Apple veya üçüncü taraf servisler, aktif abonelik ya da kullanıcı hesabı gerektirebilir. Belirli özelliklerin her zaman, her cihazda ve kesintisiz şekilde çalışacağı garanti edilmez."
                    ],
                    enParagraphs: [
                        "The application may offer worship-supporting tools such as dua, dhikr, tasbihat, qibla, and prayer times, as well as personal tracking features, content archives, and AI-assisted responses in certain areas.",
                        "Some features may require internet access, device permissions, Apple or third-party services, an active subscription, or a user account. It is not guaranteed that every feature will operate at all times, on every device, or without interruption."
                    ]
                ),
                section(
                    id: "informational-disclaimer",
                    trHeading: "Bilgilendirme ve Sorumluluk Sınırı",
                    enHeading: "Information Disclaimer and Limitation",
                    trParagraphs: [
                        "Uygulama içinde yer alan içerikler genel bilgilendirme ve kişisel kullanım amacı taşır. Yapay zekâ tarafından oluşturulan yanıtlar ile özetler; bağlayıcı dini görüş, fetva, hukuki mütalaa, tıbbi tavsiye, psikolojik destek veya profesyonel danışmanlık yerine geçmez.",
                        "Kullanıcı, dini, hukuki, mali, sağlık veya kişisel sonuç doğurabilecek önemli konularda yalnızca uygulama içeriğine dayanarak karar vermemeli; gerekli hallerde yetkili kurumlara veya ehil uzmanlara başvurmalıdır."
                    ],
                    enParagraphs: [
                        "Content within the application is intended for general information and personal use. AI-generated responses and summaries do not replace binding religious opinions, fatwas, legal advice, medical advice, psychological support, or professional consultation.",
                        "Users should not make important decisions with religious, legal, financial, health, or personal consequences solely based on app content and should consult competent authorities or qualified professionals where necessary."
                    ]
                ),
                section(
                    id: "official-sources",
                    trHeading: "Resmî ve Referans İçerikler",
                    enHeading: "Official and Reference Content",
                    trParagraphs: [
                        "Uygulamadaki bazı metinler, kamuya açık resmî kaynaklardan veya güvenilir referanslardan derlenebilir ya da özetlenebilir. Bu durumda uygun görülen yerlerde kaynak niteliği ayrıca belirtilir.",
                        "Buna rağmen resmî kurum metninin güncel ve bağlayıcı hali ilgili kurumun kendi yayınıdır. Kullanıcı, kesin dayanak gereken durumlarda asli kaynağı kontrol etmekle sorumludur."
                    ],
                    enParagraphs: [
                        "Some texts within the application may be compiled or summarized from publicly available official sources or reliable references. Where appropriate, the source nature of that content is also indicated.",
                        "Even so, the current and binding version of any official institutional text remains the publication issued by the relevant authority. Users are responsible for checking the primary source where a definitive basis is required."
                    ]
                ),
                section(
                    id: "user-obligations",
                    trHeading: "Kullanıcı Yükümlülükleri",
                    enHeading: "User Obligations",
                    trParagraphs: [
                        "Kullanıcı; uygulamayı hukuka, genel ahlaka, kamu düzenine ve uygulamanın amacına uygun şekilde kullanmakla yükümlüdür. Hesap güvenliği, giriş bilgilerinin korunması ve cihaz erişiminin kontrolü kullanıcı sorumluluğundadır.",
                        "Uygulama üzerinden hukuka aykırı içerik yüklenmesi, başkalarının haklarını ihlal eden kullanım, servisleri kötüye kullanma, teknik sistemleri aşmaya çalışma, otomatik veri çekme veya ticari amaçla izinsiz çoğaltma ve dağıtım yasaktır."
                    ],
                    enParagraphs: [
                        "The user must use the application in compliance with the law, public order, general morals, and the intended purpose of the application. Account security, protection of login credentials, and control over device access are the user’s responsibility.",
                        "Uploading unlawful content, using the app in a way that violates the rights of others, abusing services, attempting to bypass technical systems, scraping data automatically, or reproducing and distributing content for commercial purposes without permission is prohibited."
                    ]
                ),
                section(
                    id: "subscriptions",
                    trHeading: "Premium, Abonelik ve Dijital Hizmetler",
                    enHeading: "Premium, Subscription, and Digital Services",
                    trParagraphs: [
                        "Premium üyelikler ve uygulama içi dijital hizmetler Apple App Store altyapısı üzerinden sunulabilir. Fiyatlandırma, yenileme, faturalandırma, iptal ve iade süreçleri bakımından App Store kuralları ile uygulanabilir tüketici mevzuatı birlikte dikkate alınır.",
                        "Kullanıcının satın alma öncesi gösterilen abonelik koşullarını ve App Store tarafında sunulan sözleşme ile bilgilendirmeleri ayrıca incelemesi gerekir. Dijital içerik ve anında ifa edilen hizmetler bakımından, işlemin niteliğine göre cayma hakkına ilişkin istisnalar gündeme gelebilir."
                    ],
                    enParagraphs: [
                        "Premium memberships and in-app digital services may be offered through the Apple App Store infrastructure. Pricing, renewal, billing, cancellation, and refund matters are subject both to App Store rules and to applicable consumer law.",
                        "Users should also review the subscription terms shown before purchase and the contractual disclosures provided through the App Store. For digital content and services performed instantly, exceptions to withdrawal rights may apply depending on the nature of the transaction."
                    ]
                ),
                section(
                    id: "intellectual-property",
                    trHeading: "Fikri Mülkiyet",
                    enHeading: "Intellectual Property",
                    trParagraphs: [
                        "Uygulamanın yazılımı, tasarımı, veri düzeni, markasal unsurları, özgün metinleri ve hukuken korunan diğer bileşenleri, aksi açıkça belirtilmedikçe uygulama işletmecisine veya ilgili hak sahiplerine aittir.",
                        "Kullanıcıya, uygulamayı kişisel ve sınırlı kullanım amacıyla geri alınabilir, devredilemez ve münhasır olmayan bir kullanım hakkı tanınır; bu hak mülkiyet devri anlamına gelmez."
                    ],
                    enParagraphs: [
                        "The software, design, data arrangement, branding elements, original texts, and other legally protected components of the application belong to the app operator or relevant rights holders unless expressly stated otherwise.",
                        "The user is granted a revocable, non-transferable, non-exclusive right to use the application for personal and limited purposes; this does not constitute a transfer of ownership."
                    ]
                ),
                section(
                    id: "termination",
                    trHeading: "Hizmetin Değiştirilmesi ve Hesabın Sona Erdirilmesi",
                    enHeading: "Changes to the Service and Termination",
                    trParagraphs: [
                        "Uygulama sahibi; güvenlik, teknik ihtiyaç, mevzuata uyum, ürün geliştirme veya ticari gerekçelerle uygulamanın tamamında ya da belirli özelliklerinde değişiklik yapabilir, bazı özellikleri durdurabilir veya yeniden yapılandırabilir.",
                        "Kullanım şartlarının ihlali, güvenlik riski, suistimal şüphesi veya yasal zorunluluk bulunması halinde hesabın veya belirli özelliklerin erişimi geçici olarak sınırlandırılabilir ya da sona erdirilebilir."
                    ],
                    enParagraphs: [
                        "The app owner may modify, suspend, or restructure all or part of the application for reasons including security, technical needs, legal compliance, product development, or commercial reasons.",
                        "Access to an account or certain features may be temporarily restricted or terminated in case of breach of these terms, security risk, suspected abuse, or legal necessity."
                    ]
                ),
                section(
                    id: "applicable-law",
                    trHeading: "Uygulanacak Hukuk ve Tüketici Hakları",
                    enHeading: "Applicable Law and Consumer Rights",
                    trParagraphs: [
                        "İşbu kullanım şartları, Türk hukuku esas alınarak yorumlanır. Uygulamanın bir tüketici işlemi oluşturduğu hallerde, kullanıcının 6502 sayılı Tüketicinin Korunması Hakkında Kanun ve ilgili ikincil mevzuattan doğan emredici hakları saklıdır.",
                        "Uyuşmazlık halinde, uygulanabilir parasal sınırlar ve görev kuralları çerçevesinde tüketici hakem heyetleri, tüketici mahkemeleri ve diğer yetkili mercilere başvuru hakkı devam eder."
                    ],
                    enParagraphs: [
                        "These terms are interpreted primarily under Turkish law. Where use of the application constitutes a consumer transaction, the user’s mandatory rights arising from Turkish Consumer Protection Law No. 6502 and related secondary legislation remain reserved.",
                        "In the event of a dispute, the right to apply to consumer arbitration committees, consumer courts, and other competent authorities continues subject to the applicable monetary thresholds and jurisdiction rules."
                    ]
                )
            ]
        ),
        .privacyPolicy: LegalDocumentTemplate(
            version: "1.2",
            lastUpdated: legalDate(year: 2026, month: 3, day: 19),
            sections: [
                section(
                    id: "principle",
                    trHeading: "Genel Yaklaşım",
                    enHeading: "General Approach",
                    trParagraphs: [
                        "\(AppName.short), kullanıcı gizliliğini temel ürün ilkelerinden biri olarak ele alır. Kişisel verilerin işlenmesinde ölçülülük, belirli amaç, veri minimizasyonu ve güvenlik yaklaşımı esas alınır.",
                        "Bu politika, uygulamanın veri işleme yaklaşımını daha anlaşılır bir dille özetlemek amacıyla hazırlanmıştır; KVKK aydınlatma metni ile birlikte değerlendirilmelidir."
                    ],
                    enParagraphs: [
                        "\(AppName.short) treats user privacy as a core product principle. Proportionality, specific purpose, data minimization, and security form the basis of personal data processing.",
                        "This policy is intended to summarize the application’s data processing approach in clearer language and should be read together with the KVKK information notice."
                    ]
                ),
                section(
                    id: "what-we-collect",
                    trHeading: "Hangi Verileri Neden Kullanırız?",
                    enHeading: "What Data Do We Use and Why?",
                    trParagraphs: [
                        "Hesap açma ve oturum yönetimi için e-posta, kullanıcı adı ve üçüncü taraf oturum açma kayıtları; kişiselleştirme için dil, tema ve uygulama tercihleri; bildirimler için izin ve hatırlatıcı ayarları; namaz vakitleri ve kıble gibi özellikler için konum verileri işlenebilir.",
                        "Premium ve yedekleme özellikleri kullanıldığında abonelik durumu, iCloud eşitleme kayıtları ve ilgili yedek veriler; yapay zekâ destekli alanlar kullanıldığında kullanıcının ilgili alana yazdığı metinler ve istek bağlamı işlenebilir."
                    ],
                    enParagraphs: [
                        "Email, username, and third-party sign-in records may be used for account creation and session management; language, theme, and app preferences for personalization; permission and reminder settings for notifications; and location data for features such as prayer times and qibla.",
                        "If premium and backup features are used, subscription status, iCloud sync records, and related backup data may be processed; if AI-assisted areas are used, text entered by the user and the request context may also be processed."
                    ]
                ),
                section(
                    id: "minimization",
                    trHeading: "Veri Minimizasyonu",
                    enHeading: "Data Minimization",
                    trParagraphs: [
                        "Uygulama, hizmetin sunulması için gerekli olmayan kişisel verileri toplamamayı hedefler. Her özellik için yalnızca ilgili işlevin makul şekilde çalışması için gereken veri kategorilerinin işlenmesi amaçlanır.",
                        "Kullanıcı tarafından girilen serbest metin alanlarında paylaşılan içeriklerin niteliği kullanıcının kendi tercihine bağlıdır; gerekli olmayan hassas veya özel bilgilerin paylaşılmaması tavsiye edilir."
                    ],
                    enParagraphs: [
                        "The application aims not to collect personal data that is unnecessary for providing the service. For each feature, only the data categories reasonably required for that function are intended to be processed.",
                        "The nature of information entered into free-form text fields is under the user’s control; users are advised not to share sensitive or unnecessary personal information."
                    ]
                ),
                section(
                    id: "third-parties",
                    trHeading: "Üçüncü Taraf Servisler",
                    enHeading: "Third-Party Services",
                    trParagraphs: [
                        "Uygulama; kimlik doğrulama, bildirim, abonelik doğrulama, cihaz altyapısı, bulut yedekleme, hata yönetimi, yapay zekâ desteği ve benzeri teknik amaçlarla Apple, Google, Firebase, RevenueCat, iCloud ve benzeri üçüncü taraf servislerden yararlanabilir.",
                        "Bu servislerin kendi gizlilik politikaları ve veri işleme koşulları ayrıca uygulanabilir. Üçüncü taraf servis kullanımı, ilgili özelliğin teknik olarak çalışması için gerekli olabilir.",
                        "Uygulama kapsamında kullanıcı verisi alan üçüncü taraflardan, bu politikada açıklanan koruma düzeyiyle aynı veya eşdeğer kullanıcı verisi koruması sağlamaları ve verileri yalnızca ilgili hizmet amacıyla işlemeleri beklenir."
                    ],
                    enParagraphs: [
                        "The application may rely on third-party services such as Apple, Google, Firebase, RevenueCat, iCloud, and similar providers for authentication, notifications, subscription verification, device infrastructure, cloud backup, error management, AI support, and comparable technical purposes.",
                        "These services may also apply their own privacy policies and processing terms. Using a third-party service may be technically necessary for the relevant feature to function.",
                        "Any third party receiving user data through the application is expected to provide the same or equal protection of user data as described in this policy and to process that data only for the relevant service purpose."
                    ]
                ),
                section(
                    id: "security",
                    trHeading: "Güvenlik",
                    enHeading: "Security",
                    trParagraphs: [
                        "Verilerin gizliliğinin ve bütünlüğünün korunması amacıyla makul teknik ve idari tedbirler alınır. Yetkisiz erişim, kötüye kullanım, ifşa, kayıp veya değişiklik riskini azaltmaya yönelik önlemler sürekli gözden geçirilir.",
                        "Buna rağmen internet, mobil cihaz ve bulut altyapılarının doğası gereği hiçbir sistem için mutlak güvenlik garantisi verilemez."
                    ],
                    enParagraphs: [
                        "Reasonable technical and administrative measures are taken to protect the confidentiality and integrity of data. Measures aimed at reducing the risk of unauthorized access, misuse, disclosure, loss, or alteration are reviewed on an ongoing basis.",
                        "Even so, no system can provide absolute security due to the nature of the internet, mobile devices, and cloud infrastructures."
                    ]
                ),
                section(
                    id: "retention",
                    trHeading: "Saklama Süreleri",
                    enHeading: "Retention Periods",
                    trParagraphs: [
                        "Veriler, ilgili özelliğin çalışması, hesabın sürdürülmesi, teknik kayıtların yönetimi, yedekleme süreçleri ve hukuki yükümlülükler için gerekli olduğu süre kadar saklanır.",
                        "Kullanıcının hesap silme veya belirli verilerin kaldırılmasını talep etmesi halinde, teknik olarak hemen silinemeyen yedekler veya mevzuat gereği korunması gereken kayıtlar bir süre daha muhafaza edilebilir.",
                        "Kullanıcı; konum, bildirim, kamera, fotoğraf, yedekleme veya üçüncü taraf oturum açma gibi isteğe bağlı izinleri ve özellikleri cihaz ya da uygulama ayarlarından kapatarak rızasını geri çekebilir. Ayrıca uygulama içinden hesap silme akışını kullanabilir veya \(LegalLinks.supportEmail) üzerinden veri silme talebi iletebilir."
                    ],
                    enParagraphs: [
                        "Data is retained for as long as needed to operate the relevant feature, maintain the account, manage technical logs, support backup processes, and comply with legal obligations.",
                        "If the user requests account deletion or removal of specific data, backups that cannot be removed immediately for technical reasons or records that must be retained by law may be preserved for an additional period.",
                        "Users may withdraw consent for optional permissions and features such as location, notifications, camera, photos, backups, or third-party sign-in by disabling the relevant setting. They may also use the in-app account deletion flow or contact \(LegalLinks.supportEmail) to request deletion of their data."
                    ]
                ),
                section(
                    id: "children",
                    trHeading: "Çocukların Gizliliği",
                    enHeading: "Children’s Privacy",
                    trParagraphs: [
                        "Uygulama genel kullanıcı kitlesine yöneliktir. Çocuklara ilişkin veri işleme söz konusu olduğunda, uygulanabilir hukuki yükümlülükler ve ebeveyn/kanuni temsilci onayı gereklilikleri ayrıca dikkate alınmalıdır.",
                        "Bir çocuğa ait kişisel verilerin uygun olmayan şekilde işlendiği düşünülüyorsa \(LegalLinks.supportEmail) üzerinden iletişime geçilebilir."
                    ],
                    enParagraphs: [
                        "The application is designed for a general audience. Where the processing of children’s data is involved, applicable legal obligations and parental or guardian consent requirements must also be taken into account.",
                        "If you believe that personal data belonging to a child has been processed inappropriately, you may contact \(LegalLinks.supportEmail)."
                    ]
                ),
                section(
                    id: "changes",
                    trHeading: "Politika Değişiklikleri",
                    enHeading: "Policy Changes",
                    trParagraphs: [
                        "Bu politika, ürün geliştirme ihtiyaçları, servis sağlayıcı değişiklikleri, uygulama özelliklerindeki güncellemeler veya mevzuata uyum gerekçeleriyle zaman zaman güncellenebilir.",
                        "Güncel metin uygulama içinde yayımlandığı tarihten itibaren geçerli olur. Önemli değişikliklerde kullanıcıya uygulama içi bildirim veya başka uygun yollarla bilgilendirme yapılabilir."
                    ],
                    enParagraphs: [
                        "This policy may be updated from time to time due to product development needs, changes in service providers, feature updates, or legal compliance requirements.",
                        "The current text becomes effective from the date it is published within the application. In the event of significant changes, users may be informed through in-app notices or other appropriate means."
                    ]
                )
            ]
        )
    ]

    private static func section(
        id: String,
        trHeading: String,
        enHeading: String,
        trParagraphs: [String],
        enParagraphs: [String]
    ) -> LegalSectionTemplate {
        LegalSectionTemplate(
            id: id,
            heading: localized(trHeading, enHeading),
            paragraphs: zip(trParagraphs, enParagraphs).map { localized($0.0, $0.1) }
        )
    }

    private static func localized(_ tr: String, _ en: String) -> LegalLocalizedText {
        LegalLocalizedText([
            .tr: tr,
            .en: en
        ])
    }

    private static func legalDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }
}

private struct LegalDocumentTemplate {
    let version: String?
    let lastUpdated: Date
    let sections: [LegalSectionTemplate]
}

private struct LegalSectionTemplate {
    let id: String
    let heading: LegalLocalizedText
    let paragraphs: [LegalLocalizedText]
}

private struct LegalLocalizedText {
    let values: [AppLanguage: String]

    init(_ values: [AppLanguage: String]) {
        self.values = values
    }

    func resolve(for language: AppLanguage) -> String {
        values[language] ?? values[.en] ?? values[.tr] ?? ""
    }
}
