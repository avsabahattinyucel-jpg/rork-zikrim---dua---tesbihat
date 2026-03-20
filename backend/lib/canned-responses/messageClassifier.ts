import { CANNED_RESPONSES } from "./localization.js";
import { escapeRegex, isEmojiOnlyMessage, normalizeForEscalation, normalizeForMatching, normalizeForSurfaceText, splitWords } from "./normalizeText.js";
import type { IntentMatch, LightweightIntent, TriggerIntent } from "./types.js";

const ASSISTANT_NAME_ALIASES = new Set([
  "rabia",
  "rabiya",
  "رابعة",
  "رابيا",
  "رابعہ"
]);

const LIGHTWEIGHT_FILLER_WORDS = new Set([
  "rabia",
  "please",
  "pls",
  "plz",
  "lütfen",
  "lutfen",
  "por favor",
  "s'il",
  "svp",
  "bitte",
  "tolong",
  "silakan",
  "برائے",
  "مہربانی",
  "من",
  "فضلك",
  "لطفا",
  "خواهشاً"
]);

const DISTRESS_PATTERNS = [
  "i feel bad",
  "i feel terrible",
  "i am overwhelmed",
  "i'm overwhelmed",
  "i feel overwhelmed",
  "i am anxious",
  "i'm anxious",
  "i feel anxious",
  "i am scared",
  "i'm scared",
  "i feel scared",
  "i feel guilty",
  "i'm confused",
  "i feel lost",
  "help me",
  "what should i do",
  "i need help",
  "i feel awful",
  "i am not okay",
  "i'm not okay",
  "selam içim daralıyor",
  "içim daralıyor",
  "icim daraliyor",
  "çok kötüyüm",
  "cok kotuyum",
  "çok kötü hissediyorum",
  "cok kotu hissediyorum",
  "kaygılıyım",
  "kaygiliyim",
  "korkuyorum",
  "yardım et",
  "yardim et",
  "ne yapmalıyım",
  "ne yapmaliyim",
  "kendimi kötü hissediyorum",
  "üzgünüm",
  "uzgunum",
  "bunaldım",
  "bunaldim",
  "أشعر بالسوء",
  "أشعر أني لست بخير",
  "أنا خائف",
  "أنا قلِق",
  "قلق",
  "حزين",
  "ساعدني",
  "ماذا أفعل",
  "منهار",
  "حالم بده",
  "حال من بده",
  "کمکم کن",
  "حالم بد است",
  "حالم بده",
  "نگرانم",
  "می ترسم",
  "چه کار کنم",
  "غمگینم",
  "میں بہت پریشان ہوں",
  "میرا دل گھبرا رہا ہے",
  "مدد کریں",
  "مدد کرو",
  "میں ٹھیک نہیں ہوں",
  "کیا کروں",
  "میں خوفزدہ ہوں",
  "میں پریشان ہوں"
];

const RELIGIOUS_REQUEST_PATTERNS = [
  "dua",
  "pray for me",
  "prayer",
  "dhikr",
  "zikr",
  "dhikir",
  "quran",
  "koran",
  "verse",
  "ayah",
  "surah",
  "hadith",
  "tafsir",
  "meaning",
  "explanation",
  "explain",
  "fatwa",
  "halal",
  "haram",
  "religious question",
  "dua öner",
  "dua oner",
  "dua istiyorum",
  "zikir",
  "tesbih",
  "ayet",
  "hadis",
  "tefsir",
  "meal",
  "açıkla",
  "acikla",
  "anlamı ne",
  "anlami ne",
  "caiz mi",
  "günah mı",
  "gunah mi",
  "hangi dua",
  "hangi zikir",
  "quran",
  "آية",
  "آيه",
  "قرآن",
  "تفسير",
  "حديث",
  "دعاء",
  "ذكر",
  "فتوى",
  "حكم",
  "معنى",
  "اشرح",
  "توضيح",
  "دعا",
  "ذکر",
  "حدیث",
  "قرآن",
  "تفسیر",
  "معنی",
  "توضیح",
  "شرح بده",
  "دعا بده",
  "آیت",
  "دعا",
  "ذکر",
  "قرآن",
  "حدیث",
  "تفسیر",
  "معنی",
  "وضاحت"
];

const HELP_SEEKING_PATTERNS = [
  "how can you help me with",
  "can you help me with",
  "can you help me",
  "what do i do",
  "what should i do",
  "yardım eder misin",
  "yardim eder misin",
  "yardıma ihtiyacım var",
  "yardima ihtiyacim var",
  "ne yapacağımı bilmiyorum",
  "ne yapacagimi bilmiyorum",
  "bana yardım et",
  "bana yardim et",
  "ساعدني",
  "كيف أتصرف",
  "ماذا أفعل",
  "أحتاج مساعدة",
  "کمکم کن",
  "کمک لازم دارم",
  "چه کار کنم",
  "می توانی کمکم کنی",
  "می‌تونی کمکم کنی",
  "مدد کریں",
  "میری مدد کریں",
  "کیا کروں",
  "کیا آپ مدد کر سکتی ہیں"
];

const CLAUSE_SEPARATORS_REGEX = /[,;،؛]/u;
const QUESTION_MARK_REGEX = /[?؟]/u;

interface CompiledTrigger {
  intent: TriggerIntent;
  originalTrigger: string;
  surface: string;
  matching: string;
  regex: RegExp;
}

const TRIGGER_INTENTS = Object.keys(CANNED_RESPONSES.tr.triggers) as TriggerIntent[];
const COMPILED_TRIGGERS = buildCompiledTriggers();
const SURFACE_INDEX = buildIndex(COMPILED_TRIGGERS, "surface");
const MATCHING_INDEX = buildIndex(COMPILED_TRIGGERS, "matching");
const LEADING_TRIGGERS = [...COMPILED_TRIGGERS].sort((left, right) => right.matching.length - left.matching.length);

export function detectLightweightIntent(message: string): IntentMatch | null {
  if (isEmojiOnlyMessage(message)) {
    return { intent: "emoji_only", matchType: "emoji_only" };
  }

  const surface = normalizeForSurfaceText(message);
  const matching = normalizeForMatching(message);
  if (!matching) {
    return null;
  }

  const exactMatch = SURFACE_INDEX.get(surface)?.[0];
  if (exactMatch) {
    return { intent: exactMatch.intent, matchType: "exact", matchedTrigger: exactMatch.originalTrigger };
  }

  const synonymMatch = MATCHING_INDEX.get(matching)?.[0];
  if (synonymMatch) {
    return { intent: synonymMatch.intent, matchType: "synonym", matchedTrigger: synonymMatch.originalTrigger };
  }

  const regexMatch = COMPILED_TRIGGERS.find((entry) => entry.regex.test(matching));
  if (regexMatch) {
    return { intent: regexMatch.intent, matchType: "regex", matchedTrigger: regexMatch.originalTrigger };
  }

  return detectShortHeuristicIntent(matching);
}

export function shouldEscalateToLLM(message: string): boolean {
  const escalationText = normalizeForEscalation(message);
  const matchingText = normalizeForMatching(message);
  if (!matchingText || isEmojiOnlyMessage(message)) {
    return false;
  }

  if (detectLightweightIntent(message)) {
    return false;
  }

  if (containsEscalationPattern(matchingText)) {
    return true;
  }

  const leadingIntent = detectLeadingIntent(matchingText);
  if (leadingIntent?.remainder) {
    if (!detectRemainderAsSimpleIntent(leadingIntent.remainder)) {
      return true;
    }
  }

  const wordCount = splitWords(matchingText).length;
  const hasQuestion = QUESTION_MARK_REGEX.test(escalationText);
  const hasClauses = CLAUSE_SEPARATORS_REGEX.test(escalationText);

  if ((hasQuestion || hasClauses) && wordCount > 6) {
    return true;
  }

  return wordCount > 8;
}

function buildCompiledTriggers(): CompiledTrigger[] {
  const entries: CompiledTrigger[] = [];

  for (const localeConfig of Object.values(CANNED_RESPONSES)) {
    for (const intent of TRIGGER_INTENTS) {
      for (const trigger of localeConfig.triggers[intent]) {
        const surface = normalizeForSurfaceText(trigger);
        const matching = normalizeForMatching(trigger);

        if (!matching) {
          continue;
        }

        entries.push({
          intent,
          originalTrigger: trigger,
          surface,
          matching,
          regex: new RegExp(`^${escapeRegex(matching).replace(/\\ /g, "\\s+")}$`, "u")
        });
      }
    }
  }

  return entries;
}

function buildIndex(entries: readonly CompiledTrigger[], field: "surface" | "matching"): Map<string, CompiledTrigger[]> {
  const map = new Map<string, CompiledTrigger[]>();

  for (const entry of entries) {
    const key = entry[field];
    const bucket = map.get(key) ?? [];
    bucket.push(entry);
    map.set(key, bucket);
  }

  return map;
}

function detectShortHeuristicIntent(matchingText: string): IntentMatch | null {
  const words = splitWords(matchingText);
  if (words.length === 0 || words.length > 4) {
    return null;
  }

  const strippedWords = words.filter((word) => !ASSISTANT_NAME_ALIASES.has(word) && !LIGHTWEIGHT_FILLER_WORDS.has(word));
  if (strippedWords.length === 0) {
    return null;
  }

  const compactMessage = strippedWords.join(" ");
  const match = MATCHING_INDEX.get(compactMessage)?.[0];
  if (match) {
    return { intent: match.intent, matchType: "heuristic", matchedTrigger: match.originalTrigger };
  }

  return null;
}

function containsEscalationPattern(matchingText: string): boolean {
  return [...DISTRESS_PATTERNS, ...RELIGIOUS_REQUEST_PATTERNS, ...HELP_SEEKING_PATTERNS]
    .some((pattern) => matchingText.includes(normalizeForMatching(pattern)));
}

function detectLeadingIntent(matchingText: string): { intent: LightweightIntent; remainder: string } | null {
  for (const trigger of LEADING_TRIGGERS) {
    if (matchingText === trigger.matching) {
      return { intent: trigger.intent, remainder: "" };
    }

    if (matchingText.startsWith(`${trigger.matching} `)) {
      return {
        intent: trigger.intent,
        remainder: matchingText.slice(trigger.matching.length).trim()
      };
    }
  }

  return null;
}

function detectRemainderAsSimpleIntent(remainder: string): boolean {
  const remainderWords = splitWords(remainder).filter((word) => !ASSISTANT_NAME_ALIASES.has(word) && !LIGHTWEIGHT_FILLER_WORDS.has(word));
  if (remainderWords.length === 0) {
    return true;
  }

  const candidate = remainderWords.join(" ");
  return detectLightweightIntent(candidate) !== null;
}
