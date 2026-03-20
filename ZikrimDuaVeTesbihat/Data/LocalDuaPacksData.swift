import Foundation

enum LocalDuaPacksData {
    static let extraCategories: [ZikirCategory] = [
        ZikirCategory(
            id: "peygamber_dualari",
            name: "Peygamber Duaları",
            icon: "book.closed.fill",
            items: [
                ZikirItem(id: "peygamber_1", category: "peygamber_dualari", arabicText: "رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي", turkishPronunciation: "Rabbi'şrah lî sadrî ve yessir lî emrî", turkishMeaning: "Rabbim, gönlüme ferahlık ver ve işimi kolaylaştır", recommendedCount: 7, source: "Taha 25-26"),
                ZikirItem(id: "peygamber_2", category: "peygamber_dualari", arabicText: "لَا إِلَهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ", turkishPronunciation: "Lâ ilâhe illâ ente sübhâneke innî küntü minez-zâlimîn", turkishMeaning: "Senden başka ilah yoktur, seni tenzih ederim; ben nefsime zulmedenlerden oldum", recommendedCount: 40, source: "Enbiya 87"),
                ZikirItem(id: "peygamber_3", category: "peygamber_dualari", arabicText: "أَنِّي مَسَّنِيَ الضُّرُّ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ", turkishPronunciation: "Ennî messeniyed-durru ve ente erhamür-râhimîn", turkishMeaning: "Başıma dert geldi; sen merhametlilerin en merhametlisisin", recommendedCount: 7, source: "Enbiya 83"),
                ZikirItem(id: "peygamber_4", category: "peygamber_dualari", arabicText: "رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنتَ السَّمِيعُ الْعَلِيمُ", turkishPronunciation: "Rabbenâ tekabbel minnâ inneke entes-semî'ul-alîm", turkishMeaning: "Rabbimiz, bizden kabul buyur; şüphesiz sen işiten ve bilensin", recommendedCount: 7, source: "Bakara 127"),
                ZikirItem(id: "peygamber_5", category: "peygamber_dualari", arabicText: "رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ", turkishPronunciation: "Rabbi evzi'nî en eşküre ni'metek", turkishMeaning: "Rabbim, bana verdiğin nimete şükretmeyi ilham et", recommendedCount: 7, source: "Neml 19"),
                ZikirItem(id: "peygamber_6", category: "peygamber_dualari", arabicText: "رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ", turkishPronunciation: "Rabbi innî limâ enzelte ileyye min hayrin fakîr", turkishMeaning: "Rabbim, bana indireceğin her hayra muhtacım", recommendedCount: 21, source: "Kasas 24"),
                ZikirItem(id: "peygamber_7", category: "peygamber_dualari", arabicText: "تَوَفَّنِي مُسْلِمًا وَأَلْحِقْنِي بِالصَّالِحِينَ", turkishPronunciation: "Teveffenî müslimen ve elhiknî bis-sâlihîn", turkishMeaning: "Canımı müslüman olarak al ve beni salihlere kat", recommendedCount: 7, source: "Yusuf 101"),
                ZikirItem(id: "peygamber_8", category: "peygamber_dualari", arabicText: "رَبِّ لَا تَذَرْنِي فَرْدًا وَأَنتَ خَيْرُ الْوَارِثِينَ", turkishPronunciation: "Rabbî lâ tezernî ferden ve ente hayrul-vârisîn", turkishMeaning: "Rabbim, beni yalnız bırakma; sen varislerin en hayırlısısın", recommendedCount: 40, source: "Enbiya 89")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "ev_ve_yolculuk_dualari",
            name: "Ev ve Yolculuk Duaları",
            icon: "house.fill",
            items: [
                ZikirItem(id: "evyol_1", category: "ev_ve_yolculuk_dualari", arabicText: "بِسْمِ اللَّهِ وَلَجْنَا وَبِسْمِ اللَّهِ خَرَجْنَا وَعَلَى اللَّهِ رَبِّنَا تَوَكَّلْنَا", turkishPronunciation: "Bismillâhi velecnâ ve bismillâhi harecnâ ve alâllâhi rabbinâ tevekkelnâ", turkishMeaning: "Allah'ın adıyla girdik, Allah'ın adıyla çıktık ve Rabbimiz Allah'a tevekkül ettik", recommendedCount: 1, source: "Ebû Dâvûd"),
                ZikirItem(id: "evyol_2", category: "ev_ve_yolculuk_dualari", arabicText: "بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ", turkishPronunciation: "Bismillâhi tevekkeltü alâllâhi lâ havle ve lâ kuvvete illâ billâh", turkishMeaning: "Allah'ın adıyla, Allah'a tevekkül ettim; güç ve kuvvet ancak Allah'tandır", recommendedCount: 1, source: "Tirmizî"),
                ZikirItem(id: "evyol_3", category: "ev_ve_yolculuk_dualari", arabicText: "اللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ اللَّهُ أَكْبَرُ سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا", turkishPronunciation: "Allâhu ekber, Allâhu ekber, Allâhu ekber. Sübhânellezî sahhara lenâ hâzâ", turkishMeaning: "Allah en büyüktür. Bunu bize boyun eğdireni tesbih ederiz", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "evyol_4", category: "ev_ve_yolculuk_dualari", arabicText: "اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ", turkishPronunciation: "Allâhümme'ftah lî ebvâbe rahmetike", turkishMeaning: "Allah'ım, bana rahmet kapılarını aç", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "evyol_5", category: "ev_ve_yolculuk_dualari", arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ", turkishPronunciation: "Allâhümme innî es'elüke min fadlik", turkishMeaning: "Allah'ım, senden fazlını ve lütfunu istiyorum", recommendedCount: 1, source: "Müslim"),
                ZikirItem(id: "evyol_6", category: "ev_ve_yolculuk_dualari", arabicText: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ", turkishPronunciation: "Elhamdülillâhillezî ahyânâ ba'de mâ emâtenâ ve ileyhin-nüşûr", turkishMeaning: "Bizi öldürdükten sonra dirilten Allah'a hamd olsun; dönüş O'nadır", recommendedCount: 1, source: "Buhârî"),
                ZikirItem(id: "evyol_7", category: "ev_ve_yolculuk_dualari", arabicText: "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا", turkishPronunciation: "Bismikellâhümme emûtü ve ahyâ", turkishMeaning: "Allah'ım, senin adınla ölür ve dirilirim", recommendedCount: 1, source: "Buhârî"),
                ZikirItem(id: "evyol_8", category: "ev_ve_yolculuk_dualari", arabicText: "بِسْمِ اللَّهِ", turkishPronunciation: "Bismillâh", turkishMeaning: "Allah'ın adıyla", recommendedCount: 1, source: "Hisnü'l Müslim")
            ],
            isPremium: false
        ),
        ZikirCategory(
            id: "aile_ve_nesil_dualari",
            name: "Aile ve Nesil Duaları",
            icon: "person.3.fill",
            items: [
                ZikirItem(id: "aile_1", category: "aile_ve_nesil_dualari", arabicText: "رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا", turkishPronunciation: "Rabbenâ heb lenâ min ezvâcinâ ve zürriyyâtinâ kurrete a'yünin vec'alnâ lil-müttakîne imâmâ", turkishMeaning: "Rabbimiz, bize eşlerimizden ve nesillerimizden göz aydınlığı ver ve bizi takva sahiplerine önder kıl", recommendedCount: 7, source: "Furkan 74"),
                ZikirItem(id: "aile_2", category: "aile_ve_nesil_dualari", arabicText: "رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ", turkishPronunciation: "Rabbi heb lî mines-sâlihîn", turkishMeaning: "Rabbim, bana salihlerden olacak bir nesil ihsan et", recommendedCount: 7, source: "Saffat 100"),
                ZikirItem(id: "aile_3", category: "aile_ve_nesil_dualari", arabicText: "رَبِّ لَا تَذَرْنِي فَرْدًا وَأَنتَ خَيْرُ الْوَارِثِينَ", turkishPronunciation: "Rabbî lâ tezernî ferden ve ente hayrul-vârisîn", turkishMeaning: "Rabbim, beni yalnız bırakma; sen varislerin en hayırlısısın", recommendedCount: 40, source: "Enbiya 89"),
                ZikirItem(id: "aile_4", category: "aile_ve_nesil_dualari", arabicText: "رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِن ذُرِّيَّتِي", turkishPronunciation: "Rabbi'c'alnî mukîmes-salâti ve min zürriyyetî", turkishMeaning: "Rabbim, beni ve neslimi namazı dosdoğru kılanlardan eyle", recommendedCount: 7, source: "İbrahim 40"),
                ZikirItem(id: "aile_5", category: "aile_ve_nesil_dualari", arabicText: "رَبَّنَا وَاجْعَلْنَا مُسْلِمَيْنِ لَكَ وَمِن ذُرِّيَّتِنَا أُمَّةً مُّسْلِمَةً لَّكَ", turkishPronunciation: "Rabbenâ vec'alnâ müslimeyni leke ve min zürriyyetinâ ümmeten müslimeten lek", turkishMeaning: "Rabbimiz, bizi sana teslim olanlardan kıl; neslimizden de sana teslim bir ümmet çıkar", recommendedCount: 3, source: "Bakara 128"),
                ZikirItem(id: "aile_6", category: "aile_ve_nesil_dualari", arabicText: "رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا", turkishPronunciation: "Rabbirhamhumâ kemâ rabbeyânî sağîrâ", turkishMeaning: "Rabbim, beni küçükken yetiştirdikleri gibi anne ve babama merhamet et", recommendedCount: 7, source: "İsra 24"),
                ZikirItem(id: "aile_7", category: "aile_ve_nesil_dualari", arabicText: "رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ", turkishPronunciation: "Rabbenağfir lî ve li-vâlideyye ve lil-mü'minîne yevme yekûmül-hisâb", turkishMeaning: "Rabbimiz, hesap gününde beni, anne babamı ve müminleri bağışla", recommendedCount: 10, source: "İbrahim 41")
            ],
            isPremium: true
        ),
        ZikirCategory(
            id: "rizik_ve_bereket_dualari",
            name: "Rızık ve Bereket Duaları",
            icon: "sparkles",
            items: [
                ZikirItem(id: "rizik_1", category: "rizik_ve_bereket_dualari", arabicText: "رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ", turkishPronunciation: "Rabbi innî limâ enzelte ileyye min hayrin fakîr", turkishMeaning: "Rabbim, bana indireceğin her hayra muhtacım", recommendedCount: 21, source: "Kasas 24"),
                ZikirItem(id: "rizik_2", category: "rizik_ve_bereket_dualari", arabicText: "اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ", turkishPronunciation: "Allâhümme'kfinî bi-halâlike an harâmike ve ağninî bi-fadlike ammen sivâk", turkishMeaning: "Allah'ım, helalinle beni haramdan koru ve fazlınla beni senden başkasına muhtaç etme", recommendedCount: 7, source: "Tirmizî"),
                ZikirItem(id: "rizik_3", category: "rizik_ve_bereket_dualari", arabicText: "وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ", turkishPronunciation: "Ve men yettekıllâhe yec'al lehû mahracen ve yerzukhû min haysü lâ yahtesib", turkishMeaning: "Kim Allah'tan sakınırsa Allah ona çıkış yolu verir ve onu ummadığı yerden rızıklandırır", recommendedCount: 21, source: "Talak 2-3"),
                ZikirItem(id: "rizik_4", category: "rizik_ve_bereket_dualari", arabicText: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ", turkishPronunciation: "Rabbenâ âtinâ fid-dünyâ haseneten ve fil-âhireti haseneten ve kınâ azâben-nâr", turkishMeaning: "Rabbimiz, bize dünyada da ahirette de güzellik ver ve bizi ateş azabından koru", recommendedCount: 7, source: "Bakara 201"),
                ZikirItem(id: "rizik_5", category: "rizik_ve_bereket_dualari", arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ عِلْمًا نَافِعًا وَرِزْقًا طَيِّبًا وَعَمَلًا مُتَقَبَّلًا", turkishPronunciation: "Allâhümme innî es'elüke ilmen nâfi'an ve rızkan tayyiben ve amelen mütekabbelen", turkishMeaning: "Allah'ım, senden faydalı ilim, temiz rızık ve kabul edilmiş amel istiyorum", recommendedCount: 1, source: "İbn Mace"),
                ZikirItem(id: "rizik_6", category: "rizik_ve_bereket_dualari", arabicText: "رَبِّ زِدْنِي عِلْمًا", turkishPronunciation: "Rabbi zidnî ilmâ", turkishMeaning: "Rabbim, ilmimi artır", recommendedCount: 7, source: "Taha 114"),
                ZikirItem(id: "rizik_7", category: "rizik_ve_bereket_dualari", arabicText: "رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ", turkishPronunciation: "Rabbi evzi'nî en eşküre ni'metek", turkishMeaning: "Rabbim, bana verdiğin nimete şükretmeyi ilham et", recommendedCount: 7, source: "Neml 19")
            ],
            isPremium: true
        ),
    ]

    static let premiumCategoryIDs: Set<String> = [
        "aile_ve_nesil_dualari",
        "rizik_ve_bereket_dualari"
    ]

    static let extraDailyDuas: [ZikirItem] = [
        ZikirItem(id: "daily_11", category: "daily", arabicText: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", turkishPronunciation: "Hasbünallâhü ve ni'mel-vekîl", turkishMeaning: "Allah bize yeter; O ne güzel vekildir", recommendedCount: 33, source: "Al-i İmran 173"),
        ZikirItem(id: "daily_12", category: "daily", arabicText: "رَبِّ إِنِّي لِمَا أَنْزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ", turkishPronunciation: "Rabbi innî limâ enzelte ileyye min hayrin fakîr", turkishMeaning: "Rabbim, bana indireceğin her hayra muhtacım", recommendedCount: 7, source: "Kasas 24"),
        ZikirItem(id: "daily_13", category: "daily", arabicText: "رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا", turkishPronunciation: "Rabbirhamhumâ kemâ rabbeyânî sağîrâ", turkishMeaning: "Rabbim, anne ve babama merhamet et", recommendedCount: 7, source: "İsra 24"),
        ZikirItem(id: "daily_14", category: "daily", arabicText: "رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِن ذُرِّيَّتِي", turkishPronunciation: "Rabbi'c'alnî mukîmes-salâti ve min zürriyyetî", turkishMeaning: "Rabbim, beni ve neslimi namazı dosdoğru kılanlardan eyle", recommendedCount: 7, source: "İbrahim 40"),
        ZikirItem(id: "daily_15", category: "daily", arabicText: "أَنِّي مَسَّنِيَ الضُّرُّ وَأَنتَ أَرْحَمُ الرَّاحِمِينَ", turkishPronunciation: "Ennî messeniyed-durru ve ente erhamür-râhimîn", turkishMeaning: "Başıma dert geldi; sen merhametlilerin en merhametlisisin", recommendedCount: 7, source: "Enbiya 83"),
        ZikirItem(id: "daily_16", category: "daily", arabicText: "رَبِّ هَبْ لِي مِنَ الصَّالِحِينَ", turkishPronunciation: "Rabbi heb lî mines-sâlihîn", turkishMeaning: "Rabbim, bana salihlerden olacak bir nesil ihsan et", recommendedCount: 7, source: "Saffat 100"),
        ZikirItem(id: "daily_17", category: "daily", arabicText: "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ", turkishPronunciation: "Yâ Hayyü yâ Kayyûm bi-rahmetike estağîs", turkishMeaning: "Ey diri ve her şeyi ayakta tutan Rabbim, rahmetinle yardım istiyorum", recommendedCount: 33, source: "Tirmizî"),
        ZikirItem(id: "daily_18", category: "daily", arabicText: "اللَّهُمَّ مُصَرِّفَ الْقُلُوبِ صَرِّفْ قُلُوبَنَا عَلَى طَاعَتِكَ", turkishPronunciation: "Allâhümme musarrifel-kulûb sarrif kulûbenâ alâ tâatik", turkishMeaning: "Allah'ım, kalpleri çeviren sensin; kalplerimizi itaatine yönelt", recommendedCount: 7, source: "Müslim")
    ]
}
