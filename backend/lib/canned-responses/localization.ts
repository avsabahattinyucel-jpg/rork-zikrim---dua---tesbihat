import type { LocalizationConfig } from "./types.js";

export const CANNED_RESPONSES = {
  tr: {
    triggers: {
      greeting: ["selam", "selamün aleyküm", "selamun aleykum", "merhaba", "slm", "sa", "günaydın", "iyi akşamlar", "iyi geceler"],
      how_are_you: ["naber", "nasılsın", "iyi misin", "nasıl gidiyor", "ne yapıyorsun"],
      thanks: ["teşekkürler", "teşekkür ederim", "sağ ol", "sağolasın", "eyvallah", "allah razı olsun"],
      goodbye: ["görüşürüz", "hoşça kal", "kendine iyi bak", "sonra yazarım", "bye", "bb"],
      short_positive: ["tamam", "okey", "olur", "anladım", "güzel", "iyi", "süper", "mantıklı"],
      short_negative: ["yok", "istemiyorum", "boşver", "emin değilim", "kararsızım", "bilemedim"],
      blessings: ["amin", "inşallah", "maşallah", "allah razı olsun"],
      who_are_you: ["kimsin", "sen kimsin", "rabia kimsin"],
      what_can_you_do: ["ne yapabiliyorsun", "ne yaparsın", "ne işe yararsın", "bana nasıl yardımcı olabilirsin"]
    },
    responses: {
      greeting: [
        "Aleyküm selam. Hoş geldin, nasıl yardımcı olabilirim?",
        "Selam, hoş geldin. Bugün gönlüne iyi gelecek ne arıyorsun?",
        "Merhaba. İstersen dua, zikir ya da kısa bir manevi destekle devam edebiliriz.",
        "Günaydın. Allah gününü hayırlı ve huzurlu kılsın.",
        "İyi akşamlar. Rabbim geceni huzurlu eylesin."
      ],
      how_are_you: [
        "İyiyim, Allah razı olsun. Sen nasılsın?",
        "Çok şükür iyiyim. Sana nasıl destek olabilirim?",
        "Buradayım, seni dinliyorum. Gönlünde ne var?",
        "İyiyim. İstersen dua, zikir ya da sohbet edebiliriz.",
        "Şükürler olsun, iyiyim. Sen bugün nasıl hissediyorsun?"
      ],
      thanks: [
        "Rica ederim. Allah senden de razı olsun.",
        "Ne demek, her zaman buradayım.",
        "Allah razı olsun. Dilersen devam edebiliriz.",
        "Memnun oldum. Başka bir konuda da yardımcı olabilirim.",
        "Rica ederim. Rabbim gönlüne ferahlık versin."
      ],
      goodbye: [
        "Görüşürüz. Allah’a emanet ol.",
        "Hoşça kal. Rabbim kalbine huzur versin.",
        "Kendine iyi bak. Ne zaman istersen buradayım.",
        "Allah’a emanet ol. Yine beklerim.",
        "Görüşmek üzere. İçin daralırsa gel, konuşalım."
      ],
      short_positive: [
        "Tamam. İstersen buradan devam edelim.",
        "Güzel. Bir sonraki adımda sana yardımcı olabilirim.",
        "Anladım. Dilersen biraz daha açabiliriz.",
        "Sevindim. İstersen bunu birlikte netleştirelim.",
        "Peki. Nasıl devam etmek istersin?"
      ],
      short_negative: [
        "Sorun değil. Hazır olduğunda yine konuşabiliriz.",
        "Peki. Fikrini değiştirirsen buradayım.",
        "Anlıyorum. İstersen daha sade şekilde yardımcı olayım.",
        "Kararsız olman normal. Dilersen birlikte netleştirebiliriz.",
        "Tamam. Zorlamayalım, istersen başka bir şey konuşabiliriz."
      ],
      blessings: [
        "Amin, Allah kabul etsin.",
        "İnşallah. Rabbim hayırlısını nasip etsin.",
        "Maşallah. Allah güzellikleri artırsın.",
        "Allah razı olsun. Gönlüne ferahlık versin.",
        "Ne güzel. Rabbim huzurunu artırsın."
      ],
      emoji_only: [
        "Buradayım. İstersen devam edebiliriz.",
        "Ne güzel. Dilersen konuşabiliriz.",
        "Kalbine huzur olsun. Devam etmek istersen buradayım."
      ],
      who_are_you: [
        "Ben Rabia. Dua, zikir ve manevi destek konusunda sana eşlik etmek için buradayım.",
        "Ben Rabia. İstersen dua bulabilir, zikir seçebilir ya da seninle sakin bir sohbet edebilirim."
      ],
      what_can_you_do: [
        "Dua, zikir, manevi destek ve temel dini içeriklerde yardımcı olabilirim.",
        "İstersen sana dua önerebilir, zikir seçebilir ya da içini rahatlatacak bir sohbet başlatabilirim."
      ]
    }
  },
  en: {
    triggers: {
      greeting: ["hi", "hello", "hey", "good morning", "good evening", "good night", "salam"],
      how_are_you: ["how are you", "how are you doing", "how's it going", "you good", "what's up"],
      thanks: ["thanks", "thank you", "thx", "appreciate it", "jazakallah", "may allah reward you"],
      goodbye: ["bye", "goodbye", "see you", "take care", "talk later"],
      short_positive: ["ok", "okay", "alright", "got it", "nice", "good", "great", "makes sense"],
      short_negative: ["no", "never mind", "not sure", "i don't want to", "maybe not", "skip"],
      blessings: ["ameen", "inshallah", "mashallah", "allah bless", "may allah reward you"],
      who_are_you: ["who are you", "what are you", "rabia who are you"],
      what_can_you_do: ["what can you do", "how can you help", "what do you do"]
    },
    responses: {
      greeting: [
        "Peace be with you. Welcome, how can I help you today?",
        "Hello, welcome. What would bring your heart some ease today?",
        "Hi. We can continue with a prayer, dhikr, or a short moment of spiritual support.",
        "Good morning. May your day be peaceful and blessed.",
        "Good evening. May your night be calm and restful."
      ],
      how_are_you: [
        "I’m well, thank you. How are you feeling today?",
        "I’m doing well. How can I support you?",
        "I’m here and listening. What is on your heart?",
        "I’m well. We can talk, reflect, or continue with prayer or dhikr.",
        "All is well, by God’s grace. How are you today?"
      ],
      thanks: [
        "You’re welcome. May God reward you as well.",
        "Anytime. I’m here for you.",
        "You’re very welcome. We can continue if you’d like.",
        "Glad to help. I can also help with something else.",
        "You’re welcome. May your heart be at ease."
      ],
      goodbye: [
        "See you soon. May peace be with you.",
        "Take care. May your heart stay calm.",
        "Take good care of yourself. I’ll be here when you need me.",
        "Goodbye for now. You’re always welcome back.",
        "See you later. Come back anytime you need a quiet space."
      ],
      short_positive: [
        "Alright. We can continue from here.",
        "Good. I can help with the next step too.",
        "Understood. We can explore it a little more if you want.",
        "Glad to hear that. We can make it clearer together.",
        "Okay. How would you like to continue?"
      ],
      short_negative: [
        "That’s okay. We can talk again whenever you’re ready.",
        "No problem. I’ll be here if you change your mind.",
        "I understand. I can keep it simpler if you prefer.",
        "That’s completely fine. We can leave it here for now.",
        "Alright. No pressure, we can talk about something else."
      ],
      blessings: [
        "Ameen. May it be accepted.",
        "Inshallah. May what is best come to you.",
        "Mashallah. May goodness continue to grow.",
        "May God bless you and bring you ease.",
        "That is beautiful. May peace increase in your heart."
      ],
      emoji_only: [
        "I’m here if you’d like to continue.",
        "That’s lovely. We can keep going if you want.",
        "May peace be with you. I’m here whenever you need."
      ],
      who_are_you: [
        "I’m Rabia. I’m here to accompany you with prayer, dhikr, and gentle spiritual support.",
        "I’m Rabia. I can help you find prayers, choose dhikr, or simply stay with you in a calm conversation."
      ],
      what_can_you_do: [
        "I can help with prayer, dhikr, spiritual support, and basic religious guidance.",
        "I can suggest prayers, help you choose dhikr, or support you with a calm and thoughtful conversation."
      ]
    }
  },
  ar: {
    triggers: {
      greeting: ["السلام عليكم", "سلام", "مرحبا", "أهلا", "صباح الخير", "مساء الخير"],
      how_are_you: ["كيف حالك", "كيفك", "شلونك", "أخبارك"],
      thanks: ["شكرا", "شكرا لك", "جزاك الله خيرا", "الله يرضى عليك"],
      goodbye: ["مع السلامة", "إلى اللقاء", "أراك لاحقا", "تصبح على خير"],
      short_positive: ["حسنا", "تمام", "جميل", "مفهوم", "جيد"],
      short_negative: ["لا", "اتركه", "لا أريد", "لست متأكدا", "لا أدري"],
      blessings: ["آمين", "إن شاء الله", "ما شاء الله", "الله يرضى عنك"],
      who_are_you: ["من أنت", "مين أنت", "من تكونين"],
      what_can_you_do: ["ماذا يمكنك أن تفعلي", "كيف تساعدينني", "ما الذي تفعلينه"]
    },
    responses: {
      greeting: [
        "وعليكم السلام. أهلا بك، كيف يمكنني مساعدتك اليوم؟",
        "مرحبا بك. ما الذي قد يريح قلبك اليوم؟",
        "أهلا. يمكننا أن نبدأ بدعاء أو ذكر أو دعم روحي بسيط.",
        "صباح الخير. أسأل الله أن يجعل يومك مباركا وهادئا.",
        "مساء الخير. أسأل الله أن يجعل ليلتك هادئة ومطمئنة."
      ],
      how_are_you: [
        "أنا بخير، الحمد لله. كيف حالك أنت؟",
        "بخير بفضل الله. كيف أستطيع أن أساندك؟",
        "أنا هنا وأستمع إليك. ماذا في قلبك؟",
        "أنا بخير. يمكننا أن نتحدث أو نذكر الله أو ندعو معا.",
        "الحمد لله أنا بخير. كيف تشعر اليوم؟"
      ],
      thanks: [
        "على الرحب والسعة. جزاك الله خيرا أيضا.",
        "لا شكر على واجب. أنا هنا دائما.",
        "بارك الله فيك. يمكننا أن نكمل إن أردت.",
        "يسرني ذلك. يمكنني مساعدتك في أمر آخر أيضا.",
        "عفوا. أسأل الله أن يشرح صدرك."
      ],
      goodbye: [
        "إلى اللقاء. في أمان الله.",
        "مع السلامة. أسأل الله أن يملأ قلبك سكينة.",
        "اعتن بنفسك. سأبقى هنا متى احتجت.",
        "في أمان الله. أهلا بك في أي وقت.",
        "أراك لاحقا. عد متى احتجت إلى لحظة هادئة."
      ],
      short_positive: [
        "حسنا. يمكننا المتابعة من هنا.",
        "جميل. أستطيع مساعدتك في الخطوة التالية أيضا.",
        "فهمت. يمكننا توضيح الأمر أكثر إن أحببت.",
        "يسرني ذلك. يمكننا ترتيبه معا.",
        "حسنا. كيف تريد أن نكمل؟"
      ],
      short_negative: [
        "لا بأس. يمكننا الحديث عندما تكون مستعدا.",
        "حسنا. سأبقى هنا إن غيرت رأيك.",
        "أتفهم ذلك. أستطيع أن أبسط الأمر أكثر.",
        "هذا طبيعي. يمكننا التوقف هنا الآن.",
        "لا مشكلة. يمكننا الحديث في أمر آخر."
      ],
      blessings: [
        "آمين، تقبل الله.",
        "إن شاء الله. أسأل الله أن يقدر لك الخير.",
        "ما شاء الله. أسأل الله أن يزيدك من فضله.",
        "جزاك الله خيرا. أسأل الله أن يرزقك السكينة.",
        "جميل جدا. أسأل الله أن يملأ قلبك سلاما."
      ],
      emoji_only: [
        "أنا هنا إن أحببت أن نكمل.",
        "جميل. يمكننا المتابعة إن أردت.",
        "أسأل الله أن يمنح قلبك السكينة. أنا هنا متى احتجت."
      ],
      who_are_you: [
        "أنا رابعة. أنا هنا لأرافقك بالدعاء والذكر والدعم الروحي اللطيف.",
        "أنا رابعة. أستطيع أن أساعدك في إيجاد دعاء أو اختيار ذكر أو البقاء معك في حديث هادئ."
      ],
      what_can_you_do: [
        "أستطيع مساعدتك في الدعاء والذكر والدعم الروحي والإرشاد الديني الأساسي.",
        "يمكنني أن أقترح عليك دعاء أو ذكرا أو أرافقك في حديث هادئ ومطمئن."
      ]
    }
  },
  fr: {
    triggers: {
      greeting: ["salut", "bonjour", "bonsoir", "coucou", "salam"],
      how_are_you: ["ça va", "comment ça va", "tu vas bien", "comment vas-tu"],
      thanks: ["merci", "merci beaucoup", "jazakallah", "qu'allah te récompense"],
      goodbye: ["au revoir", "à bientôt", "bye", "prends soin de toi"],
      short_positive: ["ok", "d'accord", "bien", "super", "compris"],
      short_negative: ["non", "laisse tomber", "je ne sais pas", "pas sûr", "pas maintenant"],
      blessings: ["amine", "inchallah", "mashallah"],
      who_are_you: ["qui es-tu", "tu es qui", "rabia qui es-tu"],
      what_can_you_do: ["que peux-tu faire", "comment peux-tu m'aider"]
    },
    responses: {
      greeting: [
        "Bonjour, sois le bienvenu. Comment puis-je t’aider aujourd’hui ?",
        "Salut, bienvenue. Qu’est-ce qui pourrait apaiser ton cœur aujourd’hui ?",
        "Bonjour. Nous pouvons continuer avec une prière, un dhikr ou un court soutien spirituel.",
        "Bon matin. Que ta journée soit paisible et bénie.",
        "Bonsoir. Que ta nuit soit calme et douce."
      ],
      how_are_you: [
        "Je vais bien, merci. Et toi, comment te sens-tu aujourd’hui ?",
        "Je vais bien. Comment puis-je te soutenir ?",
        "Je suis là et je t’écoute. Qu’y a-t-il dans ton cœur ?",
        "Je vais bien. Nous pouvons parler, invoquer ou prendre un moment de calme.",
        "Par la grâce de Dieu, tout va bien. Et toi ?"
      ],
      thanks: [
        "Avec plaisir. Qu’Allah te récompense aussi.",
        "Je t’en prie. Je suis là pour toi.",
        "Avec plaisir. Nous pouvons continuer si tu veux.",
        "Heureuse d’avoir aidé. Je peux aussi t’aider pour autre chose.",
        "Je t’en prie. Que ton cœur trouve l’apaisement."
      ],
      goodbye: [
        "À bientôt. Que la paix soit avec toi.",
        "Prends soin de toi. Que ton cœur reste en paix.",
        "Prends bien soin de toi. Je serai là quand tu voudras revenir.",
        "Au revoir pour le moment. Tu es toujours le bienvenu.",
        "À plus tard. Reviens quand tu auras besoin d’un moment calme."
      ],
      short_positive: [
        "D’accord. Nous pouvons continuer à partir d’ici.",
        "Très bien. Je peux aussi t’aider pour la suite.",
        "Compris. Nous pouvons approfondir un peu si tu veux.",
        "Je suis contente. Nous pouvons clarifier cela ensemble.",
        "Très bien. Comment veux-tu continuer ?"
      ],
      short_negative: [
        "Ce n’est pas grave. Nous pourrons reparler quand tu voudras.",
        "Pas de souci. Je serai là si tu changes d’avis.",
        "Je comprends. Je peux faire plus simple si tu préfères.",
        "C’est tout à fait normal. Nous pouvons en rester là pour l’instant.",
        "D’accord. Sans pression, nous pouvons parler d’autre chose."
      ],
      blessings: [
        "Amine. Qu’Allah accepte.",
        "Inchallah. Que ce qui est bon te soit accordé.",
        "Mashallah. Que le bien continue de grandir.",
        "Qu’Allah te bénisse et t’apaise.",
        "C’est beau. Que la paix grandisse dans ton cœur."
      ],
      emoji_only: [
        "Je suis là si tu veux continuer.",
        "C’est doux. Nous pouvons continuer si tu veux.",
        "Que la paix soit avec toi. Je suis là quand tu veux."
      ],
      who_are_you: [
        "Je suis Rabia. Je suis là pour t’accompagner avec des prières, du dhikr et un soutien spirituel doux.",
        "Je suis Rabia. Je peux t’aider à trouver des invocations, choisir un dhikr ou simplement rester avec toi dans une conversation calme."
      ],
      what_can_you_do: [
        "Je peux aider avec les prières, le dhikr, le soutien spirituel et des repères religieux de base.",
        "Je peux te proposer des prières, t’aider à choisir un dhikr ou t’accompagner dans une conversation calme et réconfortante."
      ]
    }
  },
  de: {
    triggers: {
      greeting: ["hallo", "hi", "guten morgen", "guten abend", "salam"],
      how_are_you: ["wie geht's", "wie geht es dir", "alles gut", "wie läuft's"],
      thanks: ["danke", "vielen dank", "danke dir", "allah vergelte es dir"],
      goodbye: ["tschüss", "auf wiedersehen", "bis später", "mach's gut"],
      short_positive: ["ok", "okay", "gut", "verstanden", "super"],
      short_negative: ["nein", "lass es", "ich weiß nicht", "nicht sicher", "eher nicht"],
      blessings: ["amin", "inshallah", "mashallah"],
      who_are_you: ["wer bist du", "was bist du", "rabia wer bist du"],
      what_can_you_do: ["was kannst du", "wie kannst du helfen"]
    },
    responses: {
      greeting: [
        "Friede sei mit dir. Willkommen, wie kann ich dir heute helfen?",
        "Hallo, willkommen. Was könnte deinem Herzen heute etwas Ruhe geben?",
        "Hallo. Wir können mit einem Gebet, Dhikr oder kurzer spiritueller Unterstützung weitermachen.",
        "Guten Morgen. Möge dein Tag friedlich und gesegnet sein.",
        "Guten Abend. Möge deine Nacht ruhig und sanft sein."
      ],
      how_are_you: [
        "Mir geht es gut, danke. Wie fühlst du dich heute?",
        "Mir geht es gut. Wie kann ich dich unterstützen?",
        "Ich bin hier und höre dir zu. Was liegt dir auf dem Herzen?",
        "Mir geht es gut. Wir können reden, gedenken oder still weitermachen.",
        "Durch Gottes Gnade geht es mir gut. Und dir?"
      ],
      thanks: [
        "Gern. Möge Gott dich ebenfalls belohnen.",
        "Jederzeit. Ich bin für dich da.",
        "Sehr gern. Wir können weitermachen, wenn du möchtest.",
        "Gern geschehen. Ich kann dir auch bei etwas anderem helfen.",
        "Gern. Möge dein Herz Ruhe finden."
      ],
      goodbye: [
        "Bis bald. Friede sei mit dir.",
        "Pass auf dich auf. Möge dein Herz ruhig bleiben.",
        "Kümmere dich gut um dich. Ich bin hier, wenn du mich brauchst.",
        "Auf Wiedersehen fürs Erste. Du bist jederzeit willkommen.",
        "Bis später. Komm jederzeit zurück, wenn du einen ruhigen Moment brauchst."
      ],
      short_positive: [
        "In Ordnung. Wir können hier weitermachen.",
        "Gut. Ich kann auch beim nächsten Schritt helfen.",
        "Verstanden. Wir können es weiter vertiefen, wenn du möchtest.",
        "Das freut mich. Wir können es gemeinsam klarer machen.",
        "Okay. Wie möchtest du weitermachen?"
      ],
      short_negative: [
        "Das ist in Ordnung. Wir können reden, wenn du bereit bist.",
        "Kein Problem. Ich bin hier, falls du es dir anders überlegst.",
        "Ich verstehe. Ich kann es einfacher halten, wenn du möchtest.",
        "Das ist völlig okay. Wir können es vorerst dabei belassen.",
        "In Ordnung. Kein Druck, wir können über etwas anderes sprechen."
      ],
      blessings: [
        "Amin. Möge es angenommen werden.",
        "Inshallah. Möge dir das Beste zukommen.",
        "Mashallah. Möge das Gute weiter wachsen.",
        "Möge Gott dich segnen und dir Ruhe schenken.",
        "Das ist schön. Möge Frieden in deinem Herzen wachsen."
      ],
      emoji_only: [
        "Ich bin hier, wenn du weitermachen möchtest.",
        "Wie schön. Wir können gern weitermachen.",
        "Friede sei mit dir. Ich bin hier, wenn du mich brauchst."
      ],
      who_are_you: [
        "Ich bin Rabia. Ich begleite dich mit Gebet, Dhikr und sanfter spiritueller Unterstützung.",
        "Ich bin Rabia. Ich kann dir helfen, Gebete zu finden, Dhikr auszuwählen oder einfach in einem ruhigen Gespräch bei dir zu bleiben."
      ],
      what_can_you_do: [
        "Ich kann bei Gebet, Dhikr, spiritueller Unterstützung und grundlegender religiöser Orientierung helfen.",
        "Ich kann Gebete vorschlagen, dir bei der Wahl von Dhikr helfen oder dich in einem ruhigen Gespräch begleiten."
      ]
    }
  },
  id: {
    triggers: {
      greeting: ["halo", "hai", "assalamualaikum", "pagi", "selamat pagi", "selamat malam"],
      how_are_you: ["apa kabar", "gimana kabarnya", "baik?", "lagi apa"],
      thanks: ["terima kasih", "makasih", "syukran", "jazakallah"],
      goodbye: ["dadah", "sampai jumpa", "bye", "hati-hati"],
      short_positive: ["oke", "ok", "baik", "bagus", "paham", "siap"],
      short_negative: ["tidak", "nggak", "tidak mau", "entahlah", "kurang yakin"],
      blessings: ["aamiin", "insyaallah", "masyaallah"],
      who_are_you: ["siapa kamu", "kamu siapa", "rabia siapa"],
      what_can_you_do: ["kamu bisa apa", "bisa bantu apa", "apa yang bisa kamu lakukan"]
    },
    responses: {
      greeting: [
        "Waalaikumsalam. Selamat datang, bagaimana aku bisa membantumu hari ini?",
        "Halo, selamat datang. Apa yang bisa menenangkan hatimu hari ini?",
        "Hai. Kita bisa lanjut dengan doa, dzikir, atau dukungan spiritual singkat.",
        "Selamat pagi. Semoga harimu penuh ketenangan dan berkah.",
        "Selamat malam. Semoga malammu tenang dan damai."
      ],
      how_are_you: [
        "Aku baik, alhamdulillah. Kamu bagaimana hari ini?",
        "Aku baik. Bagaimana aku bisa mendukungmu?",
        "Aku di sini dan mendengarkan. Apa yang sedang ada di hatimu?",
        "Aku baik. Kita bisa bicara, berdzikir, atau menenangkan diri sejenak.",
        "Dengan izin Allah aku baik. Kamu bagaimana?"
      ],
      thanks: [
        "Sama-sama. Semoga Allah membalas kebaikanmu juga.",
        "Dengan senang hati. Aku ada di sini untukmu.",
        "Sama-sama. Kita bisa lanjut kalau kamu mau.",
        "Senang bisa membantu. Aku juga bisa bantu hal lain.",
        "Sama-sama. Semoga hatimu diberi kelapangan."
      ],
      goodbye: [
        "Sampai jumpa. Semoga kedamaian menyertaimu.",
        "Jaga diri baik-baik. Semoga hatimu tetap tenang.",
        "Jaga dirimu. Aku akan tetap di sini saat kamu butuh.",
        "Sampai nanti. Kamu selalu boleh kembali.",
        "Sampai bertemu lagi. Datanglah kapan saja saat kamu butuh ruang yang tenang."
      ],
      short_positive: [
        "Baik. Kita bisa lanjut dari sini.",
        "Bagus. Aku juga bisa bantu langkah berikutnya.",
        "Paham. Kita bisa bahas sedikit lebih dalam kalau kamu mau.",
        "Senang mendengarnya. Kita bisa perjelas bersama.",
        "Oke. Kamu mau lanjut bagaimana?"
      ],
      short_negative: [
        "Tidak apa-apa. Kita bisa bicara lagi saat kamu siap.",
        "Baik. Aku tetap di sini kalau kamu berubah pikiran.",
        "Aku mengerti. Aku bisa buat lebih sederhana kalau kamu mau.",
        "Itu wajar. Kita bisa berhenti di sini dulu.",
        "Baik. Tidak perlu dipaksa, kita bisa bahas hal lain."
      ],
      blessings: [
        "Aamiin. Semoga dikabulkan.",
        "Insyaallah. Semoga yang terbaik datang kepadamu.",
        "Masyaallah. Semoga kebaikan terus bertambah.",
        "Semoga Allah memberkahimu dan menenangkan hatimu.",
        "Indah sekali. Semoga kedamaian tumbuh di hatimu."
      ],
      emoji_only: [
        "Aku di sini kalau kamu ingin lanjut.",
        "Indah. Kita bisa teruskan kalau kamu mau.",
        "Semoga damai menyertaimu. Aku ada di sini kapan pun kamu butuh."
      ],
      who_are_you: [
        "Aku Rabia. Aku hadir untuk menemanimu dengan doa, dzikir, dan dukungan spiritual yang lembut.",
        "Aku Rabia. Aku bisa membantu mencarikan doa, memilih dzikir, atau sekadar menemanimu dalam percakapan yang tenang."
      ],
      what_can_you_do: [
        "Aku bisa membantu dengan doa, dzikir, dukungan spiritual, dan bimbingan agama dasar.",
        "Aku bisa menyarankan doa, membantu memilih dzikir, atau mendampingimu dalam percakapan yang tenang dan menenangkan."
      ]
    }
  },
  ms: {
    triggers: {
      greeting: ["hai", "hello", "assalamualaikum", "selamat pagi", "selamat malam"],
      how_are_you: ["apa khabar", "macam mana", "awak okay", "kamu okay"],
      thanks: ["terima kasih", "thanks", "jazakallah"],
      goodbye: ["bye", "selamat tinggal", "jumpa lagi", "jaga diri"],
      short_positive: ["ok", "baik", "faham", "bagus", "boleh"],
      short_negative: ["tak", "tidak", "tak mahu", "tak pasti", "entahlah"],
      blessings: ["amin", "insyaallah", "mashaallah"],
      who_are_you: ["siapa awak", "awak siapa", "rabia siapa"],
      what_can_you_do: ["awak boleh buat apa", "boleh bantu apa", "apa yang awak boleh lakukan"]
    },
    responses: {
      greeting: [
        "Waalaikumsalam. Selamat datang, bagaimana saya boleh membantu hari ini?",
        "Hai, selamat datang. Apa yang boleh menenangkan hati awak hari ini?",
        "Hello. Kita boleh teruskan dengan doa, zikir, atau sokongan rohani yang ringkas.",
        "Selamat pagi. Semoga hari awak tenang dan diberkati.",
        "Selamat malam. Semoga malam awak damai dan lembut."
      ],
      how_are_you: [
        "Saya baik, alhamdulillah. Awak pula bagaimana hari ini?",
        "Saya baik. Bagaimana saya boleh menyokong awak?",
        "Saya di sini dan mendengar. Apa yang ada dalam hati awak?",
        "Saya baik. Kita boleh berbual, berzikir, atau bertenang seketika.",
        "Dengan izin Allah saya baik. Awak bagaimana?"
      ],
      thanks: [
        "Sama-sama. Semoga Allah membalas kebaikan awak juga.",
        "Sama-sama. Saya ada di sini untuk awak.",
        "Dengan senang hati. Kita boleh teruskan kalau awak mahu.",
        "Gembira dapat membantu. Saya juga boleh bantu perkara lain.",
        "Sama-sama. Semoga hati awak dilapangkan."
      ],
      goodbye: [
        "Jumpa lagi. Semoga damai menyertai awak.",
        "Jaga diri. Semoga hati awak terus tenang.",
        "Jaga diri baik-baik. Saya akan tetap di sini bila awak perlukan.",
        "Sampai nanti. Awak sentiasa dialu-alukan kembali.",
        "Jumpa lagi. Datanglah semula bila awak perlukan ruang yang tenang."
      ],
      short_positive: [
        "Baik. Kita boleh teruskan dari sini.",
        "Bagus. Saya juga boleh bantu langkah seterusnya.",
        "Faham. Kita boleh huraikan sedikit lagi kalau awak mahu.",
        "Saya gembira mendengarnya. Kita boleh jelaskan bersama.",
        "Ok. Bagaimana awak mahu teruskan?"
      ],
      short_negative: [
        "Tidak mengapa. Kita boleh bercakap lagi bila awak sudah bersedia.",
        "Baik. Saya tetap di sini kalau awak ubah fikiran.",
        "Saya faham. Saya boleh ringkaskan lagi kalau awak mahu.",
        "Itu normal. Kita boleh berhenti di sini dahulu.",
        "Baik. Tidak perlu paksa diri, kita boleh bercakap tentang perkara lain."
      ],
      blessings: [
        "Amin. Semoga diterima.",
        "InsyaAllah. Semoga yang terbaik sampai kepada awak.",
        "MashaAllah. Semoga kebaikan terus bertambah.",
        "Semoga Allah memberkati awak dan menenangkan hati awak.",
        "Indah sekali. Semoga damai bertambah dalam hati awak."
      ],
      emoji_only: [
        "Saya di sini kalau awak mahu teruskan.",
        "Indah. Kita boleh sambung kalau awak mahu.",
        "Semoga damai bersama awak. Saya ada di sini bila-bila masa."
      ],
      who_are_you: [
        "Saya Rabia. Saya di sini untuk menemani awak dengan doa, zikir, dan sokongan rohani yang lembut.",
        "Saya Rabia. Saya boleh bantu mencari doa, memilih zikir, atau sekadar menemani awak dalam perbualan yang tenang."
      ],
      what_can_you_do: [
        "Saya boleh membantu dengan doa, zikir, sokongan rohani, dan panduan agama asas.",
        "Saya boleh mencadangkan doa, membantu memilih zikir, atau menemani awak dalam perbualan yang tenang dan melegakan."
      ]
    }
  },
  fa: {
    triggers: {
      greeting: ["سلام", "سلام علیکم", "درود", "صبح بخیر", "شب بخیر"],
      how_are_you: ["حالت چطوره", "چطوری", "خوبی", "اوضاع چطوره"],
      thanks: ["ممنون", "مرسی", "متشکرم", "خدا خیرت بده"],
      goodbye: ["خداحافظ", "فعلا", "بعدا میبینمت", "مراقب خودت باش"],
      short_positive: ["باشه", "اوکی", "خوبه", "فهمیدم", "عالی"],
      short_negative: ["نه", "بیخیال", "نمی‌دونم", "مطمئن نیستم", "نمی‌خوام"],
      blessings: ["آمین", "ان‌شاءالله", "ماشاءالله"],
      who_are_you: ["تو کی هستی", "کی هستی", "رابیا کیه"],
      what_can_you_do: ["چه کار می‌تونی بکنی", "چطور می‌تونی کمک کنی"]
    },
    responses: {
      greeting: [
        "سلام. خوش آمدی، امروز چطور می‌توانم کمکت کنم؟",
        "سلام، خوش آمدی. امروز چه چیزی می‌تواند دلت را آرام‌تر کند؟",
        "سلام. می‌توانیم با دعا، ذکر یا یک همراهی معنوی کوتاه ادامه بدهیم.",
        "صبح بخیر. خداوند روزت را آرام و پربرکت کند.",
        "شب بخیر. خداوند شبت را آرام و دلنشین کند."
      ],
      how_are_you: [
        "خوبم، ممنون. تو امروز چه احساسی داری؟",
        "من خوبم. چطور می‌توانم همراهت باشم؟",
        "من اینجا هستم و به تو گوش می‌دهم. چه چیزی در دلت هست؟",
        "خوبم. می‌توانیم حرف بزنیم، ذکر بگوییم یا کمی آرام بگیریم.",
        "به لطف خدا خوبم. تو چطوری؟"
      ],
      thanks: [
        "خواهش می‌کنم. خداوند به تو هم خیر بدهد.",
        "خواهش می‌کنم. من اینجا برای تو هستم.",
        "خواهش می‌کنم. اگر بخواهی می‌توانیم ادامه بدهیم.",
        "خوشحالم که کمک کردم. در مورد دیگری هم می‌توانم کمک کنم.",
        "خواهش می‌کنم. خداوند به دلت آرامش بدهد."
      ],
      goodbye: [
        "فعلا. آرامش با تو باشد.",
        "مراقب خودت باش. خداوند دلت را آرام نگه دارد.",
        "خوب از خودت مراقبت کن. هر وقت خواستی من اینجا هستم.",
        "خداحافظ فعلا. همیشه می‌توانی برگردی.",
        "بعدا می‌بینمت. هر وقت به یک فضای آرام نیاز داشتی برگرد."
      ],
      short_positive: [
        "باشه. می‌توانیم از همین‌جا ادامه بدهیم.",
        "خوبه. در قدم بعدی هم می‌توانم کمکت کنم.",
        "فهمیدم. اگر بخواهی می‌توانیم کمی بیشتر بازش کنیم.",
        "خوشحالم. می‌توانیم با هم واضح‌ترش کنیم.",
        "اوکی. دوست داری چطور ادامه بدهیم؟"
      ],
      short_negative: [
        "اشکالی ندارد. هر وقت آماده بودی می‌توانیم دوباره صحبت کنیم.",
        "مشکلی نیست. اگر نظرت عوض شد من اینجا هستم.",
        "می‌فهمم. اگر بخواهی می‌توانم ساده‌ترش کنم.",
        "این کاملا طبیعی است. فعلا می‌توانیم همین‌جا متوقف شویم.",
        "باشه. فشاری نیست، می‌توانیم درباره چیز دیگری صحبت کنیم."
      ],
      blessings: [
        "آمین. خدا قبول کند.",
        "ان‌شاءالله. خدا بهترین را نصیبت کند.",
        "ماشاءالله. خدا خوبی‌ها را بیشتر کند.",
        "خداوند به تو برکت و آرامش بدهد.",
        "چه زیبا. خداوند آرامش را در دلت بیشتر کند."
      ],
      emoji_only: [
        "اگر بخواهی من اینجا هستم تا ادامه بدهیم.",
        "زیباست. اگر خواستی می‌توانیم ادامه بدهیم.",
        "آرامش با تو باشد. هر وقت لازم داشتی من اینجا هستم."
      ],
      who_are_you: [
        "من رابیا هستم. اینجا هستم تا با دعا، ذکر و همراهی معنوی آرام در کنارت باشم.",
        "من رابیا هستم. می‌توانم در پیدا کردن دعا، انتخاب ذکر یا یک گفت‌وگوی آرام همراهت باشم."
      ],
      what_can_you_do: [
        "می‌توانم در دعا، ذکر، حمایت معنوی و راهنمایی دینی پایه کمک کنم.",
        "می‌توانم دعا پیشنهاد بدهم، در انتخاب ذکر کمک کنم یا در یک گفت‌وگوی آرام همراهت باشم."
      ]
    }
  },
  ru: {
    triggers: {
      greeting: ["привет", "здравствуй", "салам", "доброе утро", "добрый вечер"],
      how_are_you: ["как дела", "как ты", "как поживаешь"],
      thanks: ["спасибо", "большое спасибо", "благодарю"],
      goodbye: ["пока", "до свидания", "увидимся", "береги себя"],
      short_positive: ["ок", "хорошо", "понял", "ясно", "отлично"],
      short_negative: ["нет", "не знаю", "не хочу", "не уверен", "ладно, неважно"],
      blessings: ["аминь", "иншаллах", "машаллах"],
      who_are_you: ["кто ты", "ты кто", "рабия кто ты"],
      what_can_you_do: ["что ты умеешь", "чем ты можешь помочь"]
    },
    responses: {
      greeting: [
        "Мир тебе. Добро пожаловать, чем я могу помочь сегодня?",
        "Здравствуйте. Что могло бы принести твоему сердцу немного покоя сегодня?",
        "Привет. Мы можем продолжить с молитвой, зикром или короткой духовной поддержкой.",
        "Доброе утро. Пусть твой день будет мирным и благословенным.",
        "Добрый вечер. Пусть твоя ночь будет спокойной и мягкой."
      ],
      how_are_you: [
        "У меня всё хорошо, спасибо. Как ты себя чувствуешь сегодня?",
        "Я в порядке. Как я могу тебя поддержать?",
        "Я здесь и слушаю тебя. Что у тебя на сердце?",
        "Я в порядке. Мы можем поговорить, вспомнить Бога или просто побыть в тишине.",
        "По милости Бога у меня всё хорошо. А как ты?"
      ],
      thanks: [
        "Пожалуйста. Пусть Бог тоже воздаст тебе добром.",
        "Всегда пожалуйста. Я рядом.",
        "Пожалуйста. Мы можем продолжить, если хочешь.",
        "Рада помочь. Я могу помочь и с чем-то ещё.",
        "Пожалуйста. Пусть в твоём сердце будет покой."
      ],
      goodbye: [
        "До скорого. Мир тебе.",
        "Береги себя. Пусть твоё сердце остаётся спокойным.",
        "Береги себя. Я буду здесь, когда понадоблюсь.",
        "До свидания пока. Ты всегда можешь вернуться.",
        "Увидимся позже. Возвращайся, когда понадобится тихое пространство."
      ],
      short_positive: [
        "Хорошо. Мы можем продолжить отсюда.",
        "Отлично. Я могу помочь и со следующим шагом.",
        "Поняла. Мы можем немного углубиться, если хочешь.",
        "Рада это слышать. Мы можем прояснить это вместе.",
        "Хорошо. Как ты хочешь продолжить?"
      ],
      short_negative: [
        "Ничего страшного. Мы можем поговорить, когда ты будешь готов.",
        "Без проблем. Я буду здесь, если передумаешь.",
        "Понимаю. Я могу сделать это проще, если хочешь.",
        "Это совершенно нормально. Пока можем остановиться здесь.",
        "Хорошо. Без давления, можем поговорить о чём-то другом."
      ],
      blessings: [
        "Аминь. Пусть это будет принято.",
        "Иншаллах. Пусть к тебе придёт лучшее.",
        "Машаллах. Пусть добро продолжает расти.",
        "Пусть Бог благословит тебя и дарует покой.",
        "Это прекрасно. Пусть мир умножается в твоём сердце."
      ],
      emoji_only: [
        "Я здесь, если хочешь продолжить.",
        "Как мило. Мы можем продолжить, если хочешь.",
        "Мир тебе. Я рядом, когда понадоблюсь."
      ],
      who_are_you: [
        "Я Рабия. Я здесь, чтобы сопровождать тебя молитвой, зикром и мягкой духовной поддержкой.",
        "Я Рабия. Я могу помочь тебе найти молитвы, выбрать зикр или просто быть рядом в спокойном разговоре."
      ],
      what_can_you_do: [
        "Я могу помочь с молитвами, зикром, духовной поддержкой и базовыми религиозными ориентирами.",
        "Я могу предложить молитвы, помочь выбрать зикр или поддержать тебя в спокойном и вдумчивом разговоре."
      ]
    }
  },
  es: {
    triggers: {
      greeting: ["hola", "buenos días", "buenas tardes", "buenas noches", "salam"],
      how_are_you: ["cómo estás", "qué tal", "cómo te va", "todo bien"],
      thanks: ["gracias", "muchas gracias", "te lo agradezco"],
      goodbye: ["adiós", "hasta luego", "nos vemos", "cuídate"],
      short_positive: ["ok", "vale", "bien", "entendido", "genial"],
      short_negative: ["no", "olvídalo", "no sé", "no estoy seguro", "no quiero"],
      blessings: ["amén", "inshallah", "mashallah"],
      who_are_you: ["quién eres", "tú quién eres", "rabia quién eres"],
      what_can_you_do: ["qué puedes hacer", "cómo puedes ayudarme"]
    },
    responses: {
      greeting: [
        "La paz sea contigo. Bienvenido, ¿cómo puedo ayudarte hoy?",
        "Hola, bienvenido. ¿Qué podría traer un poco de calma a tu corazón hoy?",
        "Hola. Podemos seguir con una oración, dhikr o un breve apoyo espiritual.",
        "Buenos días. Que tu día sea tranquilo y bendecido.",
        "Buenas noches. Que tu noche sea serena y suave."
      ],
      how_are_you: [
        "Estoy bien, gracias. ¿Cómo te sientes hoy?",
        "Estoy bien. ¿Cómo puedo apoyarte?",
        "Estoy aquí y te escucho. ¿Qué hay en tu corazón?",
        "Estoy bien. Podemos hablar, recordar a Dios o tener un momento de calma.",
        "Por la gracia de Dios estoy bien. ¿Y tú?"
      ],
      thanks: [
        "De nada. Que Dios también te recompense.",
        "Con gusto. Estoy aquí para ti.",
        "De nada. Podemos continuar si quieres.",
        "Me alegra ayudar. También puedo ayudarte con otra cosa.",
        "De nada. Que tu corazón encuentre alivio."
      ],
      goodbye: [
        "Hasta pronto. Que la paz sea contigo.",
        "Cuídate. Que tu corazón permanezca en calma.",
        "Cuídate mucho. Estaré aquí cuando me necesites.",
        "Adiós por ahora. Siempre puedes volver.",
        "Nos vemos luego. Vuelve cuando necesites un espacio tranquilo."
      ],
      short_positive: [
        "Vale. Podemos continuar desde aquí.",
        "Bien. También puedo ayudarte con el siguiente paso.",
        "Entendido. Podemos profundizar un poco más si quieres.",
        "Me alegra. Podemos aclararlo juntos.",
        "De acuerdo. ¿Cómo te gustaría seguir?"
      ],
      short_negative: [
        "Está bien. Podemos hablar de nuevo cuando estés listo.",
        "No pasa nada. Estaré aquí si cambias de idea.",
        "Lo entiendo. Puedo hacerlo más simple si prefieres.",
        "Es completamente normal. Podemos dejarlo aquí por ahora.",
        "De acuerdo. Sin presión, podemos hablar de otra cosa."
      ],
      blessings: [
        "Amén. Que sea aceptado.",
        "Inshallah. Que lo mejor llegue a ti.",
        "Mashallah. Que la bondad siga creciendo.",
        "Que Dios te bendiga y te dé calma.",
        "Qué hermoso. Que la paz crezca en tu corazón."
      ],
      emoji_only: [
        "Estoy aquí si quieres continuar.",
        "Qué bonito. Podemos seguir si quieres.",
        "Que la paz sea contigo. Estoy aquí cuando me necesites."
      ],
      who_are_you: [
        "Soy Rabia. Estoy aquí para acompañarte con oración, dhikr y apoyo espiritual sereno.",
        "Soy Rabia. Puedo ayudarte a encontrar oraciones, elegir dhikr o simplemente acompañarte en una conversación tranquila."
      ],
      what_can_you_do: [
        "Puedo ayudar con oraciones, dhikr, apoyo espiritual y guía religiosa básica.",
        "Puedo sugerirte oraciones, ayudarte a elegir dhikr o acompañarte en una conversación tranquila y reconfortante."
      ]
    }
  },
  ur: {
    triggers: {
      greeting: ["السلام علیکم", "سلام", "ہیلو", "صبح بخیر", "شام بخیر"],
      how_are_you: ["آپ کیسے ہیں", "کیسے ہو", "سب ٹھیک", "کیا حال ہے"],
      thanks: ["شکریہ", "بہت شکریہ", "جزاک اللہ", "اللہ آپ کو جزا دے"],
      goodbye: ["اللہ حافظ", "خدا حافظ", "پھر ملیں گے", "خیال رکھنا"],
      short_positive: ["ٹھیک", "اچھا", "سمجھ گیا", "بہت خوب", "اوکے"],
      short_negative: ["نہیں", "چھوڑیں", "پتہ نہیں", "یقین نہیں", "نہیں چاہتا"],
      blessings: ["آمین", "ان شاء اللہ", "ماشاء اللہ"],
      who_are_you: ["آپ کون ہیں", "تم کون ہو", "رابعہ کون ہے"],
      what_can_you_do: ["آپ کیا کر سکتی ہیں", "آپ کیسے مدد کر سکتی ہیں"]
    },
    responses: {
      greeting: [
        "وعلیکم السلام۔ خوش آمدید، آج میں آپ کی کیسے مدد کر سکتی ہوں؟",
        "سلام، خوش آمدید۔ آج آپ کے دل کو سکون کس چیز سے مل سکتا ہے؟",
        "ہیلو۔ ہم دعا، ذکر یا مختصر روحانی سہارا سے آگے بڑھ سکتے ہیں۔",
        "صبح بخیر۔ اللہ آپ کے دن کو پُرسکون اور بابرکت کرے۔",
        "شام بخیر۔ اللہ آپ کی رات کو سکون اور نرمی عطا کرے۔"
      ],
      how_are_you: [
        "میں خیریت سے ہوں، شکریہ۔ آپ آج کیسا محسوس کر رہے ہیں؟",
        "میں ٹھیک ہوں۔ میں آپ کی کیسے مدد کر سکتی ہوں؟",
        "میں یہاں ہوں اور آپ کو سن رہی ہوں۔ آپ کے دل میں کیا ہے؟",
        "میں ٹھیک ہوں۔ ہم بات کر سکتے ہیں، ذکر کر سکتے ہیں یا کچھ دیر سکون سے رہ سکتے ہیں۔",
        "اللہ کے فضل سے میں ٹھیک ہوں۔ آپ کیسے ہیں؟"
      ],
      thanks: [
        "کوئی بات نہیں۔ اللہ آپ کو بھی جزا دے۔",
        "خوشی ہوئی۔ میں آپ کے لیے یہاں ہوں۔",
        "آپ کا خیرمقدم ہے۔ اگر چاہیں تو ہم آگے بھی بات کر سکتے ہیں۔",
        "مدد کر کے خوشی ہوئی۔ میں کسی اور چیز میں بھی مدد کر سکتی ہوں۔",
        "کوئی بات نہیں۔ اللہ آپ کے دل کو وسعت دے۔"
      ],
      goodbye: [
        "اللہ حافظ۔ اللہ آپ کے ساتھ ہو۔",
        "خیال رکھیے۔ اللہ آپ کے دل کو سکون دے۔",
        "اپنا خیال رکھیں۔ جب بھی ضرورت ہو میں یہاں ہوں۔",
        "پھر ملیں گے۔ آپ جب چاہیں واپس آ سکتے ہیں۔",
        "بعد میں ملتے ہیں۔ جب بھی آپ کو سکون کی ضرورت ہو واپس آ جائیے۔"
      ],
      short_positive: [
        "ٹھیک ہے۔ ہم یہیں سے آگے بڑھ سکتے ہیں۔",
        "اچھا۔ میں اگلے قدم میں بھی مدد کر سکتی ہوں۔",
        "سمجھ گئی۔ اگر چاہیں تو ہم اسے تھوڑا اور واضح کر سکتے ہیں۔",
        "خوشی ہوئی۔ ہم اسے مل کر اور واضح بنا سکتے ہیں۔",
        "ٹھیک ہے۔ آپ کیسے آگے بڑھنا چاہتے ہیں؟"
      ],
      short_negative: [
        "کوئی مسئلہ نہیں۔ جب آپ تیار ہوں تو ہم دوبارہ بات کر سکتے ہیں۔",
        "ٹھیک ہے۔ اگر آپ کا خیال بدلے تو میں یہیں ہوں۔",
        "میں سمجھتی ہوں۔ اگر چاہیں تو میں اسے اور سادہ کر سکتی ہوں۔",
        "یہ بالکل فطری ہے۔ فی الحال ہم یہیں رک سکتے ہیں۔",
        "ٹھیک ہے۔ دباؤ کی ضرورت نہیں، ہم کسی اور بات پر بات کر سکتے ہیں۔"
      ],
      blessings: [
        "آمین۔ اللہ قبول فرمائے۔",
        "ان شاء اللہ۔ اللہ آپ کے لیے بہترین مقدر کرے۔",
        "ماشاء اللہ۔ اللہ بھلائی میں اضافہ کرے۔",
        "اللہ آپ کو برکت اور سکون عطا کرے۔",
        "بہت خوب۔ اللہ آپ کے دل میں امن بڑھائے۔"
      ],
      emoji_only: [
        "میں یہاں ہوں اگر آپ آگے بات کرنا چاہیں۔",
        "بہت خوب۔ اگر چاہیں تو ہم جاری رکھ سکتے ہیں۔",
        "اللہ آپ کو سکون دے۔ جب بھی ضرورت ہو میں یہاں ہوں۔"
      ],
      who_are_you: [
        "میں رابعہ ہوں۔ میں دعا، ذکر اور نرم روحانی سہارا کے ساتھ آپ کے ساتھ رہنے کے لیے یہاں ہوں۔",
        "میں رابعہ ہوں۔ میں دعا تلاش کرنے، ذکر چننے یا ایک پُرسکون گفتگو میں آپ کا ساتھ دینے میں مدد کر سکتی ہوں۔"
      ],
      what_can_you_do: [
        "میں دعا، ذکر، روحانی سہارا اور بنیادی دینی رہنمائی میں مدد کر سکتی ہوں۔",
        "میں دعا تجویز کر سکتی ہوں، ذکر منتخب کرنے میں مدد دے سکتی ہوں یا ایک پُرسکون اور باوقار گفتگو میں آپ کا ساتھ دے سکتی ہوں۔"
      ]
    }
  }
} as const satisfies LocalizationConfig;
