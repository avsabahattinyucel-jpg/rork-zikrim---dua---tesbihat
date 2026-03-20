import Foundation

enum ZikirData {
    static let categories: [ZikirCategory] = [
        ZikirCategory(
            id: "sabah_zikirleri",
            name: "Sabah Zikirleri",
            icon: "sunrise.fill",
            items: [
                ZikirItem(id: "sabah_1", category: "sabah_zikirleri", arabicText: "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ", turkishPronunciation: "Eûzü billâhi mineş-şeytânir-racîm", turkishMeaning: "Kovulmuş şeytandan Allah'a sığınırım", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "sabah_2", category: "sabah_zikirleri", arabicText: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ", turkishPronunciation: "Bismillâhir-rahmânir-rahîm", turkishMeaning: "Rahman ve Rahim olan Allah'ın adıyla", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "sabah_3", category: "sabah_zikirleri", arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ", turkishPronunciation: "Asbahnâ ve asbahal-mülkü lillâhi vel-hamdü lillâh", turkishMeaning: "Sabaha erdik, mülk de Allah'ın olarak sabaha erdi. Hamd Allah'a mahsustur", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "sabah_4", category: "sabah_zikirleri", arabicText: "اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ", turkishPronunciation: "Allâhümme bike asbahnâ ve bike emseynâ ve bike nahyâ ve bike nemûtü ve ileyken-nüşûr", turkishMeaning: "Allah'ım! Senin sayende sabahladık, senin sayende akşamladık, senin sayende yaşar, senin sayende ölürüz. Dönüş sanadır", recommendedCount: 1, source: "Tirmizi"),
                ZikirItem(id: "sabah_5", category: "sabah_zikirleri", arabicText: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ", turkishPronunciation: "Allâhümme ente rabbî lâ ilâhe illâ ente halaktenî ve ene abdüke", turkishMeaning: "Allah'ım! Sen Rabbimsin. Senden başka ilah yoktur. Beni Sen yarattın, ben Senin kulunum", recommendedCount: 1, source: "Buhari"),
                ZikirItem(id: "sabah_6", category: "sabah_zikirleri", arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ", turkishPronunciation: "Sübhânallâhi ve bihamdihî", turkishMeaning: "Allah'ı hamd ile tesbih ederim", recommendedCount: 100, source: "Müslim"),
                ZikirItem(id: "sabah_7", category: "sabah_zikirleri", arabicText: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ", turkishPronunciation: "Lâ ilâhe illallâhü vahdehû lâ şerîke leh lehül-mülkü ve lehül-hamdü ve hüve alâ külli şey'in kadîr", turkishMeaning: "Allah'tan başka ilah yoktur, O tektir, ortağı yoktur. Mülk O'nundur, hamd O'nadır ve O her şeye kadirdir", recommendedCount: 10, source: "Buhari, Müslim"),
                ZikirItem(id: "sabah_8", category: "sabah_zikirleri", arabicText: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ", turkishPronunciation: "Eûzü bi-kelimâtillâhit-tâmmâti min şerri mâ halak", turkishMeaning: "Yarattıklarının şerrinden Allah'ın eksiksiz kelimelerine sığınırım", recommendedCount: 3, source: "Müslim"),
                ZikirItem(id: "sabah_9", category: "sabah_zikirleri", arabicText: "اللَّهُمَّ عَافِنِي فِي بَدَنِي اللَّهُمَّ عَافِنِي فِي سَمْعِي اللَّهُمَّ عَافِنِي فِي بَصَرِي", turkishPronunciation: "Allâhümme âfinî fî bedenî, allâhümme âfinî fî sem'î, allâhümme âfinî fî basarî", turkishMeaning: "Allah'ım bedenime afiyet ver, Allah'ım işitmeme afiyet ver, Allah'ım görmeme afiyet ver", recommendedCount: 3, source: "Ebu Davud"),
                ZikirItem(id: "sabah_10", category: "sabah_zikirleri", arabicText: "رَضِيتُ بِاللَّهِ رَبًّا وَبِالْإِسْلَامِ دِينًا وَبِمُحَمَّدٍ نَبِيًّا", turkishPronunciation: "Radîtü billâhi rabben ve bil-islâmi dînen ve bi-Muhammedin nebiyyâ", turkishMeaning: "Allah'ı Rabb, İslam'ı din ve Muhammed'i (s.a.v.) Peygamber olarak kabul ettim", recommendedCount: 3, source: "Ebu Davud, Tirmizi")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "aksam_zikirleri",
            name: "Akşam Zikirleri",
            icon: "sunset.fill",
            items: [
                ZikirItem(id: "aksam_1", category: "aksam_zikirleri", arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ", turkishPronunciation: "Emseynâ ve emsel-mülkü lillâhi vel-hamdü lillâh", turkishMeaning: "Akşama erdik, mülk de Allah'ın olarak akşama erdi. Hamd Allah'a mahsustur", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "aksam_2", category: "aksam_zikirleri", arabicText: "اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ", turkishPronunciation: "Allâhümme bike emseynâ ve bike asbahnâ ve bike nahyâ ve bike nemûtü ve ileykel-masîr", turkishMeaning: "Allah'ım! Senin sayende akşamladık, senin sayende sabahladık. Senin sayende yaşar, senin sayende ölürüz. Dönüş sanadır", recommendedCount: 1, source: "Tirmizi"),
                ZikirItem(id: "aksam_3", category: "aksam_zikirleri", arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ", turkishPronunciation: "Allâhümme innî es'elükel-âfiyete fid-dünyâ vel-âhirah", turkishMeaning: "Allah'ım! Senden dünya ve ahirette afiyet dilerim", recommendedCount: 1, source: "Ebu Davud"),
                ZikirItem(id: "aksam_4", category: "aksam_zikirleri", arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ شَرِّ مَا خَلَقْتَ", turkishPronunciation: "Allâhümme innî eûzü bike min şerri mâ halakte", turkishMeaning: "Allah'ım! Yarattığın şeylerin şerrinden sana sığınırım", recommendedCount: 3, source: "Müslim"),
                ZikirItem(id: "aksam_5", category: "aksam_zikirleri", arabicText: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ", turkishPronunciation: "Bismillâhillezî lâ yedurru measmihî şey'ün fil-erdı ve lâ fis-semâi ve hüves-semîul-alîm", turkishMeaning: "Allah'ın adıyla ki O'nun adı anılınca yerde ve gökte hiçbir şey zarar veremez. O, hakkıyla işiten ve bilendir", recommendedCount: 3, source: "Ebu Davud, Tirmizi"),
                ZikirItem(id: "aksam_6", category: "aksam_zikirleri", arabicText: "أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ", turkishPronunciation: "Estağfirullâhel-azîme ve etûbü ileyh", turkishMeaning: "Yüce Allah'tan bağışlanma diler, O'na tövbe ederim", recommendedCount: 3, source: "Buhari, Müslim"),
                ZikirItem(id: "aksam_7", category: "aksam_zikirleri", arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْكُفْرِ وَالْفَقْرِ وَأَعُوذُ بِكَ مِنْ عَذَابِ الْقَبْرِ", turkishPronunciation: "Allâhümme innî eûzü bike minel-küfri vel-fakri ve eûzü bike min azâbil-kabr", turkishMeaning: "Allah'ım küfürden ve fakirlikten sana sığınırım, kabir azabından sana sığınırım", recommendedCount: 3, source: "Nesai"),
                ZikirItem(id: "aksam_8", category: "aksam_zikirleri", arabicText: "اللَّهُمَّ اغْفِرْ لِي وَارْحَمْنِي وَتُبْ عَلَيَّ", turkishPronunciation: "Allâhümmağfir lî verhamnî ve tüb aleyye", turkishMeaning: "Allah'ım bağışla, merhamet et ve tövbemi kabul et", recommendedCount: 100, source: "Tirmizi")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "namaz_tesbihat",
            name: "Namaz Sonrası Tesbihat",
            icon: "hands.and.sparkles.fill",
            items: [
                ZikirItem(id: "tesbihat_1", category: "namaz_tesbihat", arabicText: "سُبْحَانَ اللَّهِ", turkishPronunciation: "Sübhânallâh", turkishMeaning: "Allah'ı tüm noksanlıklardan tenzih ederim", recommendedCount: 33, source: "Müslim"),
                ZikirItem(id: "tesbihat_2", category: "namaz_tesbihat", arabicText: "الْحَمْدُ لِلَّهِ", turkishPronunciation: "Elhamdülillâh", turkishMeaning: "Hamd Allah'a mahsustur", recommendedCount: 33, source: "Müslim"),
                ZikirItem(id: "tesbihat_3", category: "namaz_tesbihat", arabicText: "اللَّهُ أَكْبَرُ", turkishPronunciation: "Allâhu Ekber", turkishMeaning: "Allah en büyüktür", recommendedCount: 33, source: "Müslim"),
                ZikirItem(id: "tesbihat_4", category: "namaz_tesbihat", arabicText: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ", turkishPronunciation: "Lâ ilâhe illallâhü vahdehû lâ şerîke leh, lehül-mülkü ve lehül-hamdü ve hüve alâ külli şey'in kadîr", turkishMeaning: "Allah'tan başka ilah yoktur, O tektir, ortağı yoktur. Mülk O'nundur, hamd O'nadır ve O her şeye kadirdir", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "tesbihat_5", category: "namaz_tesbihat", arabicText: "اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ", turkishPronunciation: "Allâhümme entes-selâmü ve minkes-selâm, tebârekte yâ zel-celâli vel-ikrâm", turkishMeaning: "Allah'ım! Sen selamsın, selamet sendedir. Ey celal ve ikram sahibi, sen yücesin", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "tesbihat_6", category: "namaz_tesbihat", arabicText: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ", turkishPronunciation: "Allâhümme eınnî alâ zikrike ve şükrike ve hüsni ibâdetik", turkishMeaning: "Allah'ım! Seni zikretmek, sana şükretmek ve sana güzel ibadet etmek için bana yardım et", recommendedCount: 1, source: "Ebu Davud")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "esmaul_husna",
            name: "Esmaül Hüsna",
            icon: "star.fill",
            items: [
                ZikirItem(id: "esma_1", category: "esmaul_husna", arabicText: "اللَّهُ", turkishPronunciation: "Allah", turkishMeaning: "Bütün isim ve sıfatları kendinde toplayan, ibadete layık tek varlık", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_2", category: "esmaul_husna", arabicText: "الرَّحْمَنُ", turkishPronunciation: "Er-Rahmân", turkishMeaning: "Dünyada bütün yaratılmışlara merhamet eden", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_3", category: "esmaul_husna", arabicText: "الرَّحِيمُ", turkishPronunciation: "Er-Rahîm", turkishMeaning: "Ahirette yalnız müminlere merhamet eden", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_4", category: "esmaul_husna", arabicText: "الْمَلِكُ", turkishPronunciation: "El-Melik", turkishMeaning: "Mülkün gerçek sahibi, bütün kainatın hükümdarı", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_5", category: "esmaul_husna", arabicText: "الْقُدُّوسُ", turkishPronunciation: "El-Kuddûs", turkishMeaning: "Her türlü eksiklikten ve ayıptan uzak olan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_6", category: "esmaul_husna", arabicText: "السَّلَامُ", turkishPronunciation: "Es-Selâm", turkishMeaning: "Her türlü tehlikeden selamete çıkaran", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_7", category: "esmaul_husna", arabicText: "الْمُؤْمِنُ", turkishPronunciation: "El-Mü'min", turkishMeaning: "Güven veren, emin kılan, koruyan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_8", category: "esmaul_husna", arabicText: "الْمُهَيْمِنُ", turkishPronunciation: "El-Müheymin", turkishMeaning: "Her şeyi gözetip koruyan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_9", category: "esmaul_husna", arabicText: "الْعَزِيزُ", turkishPronunciation: "El-Azîz", turkishMeaning: "İzzet sahibi, mağlup edilmesi mümkün olmayan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_10", category: "esmaul_husna", arabicText: "الْجَبَّارُ", turkishPronunciation: "El-Cebbâr", turkishMeaning: "İstediğini mutlaka yapan, düzeltici", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_11", category: "esmaul_husna", arabicText: "الْمُتَكَبِّرُ", turkishPronunciation: "El-Mütekebbir", turkishMeaning: "Büyüklükte eşi olmayan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_12", category: "esmaul_husna", arabicText: "الْخَالِقُ", turkishPronunciation: "El-Hâlık", turkishMeaning: "Yoktan var eden, yaratan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_13", category: "esmaul_husna", arabicText: "الْبَارِئُ", turkishPronunciation: "El-Bâri", turkishMeaning: "Her şeyi kusursuz ve uyumlu yaratan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_14", category: "esmaul_husna", arabicText: "الْمُصَوِّرُ", turkishPronunciation: "El-Musavvir", turkishMeaning: "Her şeye şekil ve suret veren", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_15", category: "esmaul_husna", arabicText: "الْغَفَّارُ", turkishPronunciation: "El-Gaffâr", turkishMeaning: "Günahları çokça bağışlayan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_16", category: "esmaul_husna", arabicText: "الْقَهَّارُ", turkishPronunciation: "El-Kahhâr", turkishMeaning: "Her şeye galip gelen, kahreden", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_17", category: "esmaul_husna", arabicText: "الْوَهَّابُ", turkishPronunciation: "El-Vehhâb", turkishMeaning: "Karşılıksız bol bol veren", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_18", category: "esmaul_husna", arabicText: "الرَّزَّاقُ", turkishPronunciation: "Er-Rezzâk", turkishMeaning: "Bütün canlıların rızkını veren", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_19", category: "esmaul_husna", arabicText: "الْفَتَّاحُ", turkishPronunciation: "El-Fettâh", turkishMeaning: "Her türlü zorluğu açan ve kolaylaştıran", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_20", category: "esmaul_husna", arabicText: "الْعَلِيمُ", turkishPronunciation: "El-Alîm", turkishMeaning: "Her şeyi hakkıyla bilen", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_21", category: "esmaul_husna", arabicText: "الْقَابِضُ", turkishPronunciation: "El-Kâbid", turkishMeaning: "Dilediği şeyi tutan, daraltan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_22", category: "esmaul_husna", arabicText: "الْبَاسِطُ", turkishPronunciation: "El-Bâsit", turkishMeaning: "Dilediği şeyi açan, genişleten", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_23", category: "esmaul_husna", arabicText: "الرَّافِعُ", turkishPronunciation: "Er-Râfi", turkishMeaning: "Yükselten, şan ve şeref veren", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_24", category: "esmaul_husna", arabicText: "الْمُعِزُّ", turkishPronunciation: "El-Müizz", turkishMeaning: "İzzet ve şeref veren", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_25", category: "esmaul_husna", arabicText: "السَّمِيعُ", turkishPronunciation: "Es-Semî", turkishMeaning: "Her şeyi hakkıyla işiten", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_26", category: "esmaul_husna", arabicText: "الْبَصِيرُ", turkishPronunciation: "El-Basîr", turkishMeaning: "Her şeyi hakkıyla gören", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_27", category: "esmaul_husna", arabicText: "الْحَكَمُ", turkishPronunciation: "El-Hakem", turkishMeaning: "Hükmeden, hükümler koyup uygulayan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_28", category: "esmaul_husna", arabicText: "الْعَدْلُ", turkishPronunciation: "El-Adl", turkishMeaning: "Son derece adil olan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_29", category: "esmaul_husna", arabicText: "اللَّطِيفُ", turkishPronunciation: "El-Latîf", turkishMeaning: "En ince işleri bilen, lütufkâr olan", recommendedCount: 1, source: "Kur'an"),
                ZikirItem(id: "esma_30", category: "esmaul_husna", arabicText: "الْخَبِيرُ", turkishPronunciation: "El-Habîr", turkishMeaning: "Her şeyden haberdar olan", recommendedCount: 1, source: "Kur'an")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "koruyucu_dualar",
            name: "Koruyucu Dualar",
            icon: "shield.fill",
            items: [
                ZikirItem(id: "koruyucu_1", category: "koruyucu_dualar", arabicText: "قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ", turkishPronunciation: "Kul hüvallâhü ehad. Allâhüs-samed. Lem yelid ve lem yûled. Ve lem yekün lehû küfüven ehad", turkishMeaning: "De ki: O Allah birdir. Allah sameddir. Doğurmamış ve doğmamıştır. Hiçbir şey O'na denk değildir", recommendedCount: 3, source: "İhlas Suresi"),
                ZikirItem(id: "koruyucu_2", category: "koruyucu_dualar", arabicText: "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ", turkishPronunciation: "Kul eûzü bi-rabbil-felak. Min şerri mâ halak", turkishMeaning: "De ki: Sabahın Rabbine sığınırım. Yarattığı şeylerin şerrinden", recommendedCount: 3, source: "Felak Suresi"),
                ZikirItem(id: "koruyucu_3", category: "koruyucu_dualar", arabicText: "قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ", turkishPronunciation: "Kul eûzü bi-rabbin-nâs. Melikin-nâs. İlâhin-nâs", turkishMeaning: "De ki: İnsanların Rabbine, insanların Melikine, insanların İlahına sığınırım", recommendedCount: 3, source: "Nas Suresi"),
                ZikirItem(id: "koruyucu_4", category: "koruyucu_dualar", arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ", turkishPronunciation: "Allâhü lâ ilâhe illâ hüvel-hayyül-kayyûm lâ te'huzühû sinetün ve lâ nevm", turkishMeaning: "Allah, O'ndan başka ilah yoktur. O, Hayy ve Kayyum'dur. Onu ne uyuklama ne de uyku tutar", recommendedCount: 1, source: "Ayetel Kürsi - Bakara 255"),
                ZikirItem(id: "koruyucu_5", category: "koruyucu_dualar", arabicText: "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ", turkishPronunciation: "Hasbiyallâhü lâ ilâhe illâ hüve aleyhi tevekkeltü ve hüve rabbül-arşil-azîm", turkishMeaning: "Allah bana yeter, O'ndan başka ilah yoktur. O'na tevekkül ettim ve O büyük arşın Rabbidir", recommendedCount: 7, source: "Tevbe 129"),
                ZikirItem(id: "koruyucu_6", category: "koruyucu_dualar", arabicText: "لَا إِلَهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ", turkishPronunciation: "Lâ ilâhe illâ ente sübhâneke innî küntü minez-zâlimîn", turkishMeaning: "Senden başka ilah yoktur. Seni tenzih ederim. Şüphesiz ben zalimlerden oldum (dua-i Yunus)", recommendedCount: 40, source: "Enbiya 87")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "namaz_dualari",
            name: "Namaz Duaları",
            icon: "figure.stand",
            items: [
                ZikirItem(id: "namaz_1", category: "namaz_dualari", arabicText: "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ وَتَبَارَكَ اسْمُكَ وَتَعَالَى جَدُّكَ وَلَا إِلَهَ غَيْرُكَ", turkishPronunciation: "Sübhânekellâhümme ve bihamdike ve tebârekesmüke ve teâlâ ceddüke ve lâ ilâhe ğayrük", turkishMeaning: "Allah'ım! Seni her türlü noksanlıktan tenzih ederim. Sana hamd ederim. İsmin ne kadar mübarektir. Şanın ne kadar yücedir. Senden başka ilah yoktur", recommendedCount: 1, source: "İftitah Duası"),
                ZikirItem(id: "namaz_2", category: "namaz_dualari", arabicText: "اللَّهُمَّ بَاعِدْ بَيْنِي وَبَيْنَ خَطَايَايَ كَمَا بَاعَدْتَ بَيْنَ الْمَشْرِقِ وَالْمَغْرِبِ", turkishPronunciation: "Allâhümme bâid beynî ve beyne hatâyâye kemâ bâadette beynel-meşriki vel-mağrib", turkishMeaning: "Allah'ım doğu ile batı arasını ne kadar uzaklaştırdıysan, beni de günahlarımdan o kadar uzaklaştır", recommendedCount: 1, source: "Buhari, Müslim"),
                ZikirItem(id: "namaz_3", category: "namaz_dualari", arabicText: "رَبِّ اغْفِرْ لِي وَارْحَمْنِي وَاجْبُرْنِي وَارْفَعْنِي وَارْزُقْنِي وَاهْدِنِي وَعَافِنِي", turkishPronunciation: "Rabbığfir lî verhamnî vecbürnî verfa'nî verzuknî vehdinî ve âfinî", turkishMeaning: "Rabbim! Bağışla, merhamet et, eksiklerimi gider, yükselt, rızıklandır, hidayet et ve afiyet ver", recommendedCount: 1, source: "İbn Mace"),
                ZikirItem(id: "namaz_4", category: "namaz_dualari", arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ عَذَابِ جَهَنَّمَ وَمِنْ عَذَابِ الْقَبْرِ وَمِنْ فِتْنَةِ الْمَحْيَا وَالْمَمَاتِ وَمِنْ شَرِّ فِتْنَةِ الْمَسِيحِ الدَّجَّالِ", turkishPronunciation: "Allâhümme innî eûzü bike min azâbi cehennem, ve min azâbil-kabr, ve min fitnetil-mahyâ vel-memât, ve min şerri fitnetil-mesîhid-deccâl", turkishMeaning: "Allah'ım cehennem azabından, kabir azabından, hayat ve ölüm fitnesinden, Deccal fitnesinin şerrinden sana sığınırım", recommendedCount: 1, source: "Buhari, Müslim")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "peygamber_dualari",
            name: "Peygamber Duaları",
            icon: "moon.stars.fill",
            items: [
                ZikirItem(id: "pey_1", category: "peygamber_dualari", arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى", turkishPronunciation: "Allâhümme innî es'elükel-hüdâ vet-tükâ vel-afâfe vel-ğınâ", turkishMeaning: "Allah'ım! Senden hidayet, takva, iffet ve gönül zenginliği isterim", recommendedCount: 3, source: "Müslim"),
                ZikirItem(id: "pey_2", category: "peygamber_dualari", arabicText: "اللَّهُمَّ أَصْلِحْ لِي دِينِي الَّذِي هُوَ عِصْمَةُ أَمْرِي وَأَصْلِحْ لِي دُنْيَايَ الَّتِي فِيهَا مَعَاشِي", turkishPronunciation: "Allâhümme aslih lî dîniyellezî hüve ısmetü emrî ve aslih lî dünyâyelleti fîhâ meâşî", turkishMeaning: "Allah'ım! Benim için dünyadaki hayatımı ıslah et ve işlerimin güvencesi olan dinimi ıslah et", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "pey_3", category: "peygamber_dualari", arabicText: "اللَّهُمَّ اجْعَلْنِي مِنَ الَّذِينَ إِذَا أَحْسَنُوا اسْتَبْشَرُوا وَإِذَا أَسَاؤُوا اسْتَغْفَرُوا", turkishPronunciation: "Allâhümmec'alnî minellezîne izâ ahsenûs-tebşerû ve izâ esâûs-tağferû", turkishMeaning: "Allah'ım! İyi iş yapınca sevinenlerin ve kötülük yapınca istiğfar edenlerin arasına beni dahil et", recommendedCount: 1, source: "İbn Mace"),
                ZikirItem(id: "pey_4", category: "peygamber_dualari", arabicText: "اللَّهُمَّ آتِ نَفْسِي تَقْوَاهَا وَزَكِّهَا أَنْتَ خَيْرُ مَنْ زَكَّاهَا أَنْتَ وَلِيُّهَا وَمَوْلَاهَا", turkishPronunciation: "Allâhümme âti nefsî takvâhâ ve zekkihâ ente hayru men zekkâhâ ente veliyyühâ ve mevlâhâ", turkishMeaning: "Allah'ım! Nefsime takvayı ver ve onu temizle. Sen onu en iyi temizleyensin. Sen onun velisi ve mevlasısın", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "pey_5", category: "peygamber_dualari", arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِرِضَاكَ مِنْ سَخَطِكَ وَبِمُعَافَاتِكَ مِنْ عُقُوبَتِكَ", turkishPronunciation: "Allâhümme innî eûzü bi-ridâke min sahatike ve bi-muâfâtike min ukûbetik", turkishMeaning: "Allah'ım! Gazabından rızana, cezandan affına sığınırım", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "pey_6", category: "peygamber_dualari", arabicText: "يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ", turkishPronunciation: "Yâ mukallibel-kulûb sebbit kalbî alâ dînik", turkishMeaning: "Ey kalpleri evirip çeviren! Kalbimi dinin üzere sabit kıl", recommendedCount: 7, source: "Tirmizi")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "gunluk_hayat",
            name: "Günlük Hayat Duaları",
            icon: "house.fill",
            items: [
                ZikirItem(id: "gunluk_1", category: "gunluk_hayat", arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنْ يَوْمِ السُّوءِ", turkishPronunciation: "Allâhümme innî eûzü bike min yevmis-sû'", turkishMeaning: "Allah'ım! Kötü bir günden sana sığınırım", recommendedCount: 1, source: "İbn Mace"),
                ZikirItem(id: "gunluk_2", category: "gunluk_hayat", arabicText: "بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", turkishPronunciation: "Bismillâh tevekkeltü alallâh lâ havle ve lâ kuvvete illâ billâh", turkishMeaning: "Allah'ın adıyla, Allah'a tevekkül ettim. Güç ve kuvvet ancak Allah'tandır (evden çıkış duası)", recommendedCount: 1, source: "Tirmizi"),
                ZikirItem(id: "gunluk_3", category: "gunluk_hayat", arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْخُبُثِ وَالْخَبَائِثِ", turkishPronunciation: "Allâhümme innî eûzü bike minel-hubüsi vel-habâis", turkishMeaning: "Allah'ım! Erkek ve dişi şeytanlardan sana sığınırım (tuvalete girerken)", recommendedCount: 1, source: "Buhari, Müslim"),
                ZikirItem(id: "gunluk_4", category: "gunluk_hayat", arabicText: "اللَّهُمَّ بَارِكْ لَنَا فِيمَا رَزَقْتَنَا وَقِنَا عَذَابَ النَّارِ", turkishPronunciation: "Allâhümme bârik lenâ fîmâ rezaktenâ ve kınâ azâben-nâr", turkishMeaning: "Allah'ım! Bize rızık olarak verdiğinde bereket ver ve bizi cehennem azabından koru (yemek duası)", recommendedCount: 1, source: "İbn Sünni"),
                ZikirItem(id: "gunluk_5", category: "gunluk_hayat", arabicText: "اللَّهُمَّ أَنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا", turkishPronunciation: "Allâhümme innî es'elüke ilmen nâfi'an ve rizkan tayyiben ve amelen mütekabbelen", turkishMeaning: "Allah'ım! Senden faydalı ilim, temiz rızık ve kabul edilmiş amel istiyorum", recommendedCount: 1, source: "İbn Mace"),
                ZikirItem(id: "gunluk_6", category: "gunluk_hayat", arabicText: "رَبِّ أَعُوذُ بِكَ مِنْ هَمَزَاتِ الشَّيَاطِينِ وَأَعُوذُ بِكَ رَبِّ أَن يَحْضُرُونِ", turkishPronunciation: "Rabbi eûzü bike min hemazâtiş-şeyâtîni ve eûzü bike rabbi en yahdurûn", turkishMeaning: "Rabbim şeytanların vesveselerinden sana sığınırım; Rabbim yanımda bulunmalarından da sana sığınırım", recommendedCount: 1, source: "Müminun 97-98")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "ramazan",
            name: "Ramazan Duaları",
            icon: "moon.fill",
            items: [
                ZikirItem(id: "ramazan_1", category: "ramazan", arabicText: "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي", turkishPronunciation: "Allâhümme inneke afüvvün tühibbül-afve fa'fü annî", turkishMeaning: "Allah'ım! Sen affedicisin, affetmeyi seversin, beni affet (Kadir gecesi duası)", recommendedCount: 100, source: "Tirmizi"),
                ZikirItem(id: "ramazan_2", category: "ramazan", arabicText: "اللَّهُمَّ أَهِلَّهُ عَلَيْنَا بِالْأَمْنِ وَالْإِيمَانِ وَالسَّلَامَةِ وَالْإِسْلَامِ", turkishPronunciation: "Allâhümme ehillehü aleynâ bil-emni vel-îmâni ves-selâmeti vel-islâm", turkishMeaning: "Allah'ım! Onu (hilali) bize emniyet, iman, selamet ve İslam ile doğdur", recommendedCount: 1, source: "Tirmizi"),
                ZikirItem(id: "ramazan_3", category: "ramazan", arabicText: "اللَّهُمَّ رَبَّ شَهْرِ رَمَضَانَ أَعِنِّي عَلَى صِيَامِهِ وَقِيَامِهِ", turkishPronunciation: "Allâhümme rabbe şehri ramadân eınnî alâ sıyâmihî ve kıyâmih", turkishMeaning: "Allah'ım Ramazan ayının Rabbi, orucunu tutmakta ve gecelerini ihya etmekte bana yardım et", recommendedCount: 1, source: "Duâ"),
                ZikirItem(id: "ramazan_4", category: "ramazan", arabicText: "ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ", turkishPronunciation: "Zehebeż-zameu vebtelleti'l-urûku ve sebete'l-ecru inşaallâh", turkishMeaning: "Susuzluk gitti, damarlar ıslandı ve Allah'ın izniyle ecir sabit oldu (iftar duası)", recommendedCount: 1, source: "Ebu Davud")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "kisa_sureler",
            name: "Kısa Sureler",
            icon: "book.fill",
            items: [
                ZikirItem(id: "sure_1", category: "kisa_sureler", arabicText: "قُلْ يَا أَيُّهَا الْكَافِرُونَ ۝ لَا أَعْبُدُ مَا تَعْبُدُونَ ۝ وَلَا أَنتُمْ عَابِدُونَ مَا أَعْبُدُ ۝ وَلَا أَنَا عَابِدٌ مَّا عَبَدتُّمْ ۝ وَلَا أَنتُمْ عَابِدُونَ مَا أَعْبُدُ ۝ لَكُمْ دِينُكُمْ وَلِيَ دِينِ", turkishPronunciation: "Kul yâ eyyühel-kâfirûn. Lâ a'büdü mâ ta'büdûn. Ve lâ entüm âbidûne mâ a'büd. Ve lâ ene âbidün mâ abedtüm. Ve lâ entüm âbidûne mâ a'büd. Leküm dînüküm ve liye dîn", turkishMeaning: "De ki: Ey kafirler! Ben sizin taptıklarınıza tapmam. Siz de benim taptığıma tapmazsınız. Sizin dininiz size, benim dinim banadır", recommendedCount: 1, source: "Kafirun Suresi"),
                ZikirItem(id: "sure_2", category: "kisa_sureler", arabicText: "إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ ۝ فَصَلِّ لِرَبِّكَ وَانْحَرْ ۝ إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ", turkishPronunciation: "İnnâ a'taynâkel-kevser. Fesalli li-rabbike venhar. İnne şânieke hüvel-ebter", turkishMeaning: "Muhakkak ki biz sana Kevser'i verdik. O halde Rabbin için namaz kıl ve kurban kes. Doğrusu sana buğzeden, soyu kesik olanın ta kendisidir", recommendedCount: 1, source: "Kevser Suresi"),
                ZikirItem(id: "sure_3", category: "kisa_sureler", arabicText: "إِذَا جَاءَ نَصْرُ اللَّهِ وَالْفَتْحُ ۝ وَرَأَيْتَ النَّاسَ يَدْخُلُونَ فِي دِينِ اللَّهِ أَفْوَاجًا ۝ فَسَبِّحْ بِحَمْدِ رَبِّكَ وَاسْتَغْفِرْهُ إِنَّهُ كَانَ تَوَّابًا", turkishPronunciation: "İzâ câe nasrullâhi vel-feth. Ve raeeyten-nâse yedhulûne fî dînillâhi efvâcâ. Fesebbih bi-hamdi rabbike vestağfirhü innehû kâne tevvâbâ", turkishMeaning: "Allah'ın yardımı ve fetih geldiğinde, insanların bölük bölük Allah'ın dinine girdiğini gördüğünde, Rabbini hamd ile tesbih et ve O'ndan bağışlama dile", recommendedCount: 1, source: "Nasr Suresi"),
                ZikirItem(id: "sure_4", category: "kisa_sureler", arabicText: "قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ", turkishPronunciation: "Kul hüvallâhü ehad. Allâhüs-samed. Lem yelid ve lem yûled. Ve lem yekün lehû küfüven ehad", turkishMeaning: "De ki: O Allah birdir. Allah sameddir. Doğurmamış ve doğmamıştır. Hiçbir şey O'na denk değildir", recommendedCount: 1, source: "İhlas Suresi"),
                ZikirItem(id: "sure_5", category: "kisa_sureler", arabicText: "وَالْعَصْرِ ۝ إِنَّ الْإِنسَانَ لَفِي خُسْرٍ ۝ إِلَّا الَّذِينَ آمَنُوا وَعَمِلُوا الصَّالِحَاتِ وَتَوَاصَوْا بِالْحَقِّ وَتَوَاصَوْا بِالصَّبْرِ", turkishPronunciation: "Vel-asr. İnnel-insâne lefî husr. İllellezîne âmenû ve amilüs-sâlihâti ve tevâsav bil-hakkı ve tevâsav bis-sabr", turkishMeaning: "Asra yemin olsun ki insan gerçekten ziyan içindedir. Ancak iman edip salih ameller işleyenler müstesna", recommendedCount: 1, source: "Asr Suresi")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "genel_zikirler",
            name: "Genel Zikirler",
            icon: "heart.fill",
            items: [
                ZikirItem(id: "genel_1", category: "genel_zikirler", arabicText: "سُبْحَانَ اللَّهِ", turkishPronunciation: "Sübhânallâh", turkishMeaning: "Allah'ı tüm noksanlıklardan tenzih ederim", recommendedCount: 33, source: "Müslim"),
                ZikirItem(id: "genel_2", category: "genel_zikirler", arabicText: "الْحَمْدُ لِلَّهِ", turkishPronunciation: "Elhamdülillâh", turkishMeaning: "Hamd Allah'a mahsustur", recommendedCount: 33, source: "Müslim"),
                ZikirItem(id: "genel_3", category: "genel_zikirler", arabicText: "اللَّهُ أَكْبَرُ", turkishPronunciation: "Allâhu Ekber", turkishMeaning: "Allah en büyüktür", recommendedCount: 33, source: "Müslim"),
                ZikirItem(id: "genel_4", category: "genel_zikirler", arabicText: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", turkishPronunciation: "Lâ havle ve lâ kuvvete illâ billâh", turkishMeaning: "Güç ve kuvvet ancak Allah'tandır", recommendedCount: 33, source: "Buhari, Müslim"),
                ZikirItem(id: "genel_5", category: "genel_zikirler", arabicText: "أَسْتَغْفِرُ اللَّهَ", turkishPronunciation: "Estağfirullâh", turkishMeaning: "Allah'tan bağışlanma dilerim", recommendedCount: 100, source: "Müslim"),
                ZikirItem(id: "genel_6", category: "genel_zikirler", arabicText: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ", turkishPronunciation: "Allâhümme salli alâ Muhammedin ve alâ âli Muhammed", turkishMeaning: "Allah'ım! Muhammed'e ve Muhammed'in ailesine salat eyle", recommendedCount: 100, source: "Buhari"),
                ZikirItem(id: "genel_7", category: "genel_zikirler", arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ سُبْحَانَ اللَّهِ الْعَظِيمِ", turkishPronunciation: "Sübhânallâhi ve bihamdihî sübhânallâhil-azîm", turkishMeaning: "Allah'ı hamd ile tesbih ederim, yüce Allah'ı tenzih ederim", recommendedCount: 100, source: "Buhari, Müslim"),
                ZikirItem(id: "genel_8", category: "genel_zikirler", arabicText: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", turkishPronunciation: "Rabbenâ âtinâ fid-dünyâ haseneten ve fil-âhireti haseneten ve kınâ azâben-nâr", turkishMeaning: "Rabbimiz! Bize dünyada da iyilik ver, ahirette de iyilik ver. Bizi cehennem azabından koru", recommendedCount: 7, source: "Bakara 201"),
                ZikirItem(id: "genel_9", category: "genel_zikirler", arabicText: "لَا إِلَهَ إِلَّا اللَّهُ", turkishPronunciation: "Lâ ilâhe illallâh", turkishMeaning: "Allah'tan başka ilah yoktur", recommendedCount: 100, source: "Buhari, Müslim"),
                ZikirItem(id: "genel_10", category: "genel_zikirler", arabicText: "اللَّهُمَّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ", turkishPronunciation: "Allâhümmağfir lî ve tüb aleyye inneke entet-tevvâbür-rahîm", turkishMeaning: "Allah'ım! Beni bağışla ve tövbemi kabul et. Şüphesiz sen tövbeleri çok kabul eden ve merhametlisin", recommendedCount: 100, source: "Tirmizi")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "sabir_zikirleri",
            name: "Sabır Zikirleri",
            icon: "leaf.fill",
            items: [
                ZikirItem(id: "sabir_1", category: "sabir_zikirleri", arabicText: "إِنَّ اللَّهَ مَعَ الصَّابِرِينَ", turkishPronunciation: "İnnallâhe meas-sâbirîn", turkishMeaning: "Şüphesiz Allah sabredenlerle beraberdir", recommendedCount: 33, source: "Bakara 153"),
                ZikirItem(id: "sabir_2", category: "sabir_zikirleri", arabicText: "رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْرًا وَثَبِّتْ أَقْدَامَنَا", turkishPronunciation: "Rabbenâ efriğ aleynâ sabren ve sebbit akdâmenâ", turkishMeaning: "Rabbimiz! Üzerimize sabır yağdır ve ayaklarımızı sabit kıl", recommendedCount: 7, source: "Bakara 250"),
                ZikirItem(id: "sabir_3", category: "sabir_zikirleri", arabicText: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", turkishPronunciation: "Hasbünallâhü ve ni'mel-vekîl", turkishMeaning: "Allah bize yeter, O ne güzel vekildir", recommendedCount: 100, source: "Al-i İmran 173"),
                ZikirItem(id: "sabir_4", category: "sabir_zikirleri", arabicText: "لَا إِلَهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ", turkishPronunciation: "Lâ ilâhe illâ ente sübhâneke innî küntü minez-zâlimîn", turkishMeaning: "Senden başka ilah yoktur. Seni tenzih ederim. Ben zalimlerden oldum", recommendedCount: 40, source: "Enbiya 87"),
                ZikirItem(id: "sabir_5", category: "sabir_zikirleri", arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ وَالْعَجْزِ وَالْكَسَلِ", turkishPronunciation: "Allâhümme innî eûzü bike minel-hemmi vel-hazeni vel-aczi vel-kesel", turkishMeaning: "Allah'ım! Keder, üzüntü, acizlik ve tembellikten sana sığınırım", recommendedCount: 7, source: "Buhari")
            ],
            isPremium: true
        ),
        ZikirCategory(
            id: "sukur_zikirleri",
            name: "Şükür Zikirleri",
            icon: "hands.clap.fill",
            items: [
                ZikirItem(id: "sukur_1", category: "sukur_zikirleri", arabicText: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ", turkishPronunciation: "Elhamdülillâhi rabbil-âlemîn", turkishMeaning: "Hamd, alemlerin Rabbi olan Allah'a mahsustur", recommendedCount: 33, source: "Fatiha 2"),
                ZikirItem(id: "sukur_2", category: "sukur_zikirleri", arabicText: "الْحَمْدُ لِلَّهِ الَّذِي بِنِعْمَتِهِ تَتِمُّ الصَّالِحَاتُ", turkishPronunciation: "Elhamdülillâhillezî bi ni'metihî tetimmüs-sâlihât", turkishMeaning: "Nimeti ile salih işler tamamlanan Allah'a hamdolsun", recommendedCount: 33, source: "İbn Mace"),
                ZikirItem(id: "sukur_3", category: "sukur_zikirleri", arabicText: "اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ", turkishPronunciation: "Allâhümme eınnî alâ zikrike ve şükrike ve hüsni ibâdetik", turkishMeaning: "Allah'ım! Seni zikretmek, sana şükretmek ve güzel ibadet etmek için yardım et", recommendedCount: 7, source: "Ebu Davud"),
                ZikirItem(id: "sukur_4", category: "sukur_zikirleri", arabicText: "رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ", turkishPronunciation: "Rabbi evzı'nî en eşküre ni'metekel-letî en'amte aleyye", turkishMeaning: "Rabbim! Bana verdiğin nimete şükretmemi ilham et", recommendedCount: 7, source: "Neml 19")
            ],
            isPremium: true
        ),
        ZikirCategory(
            id: "sabah_rutinleri",
            name: "Sabah Rutinleri",
            icon: "sun.and.horizon.fill",
            items: [
                ZikirItem(id: "srutin_1", category: "sabah_rutinleri", arabicText: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ", turkishPronunciation: "Elhamdülillâhillezî ahyânâ ba'de mâ emâtenâ ve ileyhin-nüşûr", turkishMeaning: "Bizi öldürdükten sonra dirilten Allah'a hamdolsun. Dönüş O'nadır", recommendedCount: 1, source: "Buhari"),
                ZikirItem(id: "srutin_2", category: "sabah_rutinleri", arabicText: "أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ وَكَلِمَةِ الْإِخْلَاصِ", turkishPronunciation: "Asbahnâ alâ fitratil-islâm ve kelimetil-ihlâs", turkishMeaning: "İslam fıtratı ve ihlas kelimesi üzere sabahladık", recommendedCount: 1, source: "Ahmed"),
                ZikirItem(id: "srutin_3", category: "sabah_rutinleri", arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ", turkishPronunciation: "Sübhânallâhi ve bihamdihî adede halkıhî", turkishMeaning: "Allah'ı, yarattıklarının sayısınca hamd ile tesbih ederim", recommendedCount: 3, source: "Müslim"),
                ZikirItem(id: "srutin_4", category: "sabah_rutinleri", arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَ هَذَا الْيَوْمِ", turkishPronunciation: "Allâhümme innî es'elüke hayra hâzel-yevm", turkishMeaning: "Allah'ım! Bu günün hayrını senden isterim", recommendedCount: 1, source: "Ebu Davud"),
                ZikirItem(id: "srutin_5", category: "sabah_rutinleri", arabicText: "بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", turkishPronunciation: "Bismillâhi tevekkeltü alallâhi lâ havle ve lâ kuvvete illâ billâh", turkishMeaning: "Allah'ın adıyla. Allah'a tevekkül ettim. Güç ve kuvvet ancak Allah'tandır", recommendedCount: 1, source: "Ebu Davud, Tirmizi")
            ],
            isPremium: true
        ),
        ZikirCategory(
            id: "uyku_oncesi",
            name: "Uyku Öncesi Zikirler",
            icon: "moon.zzz.fill",
            items: [
                ZikirItem(id: "uyku_1", category: "uyku_oncesi", arabicText: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا", turkishPronunciation: "Bismikallâhümme emûtü ve ahyâ", turkishMeaning: "Allah'ım! Senin adınla ölür ve dirilirim", recommendedCount: 1, source: "Buhari"),
                ZikirItem(id: "uyku_2", category: "uyku_oncesi", arabicText: "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ", turkishPronunciation: "Allâhümme kınî azâbeke yevme teb'asü ibâdek", turkishMeaning: "Allah'ım! Kullarını dirilttiğin gün beni azabından koru", recommendedCount: 3, source: "Ebu Davud"),
                ZikirItem(id: "uyku_3", category: "uyku_oncesi", arabicText: "اللَّهُمَّ بِاسْمِكَ أَحْيَا وَبِاسْمِكَ أَمُوتُ", turkishPronunciation: "Allâhümme bismike ahyâ ve bismike emût", turkishMeaning: "Allah'ım! Senin adınla yaşar, senin adınla ölürüm", recommendedCount: 1, source: "Buhari, Müslim"),
                ZikirItem(id: "uyku_4", category: "uyku_oncesi", arabicText: "سُبْحَانَ اللَّهِ", turkishPronunciation: "Sübhânallâh", turkishMeaning: "Allah'ı tüm noksanlıklardan tenzih ederim", recommendedCount: 33, source: "Buhari, Müslim"),
                ZikirItem(id: "uyku_5", category: "uyku_oncesi", arabicText: "الْحَمْدُ لِلَّهِ", turkishPronunciation: "Elhamdülillâh", turkishMeaning: "Hamd Allah'a mahsustur", recommendedCount: 33, source: "Buhari, Müslim"),
                ZikirItem(id: "uyku_6", category: "uyku_oncesi", arabicText: "اللَّهُ أَكْبَرُ", turkishPronunciation: "Allâhu Ekber", turkishMeaning: "Allah en büyüktür", recommendedCount: 34, source: "Buhari, Müslim")
            ],
            isPremium: true
        )
    ] + LocalDuaPacksData.extraCategories

    static let premiumCategoryIDs: Set<String> = Set(["sabir_zikirleri", "sukur_zikirleri", "sabah_rutinleri", "uyku_oncesi"]).union(LocalDuaPacksData.premiumCategoryIDs)

    static let dailyDuas: [ZikirItem] = [
        ZikirItem(id: "daily_1", category: "daily", arabicText: "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي", turkishPronunciation: "Rabbi'şrah lî sadrî ve yessir lî emrî", turkishMeaning: "Rabbim! Göğsümü aç ve işimi kolaylaştır", recommendedCount: 7, source: "Taha 25-26"),
        ZikirItem(id: "daily_2", category: "daily", arabicText: "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا", turkishPronunciation: "Rabbenâ heb lenâ min ezvâcinâ ve zürriyyâtinâ kurrate a'yünin vec'alnâ lil-müttekîne imâmâ", turkishMeaning: "Rabbimiz! Bize eşlerimizden ve nesillerimizden göz aydınlığı olacak kimseler ver ve bizi takva sahiplerine önder kıl", recommendedCount: 3, source: "Furkan 74"),
        ZikirItem(id: "daily_3", category: "daily", arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى", turkishPronunciation: "Allâhümme innî es'elükel-hüdâ vet-tükâ vel-afâfe vel-ğınâ", turkishMeaning: "Allah'ım! Senden hidayet, takva, iffet ve gönül zenginliği isterim", recommendedCount: 3, source: "Müslim"),
        ZikirItem(id: "daily_4", category: "daily", arabicText: "رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً", turkishPronunciation: "Rabbenâ lâ tüziğ kulûbenâ ba'de iz hedeytenâ ve heb lenâ min ledünke rahmeh", turkishMeaning: "Rabbimiz! Bizi doğru yola ilettikten sonra kalplerimizi eğriltme. Bize katından bir rahmet bağışla", recommendedCount: 3, source: "Al-i İmran 8"),
        ZikirItem(id: "daily_5", category: "daily", arabicText: "اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ", turkishPronunciation: "Allâhümme innî eûzü bike minel-hemmi vel-hazen", turkishMeaning: "Allah'ım! Kederden ve üzüntüden sana sığınırım", recommendedCount: 3, source: "Buhari"),
        ZikirItem(id: "daily_6", category: "daily", arabicText: "رَبِّ زِدْنِي عِلْمًا", turkishPronunciation: "Rabbi zidnî ilmâ", turkishMeaning: "Rabbim! İlmimi artır", recommendedCount: 7, source: "Taha 114"),
        ZikirItem(id: "daily_7", category: "daily", arabicText: "اللَّهُمَّ اغْفِرْ لِي وَارْحَمْنِي وَاهْدِنِي وَارْزُقْنِي", turkishPronunciation: "Allâhümmağfir lî verhamnî vehdinî verzuknî", turkishMeaning: "Allah'ım! Beni bağışla, bana merhamet et, beni doğru yola ilet ve beni rızıklandır", recommendedCount: 7, source: "Müslim"),
        ZikirItem(id: "daily_8", category: "daily", arabicText: "اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي", turkishPronunciation: "Allâhümme inneke afüvvün tühibbül-afve fa'fü annî", turkishMeaning: "Allah'ım! Sen affedicisin, affetmeyi seversin, beni affet", recommendedCount: 100, source: "Tirmizi"),
        ZikirItem(id: "daily_9", category: "daily", arabicText: "اللَّهُمَّ أَنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا", turkishPronunciation: "Allâhümme innî es'elüke ilmen nâfi'an ve rizkan tayyiben ve amelen mütekabbelen", turkishMeaning: "Allah'ım! Senden faydalı ilim, temiz rızık ve kabul edilmiş amel istiyorum", recommendedCount: 1, source: "İbn Mace"),
        ZikirItem(id: "daily_10", category: "daily", arabicText: "رَبَّنَا اغْفِرْ لَنَا وَلِإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالْإِيمَانِ", turkishPronunciation: "Rabbenağfir lenâ ve li-ihvâninellezîne sebekûnâ bil-îmân", turkishMeaning: "Rabbimiz! Bizleri ve bizden önce iman etmiş olan kardeşlerimizi bağışla", recommendedCount: 3, source: "Haşr 10")
    ] + LocalDuaPacksData.extraDailyDuas
}
