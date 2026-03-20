export const APP_KNOWLEDGE = Object.freeze({
  sections: [
    {
      id: "home_daily",
      label: "Home / Daily screen",
      guidance: "daily cards, reminders, and the main home flow"
    },
    {
      id: "prayer_times",
      label: "Prayer Times",
      guidance: "daily prayer times and prayer detail"
    },
    {
      id: "dhikr_tasbih",
      label: "Dhikr / Tasbih",
      guidance: "tasbih counters, dhikr lists, and dhikr flow"
    },
    {
      id: "dua",
      label: "Dua",
      guidance: "daily duas and dua reading"
    },
    {
      id: "rabia_chat",
      label: "Rabia Chat",
      guidance: "the in-app Islamic assistant chat"
    },
    {
      id: "khutbah_summary",
      label: "Khutbah Summary",
      guidance: "weekly stored khutbah summary"
    },
    {
      id: "quran_listening",
      label: "Quran Listening",
      guidance: "Quran audio and listening flow"
    },
    {
      id: "rehber",
      label: "Rehber",
      guidance: "guided religious reference content"
    }
  ]
});

const APP_SECTION_KEYWORDS = [
  "home",
  "daily",
  "ana sayfa",
  "günlük",
  "gunluk",
  "prayer times",
  "namaz vakitleri",
  "vakit",
  "dhikr",
  "zikir",
  "tesbih",
  "dua",
  "rabia",
  "chat",
  "khutbah",
  "hutbe",
  "quran",
  "kuran",
  "rehber"
];

const APP_NAV_INTENT_KEYWORDS = [
  "where",
  "where is",
  "where can i find",
  "how do i find",
  "how can i open",
  "nerede",
  "hangi bölüm",
  "hangi bolum",
  "nasıl bulurum",
  "nasil bulurum",
  "nasıl açarım",
  "nasil acabilirim",
  "hangi ekranda",
  "which section",
  "screen",
  "section",
  "bölüm",
  "bolum",
  "tab",
  "sekme",
  "sayfa",
  "git",
  "bul",
  "ac"
];

const ISLAMIC_TOPIC_KEYWORDS = [
  "allah",
  "dua",
  "zikir",
  "tesbih",
  "dhikr",
  "namaz",
  "salat",
  "salah",
  "oruç",
  "oruc",
  "fasting",
  "ramadan",
  "ramazan",
  "zekat",
  "sadaka",
  "hac",
  "umre",
  "kuran",
  "quran",
  "ayet",
  "hadis",
  "hadith",
  "sunnet",
  "sünnet",
  "haram",
  "helal",
  "caiz",
  "günah",
  "gunah",
  "sevap",
  "tevbe",
  "tövbe",
  "istiğfar",
  "istigfar",
  "fetva",
  "diyanet",
  "rehber",
  "ibadet",
  "iman",
  "abdest",
  "gusül",
  "gusul",
  "hayız",
  "hayiz",
  "nifas",
  "mahrem",
  "nikah",
  "evlilik",
  "cuma",
  "hutbe",
  "khutbah",
  "peygamber",
  "resul",
  "sahabe",
  "meal",
  "tefsir",
  "tesettür",
  "tesettur",
  "eşcinsellik",
  "escinsellik",
  "tövbe",
  "iman",
  "ahlak"
];

const SENSITIVE_KEYWORDS = [
  "gusül",
  "gusul",
  "hayız",
  "hayiz",
  "adet",
  "lohusa",
  "nifas",
  "mahrem",
  "mahremiyet",
  "nikah",
  "evlilik",
  "eşimle",
  "esimle",
  "cinsel",
  "sexual",
  "mastürb",
  "masturb",
  "intim",
  "ilişki",
  "iliski",
  "ihtilam",
  "eşcinsellik",
  "escinsellik",
  "zina",
  "şehvet",
  "sehvet"
];

const EXPLICIT_REJECT_KEYWORDS = [
  "porno",
  "porn",
  "erotik",
  "azdır",
  "azdir",
  "sext",
  "nude",
  "çıplak",
  "ciplak",
  "seks hikayesi",
  "sex story",
  "pozisyon anlat",
  "sexual position",
  "tahrik",
  "hookup",
  "blowjob",
  "oral sex",
  "anal sex",
  "fuck me",
  "beni azdir",
  "beni tahrik et"
];

const OFF_TOPIC_KEYWORDS = [
  "kod yaz",
  "code",
  "javascript",
  "swiftui",
  "swift",
  "python",
  "debug",
  "react",
  "xcode",
  "vercel",
  "wifi",
  "bluetooth",
  "printer",
  "router",
  "windows",
  "macbook",
  "iphone problem",
  "android problem",
  "tech support",
  "computer issue",
  "politics",
  "political",
  "seçim",
  "secim",
  "election",
  "parti",
  "cumhurbaşkanı",
  "cumhurbaskani",
  "parliament",
  "senato",
  "hisse",
  "stock",
  "bitcoin",
  "crypto",
  "borsa",
  "yatırım",
  "yatirim",
  "investment",
  "portfolio",
  "fon",
  "lawyer",
  "avukat",
  "mahkeme",
  "dava",
  "sözleşme",
  "sozlesme",
  "legal advice",
  "kanun",
  "hukuk",
  "doktor",
  "doctor",
  "ilaç",
  "ilac",
  "medicine",
  "medical advice",
  "teşhis",
  "teshis",
  "symptom",
  "diagnosis",
  "treatment",
  "tedavi",
  "movie",
  "film",
  "dizi",
  "shopping",
  "alışveriş",
  "alisveris",
  "oyun",
  "game",
  "recipe",
  "tarif"
];

const KHUTBAH_SUMMARY_KEYWORDS = [
  "hutbe özeti",
  "hutbe ozeti",
  "khutbah summary",
  "sermon summary",
  "hutbeyi özetle",
  "hutbeyi ozetle",
  "bu haftaki hutbe özeti",
  "this week's khutbah summary"
];

const GREETING_KEYWORDS = [
  "selam",
  "selamünaleyküm",
  "selamunaleykum",
  "merhaba",
  "hello",
  "hi",
  "salam"
];

const FOLLOW_UP_KEYWORDS = [
  "neden",
  "niye",
  "nasıl",
  "nasil",
  "peki",
  "peki ya",
  "yani",
  "emin misin",
  "eminmisin",
  "why",
  "how",
  "what about",
  "are you sure",
  "then",
  "so"
];

const MAX_HISTORY_ITEMS = 4;
const MAX_HISTORY_TEXT_LENGTH = 220;

export function normalizeLanguage(code) {
  const normalized = String(code ?? "tr").replaceAll("_", "-").toLowerCase();
  return normalized.split("-")[0] || "tr";
}

export function sanitizeRabiaHistory(history) {
  if (!Array.isArray(history)) {
    return [];
  }

  return history
    .map((item) => ({
      role: item?.role === "assistant" ? "assistant" : item?.role === "user" ? "user" : null,
      text: limitText(String(item?.text ?? "").trim(), MAX_HISTORY_TEXT_LENGTH)
    }))
    .filter((item) => item.role && item.text);
}

export function trimRabiaHistory(history, maxItems = MAX_HISTORY_ITEMS) {
  const sanitized = sanitizeRabiaHistory(history);
  return sanitized.slice(-Math.max(0, maxItems));
}

export function buildRabiaInput(message, history = []) {
  const trimmedMessage = String(message ?? "").trim();
  const input = trimRabiaHistory(history).map((item) => ({
    role: item.role,
    content: [{
      type: item.role === "assistant" ? "output_text" : "input_text",
      text: item.text
    }]
  }));

  if (trimmedMessage) {
    input.push({
      role: "user",
      content: [{ type: "input_text", text: trimmedMessage }]
    });
  }

  return input;
}

export function classifyRabiaInput(message, runtimeContext = {}, history = []) {
  const normalized = normalizeText(message);
  const diyanetAttached = Boolean(runtimeContext.diyanet?.excerpt);
  const trimmedHistory = trimRabiaHistory(history);
  const historyText = trimmedHistory.map((item) => item.text).join(" ");
  const combinedText = [message, historyText].filter(Boolean).join(" ");
  const normalizedCombined = normalizeText(combinedText);
  const isFollowUp = isFollowUpMessage(normalized);

  if (!normalized) {
    return { label: "reject", reason: "empty" };
  }

  if (matchesAny(normalized, EXPLICIT_REJECT_KEYWORDS)) {
    return { label: "reject", reason: "explicit_sexual" };
  }

  if (matchesAny(normalized, OFF_TOPIC_KEYWORDS)) {
    return { label: "reject", reason: "off_topic" };
  }

  if (isKhutbahSummaryRequest(message)) {
    return { label: "app_navigation", reason: "khutbah_summary" };
  }

  if (matchesNavigationIntent(normalized) && matchesAny(normalizedCombined, APP_SECTION_KEYWORDS)) {
    return { label: "app_navigation", reason: "app_feature" };
  }

  if (matchesAny(normalized, SENSITIVE_KEYWORDS) && (matchesAny(normalizedCombined, ISLAMIC_TOPIC_KEYWORDS) || diyanetAttached)) {
    return { label: "islamic_sensitive", reason: "sensitive_islamic" };
  }

  if (matchesAny(normalizedCombined, ISLAMIC_TOPIC_KEYWORDS) || diyanetAttached) {
    return { label: "islamic_allowed", reason: isFollowUp ? "follow_up_islamic" : "islamic_topic" };
  }

  if (isFollowUp && trimmedHistory.length > 0) {
    if (matchesAny(normalizedTextFromHistory(trimmedHistory), APP_SECTION_KEYWORDS)) {
      return { label: "app_navigation", reason: "follow_up_navigation" };
    }
    if (matchesAny(normalizedTextFromHistory(trimmedHistory), OFF_TOPIC_KEYWORDS)) {
      return { label: "reject", reason: "off_topic" };
    }
  }

  if (matchesAny(normalized, GREETING_KEYWORDS)) {
    return { label: "reject", reason: "smalltalk_outside_scope" };
  }

  return { label: "reject", reason: "outside_scope" };
}

export function isKhutbahSummaryRequest(message) {
  const normalized = normalizeText(message);
  return normalized ? matchesAny(normalized, KHUTBAH_SUMMARY_KEYWORDS) : false;
}

export function buildRabiaSystemPrompt(runtimeContext = {}, classification = "islamic_allowed") {
  const currentAppLanguage = normalizeLanguage(
    runtimeContext.currentAppLanguage ?? runtimeContext.appLanguage ?? "tr"
  );
  const currentScreen = runtimeContext.currentScreen ?? "unknown";
  const localized = getLocalizedStrings(currentAppLanguage);
  const modeLine = getModeLine(classification);
  const diyanetBlock = runtimeContext.diyanet?.excerpt
    ? [
        "Verified Diyanet context is attached.",
        `Title: ${limitText(runtimeContext.diyanet.title, 120)}`,
        `Excerpt: ${limitText(runtimeContext.diyanet.excerpt, 240)}`,
        "If it is relevant, your response order must be: first a short natural answer, then a 1-2 sentence summary of the attached Diyanet content, then the Rehber routing sentence."
      ].join("\n")
    : "";
  const appKnowledgeBlock = classification === "app_navigation"
    ? [
        "Known app sections:",
        ...APP_KNOWLEDGE.sections.map((section) => `- ${section.label}: ${section.guidance}`)
      ].join("\n")
    : "";

  return [
    "You are Rabia, the in-app Islamic assistant inside Zikrim.",
    "You are not a general chatbot.",
    `Reply only in ${currentAppLanguage}. Never mix languages.`,
    `Current app language: ${currentAppLanguage}.`,
    `Current screen: ${currentScreen}.`,
    "Tone: natural, calm, respectful, human, and warm. Do not sound robotic, cold, academic, or repetitive.",
    "Answer the user's real intent first. Redirect only when it is useful after the answer, never before a useful answer.",
    "Most replies should be 2-4 sentences. Keep them short but meaningful.",
    "If the user asks follow-up questions like why, how, what about that, so, or are you sure, continue from the recent conversation instead of restarting.",
    "Stay within Islamic questions, spiritual questions, worship, dua, dhikr, Quran reflection, khutbah-related explanation, and Zikrim app navigation.",
    "If something is clearly sinful, haram, or impermissible in mainstream Islamic understanding, say so clearly without shaming the user.",
    "If there is a known scholarly disagreement, mention it briefly and move on.",
    "Do not give coding help, unrelated tech support, politics, finance, legal advice, medical advice, trivia, or unrelated lifestyle chat.",
    "For vulgar or stimulation-seeking sexual requests, refuse briefly. For valid Islamic morality questions, answer briefly, modestly, and without graphic detail.",
    "Khutbah Summary is a separate feature. Do not generate a new khutbah summary in chat. Briefly explain it and route the user to the Khutbah Summary section.",
    "Use app knowledge only when relevant. Never invent screens, buttons, hidden settings, or actions. Never claim to control the app.",
    "If unsure about app location, say so briefly instead of guessing.",
    `If you route to Rehber, use this sentence or its direct equivalent: ${localized.rehberRoute}`,
    modeLine,
    appKnowledgeBlock,
    diyanetBlock,
    "Return only the final answer text."
  ]
    .filter(Boolean)
    .join("\n\n");
}

export function getRejectReply(language, reason = "outside_scope") {
  const localized = getLocalizedStrings(language);
  return reason === "explicit_sexual" ? localized.explicitReject : localized.scopeReject;
}

export function getKhutbahRedirectReply(language) {
  const normalized = normalizeLanguage(language);
  const replies = {
    tr: "Hutbe ozeti sohbet icinde uretilmez. Haftalik ozeti Khutbah Summary bolumunde bulabilirsin.",
    en: "Khutbah summaries are not generated in chat. You can find the weekly summary in the Khutbah Summary section.",
    de: "Khutba-Zusammenfassungen werden nicht im Chat erstellt. Du findest die woechentliche Zusammenfassung im Bereich Khutbah Summary.",
    ar: "لا يتم إنشاء ملخص الخطبة داخل المحادثة. يمكنك العثور على الملخص الأسبوعي في قسم Khutbah Summary.",
    fr: "Le resume du khutbah n'est pas genere dans le chat. Vous pouvez trouver le resume hebdomadaire dans la section Khutbah Summary.",
    es: "El resumen de la jutba no se genera dentro del chat. Puedes encontrar el resumen semanal en la seccion Khutbah Summary.",
    id: "Ringkasan khutbah tidak dibuat di chat. Kamu bisa menemukan ringkasan mingguan di bagian Khutbah Summary.",
    ur: "خطبہ خلاصہ چیٹ کے اندر تیار نہیں ہوتا۔ آپ ہفتہ وار خلاصہ Khutbah Summary حصے میں دیکھ سکتے ہیں۔",
    ms: "Ringkasan khutbah tidak dijana dalam chat. Anda boleh menemui ringkasan mingguan di bahagian Khutbah Summary.",
    ru: "Краткое содержание хутбы не создается в чате. Еженедельное содержание можно найти в разделе Khutbah Summary.",
    fa: "خلاصه خطبه در چت توليد نمي شود. مي تواني خلاصه هفتگي را در بخش Khutbah Summary ببيني."
  };

  return replies[normalized] ?? replies.tr;
}

export function compactRabiaReply(text) {
  const cleaned = String(text ?? "")
    .replaceAll(/\r/g, "")
    .replaceAll(/^\s*[-*]\s+/gm, "")
    .replaceAll(/\n{3,}/g, "\n\n")
    .trim();
  const sentences = cleaned.match(/[^.!?]+[.!?]?/g)?.map((item) => item.trim()).filter(Boolean) ?? [];
  const compact = sentences.slice(0, 4).join(" ").trim();
  const finalText = compact || cleaned;
  return finalText.length > 420 ? `${finalText.slice(0, 417).trim()}...` : finalText;
}

export function getLocalizedStrings(language) {
  const normalized = normalizeLanguage(language);
  const map = {
    tr: {
      scopeReject: "Bu konuda yardimci olamam. Rabia yalnizca Islami konular ve uygulama ici yonlendirme icindir.",
      explicitReject: "Bu konuda yardimci olamam.",
      rehberRoute: "Bu konunun detayini uygulamadaki Rehber bolumunde bulabilirsin."
    },
    en: {
      scopeReject: "I can't help with that here. Rabia is only for Islamic topics and in-app guidance.",
      explicitReject: "I can't help with that here.",
      rehberRoute: "You can find the details in the Rehber section of the app."
    },
    de: {
      scopeReject: "Dabei kann ich hier nicht helfen. Rabia ist nur fuer islamische Themen und App-Hinweise da.",
      explicitReject: "Dabei kann ich hier nicht helfen.",
      rehberRoute: "Die Details findest du im Rehber-Bereich der App."
    },
    ar: {
      scopeReject: "لا أستطيع المساعدة في هذا هنا. Rabia مخصصة فقط للمواضيع الإسلامية والإرشاد داخل التطبيق.",
      explicitReject: "لا أستطيع المساعدة في هذا هنا.",
      rehberRoute: "يمكنك العثور على التفاصيل في قسم Rehber داخل التطبيق."
    },
    fr: {
      scopeReject: "Je ne peux pas aider pour cela ici. Rabia est reservee aux sujets islamiques et au guidage dans l'application.",
      explicitReject: "Je ne peux pas aider pour cela ici.",
      rehberRoute: "Vous pouvez trouver les details dans la section Rehber de l'application."
    },
    es: {
      scopeReject: "No puedo ayudar con eso aqui. Rabia solo es para temas islamicos y orientacion dentro de la app.",
      explicitReject: "No puedo ayudar con eso aqui.",
      rehberRoute: "Puedes encontrar los detalles en la seccion Rehber de la aplicacion."
    },
    id: {
      scopeReject: "Saya tidak bisa membantu untuk itu di sini. Rabia hanya untuk topik Islami dan panduan di dalam aplikasi.",
      explicitReject: "Saya tidak bisa membantu untuk itu di sini.",
      rehberRoute: "Kamu bisa menemukan detailnya di bagian Rehber di aplikasi."
    },
    ur: {
      scopeReject: "میں یہاں اس میں مدد نہیں کر سکتی۔ رابیہ صرف اسلامی موضوعات اور ایپ کے اندر رہنمائی کے لیے ہے۔",
      explicitReject: "میں یہاں اس میں مدد نہیں کر سکتی۔",
      rehberRoute: "اس کی تفصیل آپ ایپ کے Rehber حصے میں دیکھ سکتے ہیں۔"
    },
    ms: {
      scopeReject: "Saya tidak boleh membantu untuk itu di sini. Rabia hanya untuk topik Islam dan panduan dalam aplikasi.",
      explicitReject: "Saya tidak boleh membantu untuk itu di sini.",
      rehberRoute: "Anda boleh menemukan butirannya di bahagian Rehber dalam aplikasi."
    },
    ru: {
      scopeReject: "Я не могу помочь с этим здесь. Rabia предназначена только для исламских тем и навигации по приложению.",
      explicitReject: "Я не могу помочь с этим здесь.",
      rehberRoute: "Подробности можно найти в разделе Rehber в приложении."
    },
    fa: {
      scopeReject: "من نمي توانم در اينجا درباره اين موضوع كمك كنم. رابعه فقط براي موضوعات اسلامي و راهنمايي داخل برنامه است.",
      explicitReject: "من نمي توانم در اينجا درباره اين موضوع كمك كنم.",
      rehberRoute: "جزئيات را مي تواني در بخش Rehber برنامه ببيني."
    }
  };

  return map[normalized] ?? map.tr;
}

export function getLocalizedRehberRoute(language) {
  return getLocalizedStrings(language).rehberRoute;
}

function getModeLine(classification) {
  switch (classification) {
    case "islamic_sensitive":
      return "Mode: islamic_sensitive. Be modest, non-graphic, and brief.";
    case "app_navigation":
      return "Mode: app_navigation. Use only known app structure and answer naturally.";
    default:
      return "Mode: islamic_allowed. Answer naturally, briefly, and with useful substance.";
  }
}

function normalizeText(value) {
  return String(value ?? "")
    .normalize("NFKD")
    .replaceAll(/[^\p{L}\p{N}\s]/gu, " ")
    .replaceAll(/\s+/g, " ")
    .trim()
    .toLowerCase();
}

function matchesAny(normalizedText, keywords) {
  return keywords.some((keyword) => normalizedText.includes(normalizeText(keyword)));
}

function matchesNavigationIntent(normalizedText) {
  const words = normalizedText.split(" ").filter(Boolean);

  return APP_NAV_INTENT_KEYWORDS.some((keyword) => {
    const normalizedKeyword = normalizeText(keyword);
    return normalizedKeyword.includes(" ")
      ? normalizedText.includes(normalizedKeyword)
      : words.includes(normalizedKeyword);
  });
}

function limitText(text, maxLength) {
  const trimmed = String(text ?? "").trim();
  return trimmed.length > maxLength ? `${trimmed.slice(0, maxLength - 3).trim()}...` : trimmed;
}

function isFollowUpMessage(normalizedMessage) {
  if (!normalizedMessage) {
    return false;
  }

  const wordCount = normalizedMessage.split(" ").filter(Boolean).length;
  return wordCount <= 6 && matchesAny(normalizedMessage, FOLLOW_UP_KEYWORDS);
}

function normalizedTextFromHistory(history) {
  return normalizeText(history.map((item) => item.text).join(" "));
}
