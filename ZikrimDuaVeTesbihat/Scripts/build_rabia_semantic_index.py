#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Rabia Quran Semantic Index Builder
----------------------------------
Builds a semantic search index for Quran verses from a verified dataset.

Input:
    Data/rabia_quran_dataset.json

Output:
    Data/rabia_quran_semantic_index.json

Features:
- Reads verified Quran verse dataset
- Builds semantic metadata per verse
- Adds topic tags using rule-based matching
- Generates localized keyword/search text blocks
- Produces a clean JSON index usable by Rabia retrieval layer

This is a lightweight first version.
Later it can be upgraded to:
- real embeddings
- vector search
- backend retrieval
"""

from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Any, Tuple


INPUT_PATH = Path("Data/rabia_quran_dataset.json")
OUTPUT_PATH = Path("Data/rabia_quran_semantic_index.json")


TOPIC_RULES: Dict[str, Dict[str, List[str]]] = {
    "peace": {
        "tr": [
            "huzur", "kalp huzuru", "sükunet", "iç huzur", "dinginlik",
            "zikir", "kalpler ancak allah'ı anmakla huzur bulur"
        ],
        "en": [
            "peace", "inner peace", "calm", "tranquility", "remembrance",
            "heart at rest", "peace of heart"
        ],
        "ar": ["طمأنينة", "سكينة", "ذكر الله", "راحة القلب"],
    },
    "patience": {
        "tr": ["sabır", "sabredenler", "zorluk", "musibet", "dayanmak"],
        "en": ["patience", "patient", "hardship", "endure", "trial"],
        "ar": ["صبر", "الصابرين", "بلاء", "محنة"],
    },
    "forgiveness": {
        "tr": ["bağışlama", "af", "merhamet", "tövbe", "rahmet", "günah"],
        "en": ["forgiveness", "mercy", "repentance", "sin", "pardon"],
        "ar": ["مغفرة", "رحمة", "توبة", "ذنب"],
    },
    "hope": {
        "tr": ["ümit", "umut", "rahmet", "ümitsizlik", "korkmayın"],
        "en": ["hope", "despair", "do not despair", "mercy", "hopeful"],
        "ar": ["رجاء", "لا تقنطوا", "رحمة الله"],
    },
    "anxiety": {
        "tr": ["kaygı", "endişe", "iç sıkıntısı", "daralma", "korku"],
        "en": ["anxiety", "worry", "fear", "distress", "tightness"],
        "ar": ["خوف", "ضيق", "قلق", "هم"],
    },
    "gratitude": {
        "tr": ["şükür", "nimet", "hamd", "şükredenler"],
        "en": ["gratitude", "thankfulness", "praise", "blessing"],
        "ar": ["شكر", "حمد", "نعمة"],
    },
    "love": {
        "tr": ["sevgi", "aşk", "muhabbet", "eşler", "merhamet"],
        "en": ["love", "affection", "spouses", "mercy", "companionship"],
        "ar": ["حب", "مودة", "رحمة", "أزواج"],
    },
    "family": {
        "tr": ["aile", "anne", "baba", "eş", "çocuk", "akraba"],
        "en": ["family", "mother", "father", "spouse", "children", "kin"],
        "ar": ["أسرة", "أم", "أب", "زوج", "أولاد"],
    },
    "creation": {
        "tr": ["yaratmak", "yaratılış", "insan", "gök", "yer", "ayetler"],
        "en": ["creation", "created", "human", "heavens", "earth", "signs"],
        "ar": ["خلق", "الإنسان", "السماوات", "الأرض"],
    },
    "rizq": {
        "tr": ["rızık", "nimet", "geçim", "veren", "beslemek"],
        "en": ["provision", "sustenance", "rizq", "provide", "blessing"],
        "ar": ["رزق", "يرزق", "نعمة"],
    },
    "dua": {
        "tr": ["dua", "yalvarmak", "istemek", "bana dua edin", "çağırın"],
        "en": ["supplication", "dua", "call upon", "ask", "invoke"],
        "ar": ["دعاء", "ادعوني", "اسألوا"],
    },
    "hardship": {
        "tr": ["zorluk", "kolaylık", "sıkıntı", "imtihan", "musibet"],
        "en": ["hardship", "difficulty", "ease", "trial", "affliction"],
        "ar": ["عسر", "يسر", "بلاء", "محنة"],
    },
    "loneliness": {
        "tr": ["yalnızlık", "terk edilmek", "yakınlık", "yardım", "destek"],
        "en": ["loneliness", "abandoned", "nearness", "help", "support"],
        "ar": ["وحدة", "قرب", "معية", "نصرة"],
    },
    "grief": {
        "tr": ["üzüntü", "keder", "yas", "mahzun", "ağlamak"],
        "en": ["grief", "sadness", "sorrow", "mourning", "weep"],
        "ar": ["حزن", "كآبة", "بكاء"],
    },
    "repentance": {
        "tr": ["tövbe", "pişmanlık", "dönmek", "bağışlanma"],
        "en": ["repentance", "turn back", "forgiven", "regret"],
        "ar": ["توبة", "استغفار", "رجوع"],
    },
}


REFERENCE_VERSES: Dict[str, Dict[str, List[Tuple[int, int]]]] = {
    "peace": {"refs": [(13, 28), (48, 4), (2, 186)]},
    "patience": {"refs": [(2, 153), (39, 10), (94, 5)]},
    "forgiveness": {"refs": [(39, 53), (24, 22), (3, 135)]},
    "hope": {"refs": [(39, 53), (65, 3), (94, 6)]},
    "anxiety": {"refs": [(13, 28), (2, 286), (94, 5)]},
    "gratitude": {"refs": [(14, 7), (2, 152), (31, 12)]},
    "love": {"refs": [(30, 21), (3, 31), (5, 54)]},
    "family": {"refs": [(17, 23), (30, 21), (4, 1)]},
    "creation": {"refs": [(30, 21), (51, 49), (40, 64)]},
    "rizq": {"refs": [(65, 3), (11, 6), (2, 172)]},
    "dua": {"refs": [(2, 186), (40, 60), (7, 55)]},
    "hardship": {"refs": [(94, 5), (94, 6), (2, 286)]},
    "loneliness": {"refs": [(93, 3), (50, 16), (2, 186)]},
    "grief": {"refs": [(2, 286), (12, 86), (9, 40)]},
    "repentance": {"refs": [(39, 53), (66, 8), (25, 70)]},
}


@dataclass
class SemanticVerseEntry:
    ref: str
    surah: int
    ayah: int
    topics: List[str]
    priority_score: float
    keywords: Dict[str, List[str]]
    search_text: Dict[str, str]


def normalize_text(text: str) -> str:
    if not text:
        return ""
    text = text.casefold()
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = re.sub(r"[^\w\s']", " ", text, flags=re.UNICODE)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def safe_get_translation(verse: Dict[str, Any], lang: str) -> str:
    translations = verse.get("translations", {}) or {}
    return str(translations.get(lang, "")).strip()


def make_ref(surah: int, ayah: int) -> str:
    return f"{surah}:{ayah}"


def build_reference_map() -> Dict[str, List[str]]:
    result: Dict[str, List[str]] = {}
    for topic, payload in REFERENCE_VERSES.items():
        for surah, ayah in payload["refs"]:
            ref = make_ref(surah, ayah)
            result.setdefault(ref, []).append(topic)
    return result


def score_topics_for_verse(
    verse: Dict[str, Any],
    ref_topic_map: Dict[str, List[str]],
) -> Tuple[List[str], float]:
    surah = int(verse["surah"])
    ayah = int(verse["ayah"])
    ref = make_ref(surah, ayah)

    matched_topics = set(ref_topic_map.get(ref, []))
    score = 0.0

    tr_text = normalize_text(safe_get_translation(verse, "tr"))
    en_text = normalize_text(safe_get_translation(verse, "en"))
    ar_text = normalize_text(str(verse.get("arabic", "")))

    for topic, lang_map in TOPIC_RULES.items():
        local_score = 0

        for kw in lang_map.get("tr", []):
            if normalize_text(kw) in tr_text:
                local_score += 2

        for kw in lang_map.get("en", []):
            if normalize_text(kw) in en_text:
                local_score += 2

        for kw in lang_map.get("ar", []):
            if normalize_text(kw) in ar_text:
                local_score += 1

        if local_score > 0:
            matched_topics.add(topic)
            score += float(local_score)

    return sorted(matched_topics), score


def build_keywords(topic_list: List[str]) -> Dict[str, List[str]]:
    lang_keywords: Dict[str, List[str]] = {
        "tr": [],
        "en": [],
        "de": [],
        "ar": [],
        "fr": [],
        "es": [],
        "id": [],
        "ur": [],
        "ms": [],
        "ru": [],
        "fa": [],
    }

    for topic in topic_list:
        rule = TOPIC_RULES.get(topic, {})
        for lang in ("tr", "en", "ar"):
            lang_keywords[lang].extend(rule.get(lang, []))

    # fallback propagation for languages not explicitly curated yet
    fallback_map = {
        "de": "en",
        "fr": "en",
        "es": "en",
        "id": "en",
        "ms": "en",
        "ru": "en",
        "ur": "ar",
        "fa": "ar",
    }

    for lang, source_lang in fallback_map.items():
        lang_keywords[lang].extend(lang_keywords[source_lang])

    # remove duplicates while preserving order
    deduped: Dict[str, List[str]] = {}
    for lang, items in lang_keywords.items():
        seen = set()
        clean_items = []
        for item in items:
            key = normalize_text(item)
            if key and key not in seen:
                seen.add(key)
                clean_items.append(item)
        deduped[lang] = clean_items[:24]

    return deduped


def build_search_text(
    verse: Dict[str, Any],
    topics: List[str],
    keywords: Dict[str, List[str]],
) -> Dict[str, str]:
    tr_translation = safe_get_translation(verse, "tr")
    en_translation = safe_get_translation(verse, "en")
    de_translation = safe_get_translation(verse, "de")
    ar_text = str(verse.get("arabic", "")).strip()

    topic_text_tr = ", ".join(topics)
    topic_text_en = ", ".join(topics)
    topic_text_ar = "، ".join(topics)

    out: Dict[str, str] = {}

    out["tr"] = " | ".join(filter(None, [
        topic_text_tr,
        " ; ".join(keywords["tr"][:10]),
        tr_translation,
    ]))

    out["en"] = " | ".join(filter(None, [
        topic_text_en,
        " ; ".join(keywords["en"][:10]),
        en_translation,
    ]))

    out["de"] = " | ".join(filter(None, [
        topic_text_en,
        " ; ".join(keywords["de"][:10]),
        de_translation or en_translation,
    ]))

    out["ar"] = " | ".join(filter(None, [
        topic_text_ar,
        " ؛ ".join(keywords["ar"][:10]),
        ar_text,
    ]))

    fallback_from_en = ["fr", "es", "id", "ms", "ru"]
    fallback_from_ar = ["ur", "fa"]

    for lang in fallback_from_en:
        out[lang] = " | ".join(filter(None, [
            topic_text_en,
            " ; ".join(keywords[lang][:10]),
            en_translation,
        ]))

    for lang in fallback_from_ar:
        out[lang] = " | ".join(filter(None, [
            topic_text_ar,
            " ؛ ".join(keywords[lang][:10]),
            ar_text,
        ]))

    return out


def load_quran_dataset(path: Path) -> List[Dict[str, Any]]:
    if not path.exists():
        raise FileNotFoundError(f"Input dataset not found: {path}")

    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError("Expected rabia_quran_dataset.json to contain a list of verses.")

    return data


def build_semantic_index(verses: List[Dict[str, Any]]) -> List[SemanticVerseEntry]:
    ref_topic_map = build_reference_map()
    entries: List[SemanticVerseEntry] = []

    for verse in verses:
        surah = int(verse["surah"])
        ayah = int(verse["ayah"])
        ref = make_ref(surah, ayah)

        topics, score = score_topics_for_verse(verse, ref_topic_map)
        keywords = build_keywords(topics)
        search_text = build_search_text(verse, topics, keywords)

        entry = SemanticVerseEntry(
            ref=ref,
            surah=surah,
            ayah=ayah,
            topics=topics,
            priority_score=round(score, 2),
            keywords=keywords,
            search_text=search_text,
        )
        entries.append(entry)

    return entries


def save_semantic_index(entries: List[SemanticVerseEntry], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = [asdict(entry) for entry in entries]

    with path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    print(f"Saved semantic index: {path}")
    print(f"Total entries: {len(payload)}")


def main() -> None:
    verses = load_quran_dataset(INPUT_PATH)
    entries = build_semantic_index(verses)
    save_semantic_index(entries, OUTPUT_PATH)


if __name__ == "__main__":
    main()
