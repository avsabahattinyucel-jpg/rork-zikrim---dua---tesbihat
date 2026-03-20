import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, "..");
const DATA_DIR = path.join(ROOT, "ZikrimDuaVeTesbihat", "Data", "PrayerContent");

const LANGUAGES = ["tr", "ar", "en", "fr", "de", "id", "ms", "fa", "ru", "es", "ur"];

const NOTES_BY_LANGUAGE = {
  tr: [
    "Metinler uygulama kullanımı için kısa tutulmuştur.",
    "Ayet ve hadis metinleri birebir tam tercüme değil, çoğunlukla kısa anlam aktarımıdır.",
    "Üretim ortamında kaynak doğrulaması ve dini editör kontrolü önerilir."
  ],
  ar: [
    "أُبقيت النصوص قصيرة لتناسب الاستخدام داخل التطبيق.",
    "نصوص الآيات والأحاديث هنا صيغ موجزة للمعنى وليست ترجمات حرفية كاملة.",
    "يُنصح بالتحقق من المصادر ومراجعتها من محرر ديني مؤهل قبل الاستخدام في بيئة الإنتاج."
  ],
  en: [
    "The texts are intentionally kept short for mobile app use.",
    "Quran verse and hadith texts are concise meaning-based renderings, not full literal translations.",
    "Source verification and review by a qualified religious editor are recommended before production use."
  ],
  fr: [
    "Les textes sont volontairement courts pour un usage dans l'application mobile.",
    "Les textes de versets et de hadiths sont des reformulations brèves du sens, non des traductions littérales intégrales.",
    "Avant un usage en production, une vérification des sources et une relecture par un éditeur religieux qualifié sont recommandées."
  ],
  de: [
    "Die Texte sind bewusst kurz für die Nutzung in der mobilen App gehalten.",
    "Die Vers- und Hadithtexte sind knappe sinngemäße Wiedergaben und keine vollständigen wörtlichen Übersetzungen.",
    "Vor dem Einsatz in Produktion werden Quellenprüfung und die Durchsicht durch eine qualifizierte religiöse Redaktion empfohlen."
  ],
  id: [
    "Teks dibuat singkat agar sesuai untuk penggunaan di aplikasi seluler.",
    "Teks ayat dan hadis di sini adalah ringkasan makna, bukan terjemahan harfiah penuh.",
    "Sebelum digunakan di lingkungan produksi, disarankan verifikasi sumber dan peninjauan oleh editor keagamaan yang kompeten."
  ],
  ms: [
    "Teks ini diringkaskan agar sesuai untuk penggunaan dalam aplikasi mudah alih.",
    "Teks ayat dan hadis di sini ialah ringkasan makna, bukan terjemahan harfiah sepenuhnya.",
    "Sebelum digunakan dalam persekitaran produksi, disyorkan semakan sumber dan penelitian oleh editor agama yang berkelayakan."
  ],
  fa: [
    "متن‌ها برای استفاده در اپلیکیشن کوتاه نگه داشته شده‌اند.",
    "متن آیات و احادیث ترجمه لفظ‌به‌لفظ کامل نیست، بلکه بیشتر بازنویسی کوتاهِ معناست.",
    "پیش از استفاده در محیط تولید، بررسی منبع و بازبینی توسط ویراستار دینیِ متخصص توصیه می‌شود."
  ],
  ru: [
    "Тексты намеренно сделаны короткими для использования в мобильном приложении.",
    "Тексты аятов и хадисов здесь передают смысл кратко и не являются полными дословными переводами.",
    "Перед использованием в продакшене рекомендуется проверить источники и провести религиозную редакторскую вычитку."
  ],
  es: [
    "Los textos se han mantenido breves para su uso en la aplicación móvil.",
    "Los textos de aleyas y hadices son versiones breves del sentido, no traducciones literales completas.",
    "Antes de usarlos en producción, se recomienda verificar las fuentes y revisarlos con un editor religioso cualificado."
  ],
  ur: [
    "متن کو موبائل ایپ میں استعمال کے لیے مختصر رکھا گیا ہے۔",
    "آیات اور احادیث کے متون لفظی اور مکمل ترجمے نہیں بلکہ زیادہ تر مختصر مفہومی تعبیرات ہیں۔",
    "پروڈکشن میں استعمال سے پہلے ماخذ کی جانچ اور کسی مستند دینی مدیر سے نظرِ ثانی کی سفارش کی جاتی ہے۔"
  ]
};

const TEXT_OVERRIDES = {
  en: {
    sabah: {
      1: "O Allah, begin my day with goodness, abundance, and well-being."
    },
    ogle: {
      24: "A Muslim is one from whose hand and tongue people are safe.",
      43: "Speak of your Lord's blessing."
    },
    ikindi: {
      11: "Be steadfast in the middle prayer.",
      12: "For those who do good is the best reward and more.",
      20: "Do not lose heart and do not grieve; if you are believers, you will prevail.",
      21: "Whoever neglects the Asr prayer, it is as though his deeds were lost.",
      27: "Keeping family ties brings blessing to life.",
      28: "Even if the Last Hour comes while you have a sapling in your hand, plant it."
    },
    aksam: {
      1: "O Allah, let this evening pass in safety, peace, and well-being.",
      14: "Surely your Lord's grasp is severe.",
      47: "He is the One who made the night for your rest."
    },
    yatsi: {
      14: "Indeed, rising by night is more effective.",
      24: "When you go to bed, lie on your right side and make dua.",
      26: "Whoever sleeps in a state of ablution, an angel prays for him through the night.",
      29: "O people, pray at night while others sleep; you will enter Paradise in peace.",
      30: "A servant is nearest to his Lord while in prostration."
    },
  },
  de: {
    sabah: {
      1: "O Allah, lass meinen Tag mit Gutem, Segen und Wohlergehen beginnen.",
      5: "O Allah, schenke mir halal erworbenen Rizq und reine Absichten."
    },
    ogle: {
      24: "Ein Muslim ist jemand, vor dessen Hand und Zunge die Menschen sicher sind.",
      43: "Erzaehle von der Gabe deines Herrn."
    },
    ikindi: {
      11: "Bewahrt das mittlere Gebet.",
      12: "Fuer diejenigen, die Gutes tun, gibt es das Beste und noch mehr.",
      20: "Verliert nicht den Mut und seid nicht traurig; wenn ihr glaubt, werdet ihr ueberlegen sein.",
      21: "Wer das Asr-Gebet vernachlaessigt, dessen Werke sind, als waeren sie verloren.",
      27: "Das Pflegen der Verwandtschaftsbande bringt Segen ins Leben.",
      28: "Selbst wenn die Stunde anbricht und du einen Setzling in der Hand hast, pflanze ihn."
    },
    aksam: {
      1: "O Allah, lass diesen Abend in Sicherheit, Frieden und Wohlergehen vergehen.",
      14: "Gewiss, der Zugriff deines Herrn ist gewaltig.",
      47: "Er ist es, der die Nacht fuer eure Ruhe gemacht hat."
    },
    yatsi: {
      14: "Das naechtliche Aufstehen ist gewiss eindringlicher.",
      24: "Wenn du zu Bett gehst, lege dich auf die rechte Seite und sprich ein Dua.",
      26: "Wer im Zustand der rituellen Reinheit schlaeft, fuer den bittet ein Engel in der Nacht.",
      29: "O ihr Menschen, betet in der Nacht, waehrend andere schlafen; ihr werdet in Frieden das Paradies betreten.",
      30: "Am naechsten ist der Diener seinem Herrn im Zustand der Niederwerfung."
    }
  },
  fr: {
    sabah: {
      1: "O Allah, commence ma journee avec bonte, abondance et bien-etre."
    },
    ogle: {
      24: "Un musulman est celui dont les gens sont a l'abri de sa main et de sa langue.",
      43: "Rappelle la grace de ton Seigneur."
    },
    ikindi: {
      11: "Preservez la priere mediane.",
      12: "Pour ceux qui font le bien, il y a la meilleure recompense et davantage.",
      20: "Ne faiblissez pas et ne vous attristez pas; si vous etes croyants, vous aurez le dessus.",
      21: "Celui qui delaisse la priere d'Asr, c'est comme si ses oeuvres avaient ete perdues.",
      27: "Le maintien des liens de parente apporte benediction a la vie."
    },
    aksam: {
      1: "O Allah, fais passer cette soiree dans la securite, la paix et le bien-etre.",
      14: "Certes, la prise de ton Seigneur est redoutable.",
      47: "C'est Lui qui vous accorde le sommeil pendant la nuit."
    },
    yatsi: {
      14: "Le lever de nuit est certes plus marquant.",
      24: "Quand tu vas te coucher, allonge-toi sur le cote droit et invoque Allah.",
      26: "Celui qui dort en etat d'ablution, un ange prie pour lui durant la nuit.",
      29: "O gens, priez la nuit pendant que les autres dorment; vous entrerez au Paradis en paix.",
      30: "Le serviteur est au plus pres de son Seigneur lorsqu'il est en prosternation."
    }
  },
  ms: {
    sabah: {
      1: "Ya Allah, mulakan hariku dengan kebaikan, keberkatan dan afiat."
    },
    ogle: {
      24: "Seorang Muslim ialah orang yang manusia selamat daripada tangan dan lidahnya.",
      43: "Sebutlah nikmat Tuhanmu."
    },
    ikindi: {
      11: "Peliharalah solat pertengahan.",
      12: "Bagi orang yang berbuat ihsan ada kebaikan yang lebih besar dan tambahan.",
      20: "Jangan lemah dan jangan bersedih; jika kamu beriman, kamulah yang lebih tinggi darjatnya.",
      21: "Sesiapa yang meninggalkan solat Asar, seolah-olah amalnya menjadi sia-sia.",
      27: "Menjaga silaturahim membawa berkat kepada kehidupan.",
      28: "Walaupun kiamat tiba, jika kamu mempunyai anak pokok di tanganmu, tanamlah."
    },
    aksam: {
      1: "Ya Allah, lalukan petang ini untukku dengan keselamatan, ketenangan dan afiat.",
      14: "Sesungguhnya cengkaman Tuhanmu sangat keras.",
      47: "Dialah yang menjadikan malam untuk kamu beristirahat."
    },
    yatsi: {
      14: "Sesungguhnya bangun malam itu lebih berkesan.",
      21: "Sesiapa yang menunaikan solat Isyak dan Subuh secara berjemaah, seolah-olah dia beribadah sepanjang malam.",
      24: "Apabila kamu masuk ke tempat tidur, berbaringlah di sebelah kananmu dan berdoalah.",
      26: "Sesiapa yang tidur dalam keadaan berwuduk, malaikat akan mendoakannya sepanjang malam."
    }
  },
  fa: {
    sabah: {
      1: "خدایا روزم را با خیر، برکت و عافیت آغاز کن.",
      11: "«قرآنِ صبح مورد گواهی است.»",
      12: "«پیش از طلوع خورشید، پروردگارت را با حمد تسبیح کن.»"
    },
    ogle: {
      19: "«بی‌گمان خداوند به اعمال شما آگاه است.»",
      20: "«بی‌گمان خداوند اسراف‌کنندگان را دوست ندارد.»",
      24: "«مسلمان کسی است که مردم از دست و زبان او در امان باشند.»",
      42: "«همانا خداوند بسیار آمرزنده و مهربان است.»",
      43: "«و نعمت پروردگارت را بازگو کن.»"
    },
    ikindi: {
      11: "«بر نماز میانه مراقبت کنید.»",
      12: "«برای نیکوکاران بهترین پاداش و افزونی است.»",
      20: "«سست نشوید و اندوهگین مباشید؛ اگر ایمان داشته باشید، شما برترید.»",
      21: "«هر کس نماز عصر را ترک کند، گویی اعمالش تباه شده است.»",
      27: "«صله رحم به زندگی برکت می‌بخشد.»",
      49: "«خداوند بهترین نگهبان است.»"
    },
    aksam: {
      1: "خدایا این شام را با امنیت، آرامش و عافیت بر من بگذران.",
      14: "«بی‌گمان گرفتن پروردگارت سخت است.»",
      47: "«اوست که شب را برای آرامش شما قرار داد.»"
    },
    yatsi: {
      14: "«بی‌گمان برخاستن در شب اثرگذارتر است.»",
      24: "«هنگام رفتن به بستر، بر پهلوی راست بخواب و دعا کن.»",
      26: "«هر کس با وضو بخوابد، فرشته‌ای در طول شب برای او دعا می‌کند.»",
      30: "«بنده در حال سجده از همه حال به پروردگارش نزدیک‌تر است.»"
    }
  },
  ur: {
    sabah: {
      1: "اے اللہ، میرے دن کی ابتدا خیر، برکت اور عافیت کے ساتھ فرما۔"
    },
    ogle: {
      24: "مسلمان وہ ہے جس کے ہاتھ اور زبان سے لوگ محفوظ رہیں۔",
      43: "اپنے رب کی نعمت کا بیان کرتے رہو۔"
    }
    ,
    ikindi: {
      11: "درمیانی نماز کی حفاظت کرو۔",
      12: "نیکی کرنے والوں کے لیے بہترین اجر اور مزید بھی ہے۔",
      20: "کمزور نہ پڑو اور غم نہ کرو؛ اگر تم ایمان والے ہو تو تم ہی غالب رہو گے۔",
      21: "جس نے عصر کی نماز چھوڑ دی، گویا اس کے اعمال ضائع ہوگئے۔",
      27: "صلہ رحمی زندگی میں برکت لاتی ہے۔",
      28: "اگر قیامت قائم ہو جائے اور تمہارے ہاتھ میں ایک پودا ہو تو اسے لگا دو۔"
    },
    aksam: {
      1: "اے اللہ، اس شام کو سلامتی، سکون اور عافیت کے ساتھ گزار دے۔",
      14: "بے شک تیرے رب کی پکڑ بہت سخت ہے۔",
      47: "وہی ہے جو رات کو تمہارے لیے آرام کا سبب بناتا ہے۔"
    },
    yatsi: {
      14: "بے شک رات کا اٹھنا زیادہ اثر رکھتا ہے۔",
      24: "جب بستر پر جاؤ تو دائیں کروٹ لیٹ کر دعا کرو۔",
      26: "جو شخص باوضو سوتا ہے، رات بھر فرشتہ اس کے لیے دعا کرتا ہے۔",
      30: "بندہ اپنے رب کے سب سے زیادہ قریب سجدے کی حالت میں ہوتا ہے۔"
    }
  }
};

for (const language of LANGUAGES) {
  const filePath = path.join(DATA_DIR, `prayer_content_${language}.json`);
  const payload = JSON.parse(await readFile(filePath, "utf8"));

  payload.notes = NOTES_BY_LANGUAGE[language] ?? payload.notes;

  for (const [category, items] of Object.entries(payload.categories)) {
    for (const item of items) {
      item.text = cleanupText(language, item.text);

      const override = TEXT_OVERRIDES[language]?.[category]?.[item.id];
      if (override) {
        item.text = override;
      }
    }
  }

  await writeFile(filePath, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
  console.log(`Refined ${path.basename(filePath)}`);
}

function cleanupText(language, text) {
  let value = String(text ?? "").trim();

  value = value.replace(/\s*\[$/, "");
  value = value.replace(/""/g, "\"");
  value = value.replace(/^"\s*(.*?)\s*"$/u, "\"$1\"");
  value = value.replace(/^“\s*(.*?)\s*”$/u, "“$1”");
  value = value.replace(/\s+/g, " ").trim();

  if (language === "ar") {
    value = value.replace(/^"(.*)"$/u, "«$1»");
  }

  return value;
}
