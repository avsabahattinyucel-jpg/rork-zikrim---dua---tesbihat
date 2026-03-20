#!/usr/bin/env python3
import json
import re
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "ZikrimDuaVeTesbihat" / "Data"
OUT_PATH = DATA_DIR / "content_localizations.json"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")


def extract_blocks(text: str, marker: str) -> list[str]:
    blocks = []
    idx = 0
    while True:
        start = text.find(marker, idx)
        if start == -1:
            break
        i = start + len(marker)
        depth = 1
        while i < len(text) and depth > 0:
            if text[i] == "(":
                depth += 1
            elif text[i] == ")":
                depth -= 1
            i += 1
        block = text[start + len(marker): i - 1]
        blocks.append(block)
        idx = i
    return blocks


def extract_string_field(block: str, field: str) -> Optional[str]:
    needle = f"{field}:"
    idx = block.find(needle)
    if idx == -1:
        return None
    start = block.find("\"", idx)
    if start == -1:
        return None
    i = start + 1
    out = []
    while i < len(block):
        ch = block[i]
        if ch == "\\":
            if i + 1 < len(block):
                out.append(block[i + 1])
                i += 2
                continue
        if ch == "\"":
            break
        out.append(ch)
        i += 1
    if not out:
        return None
    return "".join(out)


def add_key(entries: dict, key: str, value: str):
    if not value:
        return
    entries.setdefault(key, {})["tr"] = value


def build_entries() -> dict:
    entries: dict[str, dict] = {}

    # RehberEntry blocks
    for path in DATA_DIR.glob("*.swift"):
        text = read_text(path)
        for block in extract_blocks(text, "RehberEntry("):
            entry_id = extract_string_field(block, "id")
            if not entry_id:
                continue
            for field, suffix in [
                ("title", "title"),
                ("meaning", "meaning"),
                ("purpose", "purpose"),
                ("notes", "notes"),
                ("schedule", "schedule"),
                ("recommendedCountNote", "recommended_count_note"),
            ]:
                value = extract_string_field(block, field)
                if value:
                    add_key(entries, f"rehber.{entry_id}.{suffix}", value)

    # ZikirCategory and ZikirItem blocks (ZikirData.swift)
    zikir_path = DATA_DIR / "ZikirData.swift"
    if zikir_path.exists():
        text = read_text(zikir_path)
        for block in extract_blocks(text, "ZikirCategory("):
            cat_id = extract_string_field(block, "id")
            name = extract_string_field(block, "name")
            if cat_id and name:
                add_key(entries, f"zikir.category.{cat_id}.name", name)

        for block in extract_blocks(text, "ZikirItem("):
            item_id = extract_string_field(block, "id")
            meaning = extract_string_field(block, "turkishMeaning")
            if item_id and meaning:
                add_key(entries, f"zikir.item.{item_id}.meaning", meaning)

    # Daily motivations
    motivation_path = DATA_DIR / "IslamicMotivationPool.swift"
    if motivation_path.exists():
        text = read_text(motivation_path)
        m = re.search(r"static let sentences: \\[String\\] = \\[(.*?)\\]\\s*\\n\\s*\\n", text, re.S)
        if m:
            block = m.group(1)
            strings = re.findall(r"\"((?:\\\\.|[^\"\\\\])*)\"", block)
            for idx, raw in enumerate(strings):
                value = bytes(raw, "utf-8").decode("unicode_escape")
                add_key(entries, f"motivation.{idx}", value)
        add_key(entries, "motivation.fallback", "Allah'ı anmak kalplere huzur verir.")

    # Quran data (surah names + dataset verses)
    quran_surah_path = DATA_DIR / "QuranSurahData.swift"
    if quran_surah_path.exists():
        text = read_text(quran_surah_path)
        for block in extract_blocks(text, "QuranSurah("):
            surah_id = extract_string_field(block, "id")
            name = extract_string_field(block, "turkishName")
            if surah_id and name:
                add_key(entries, f"quran.surah.{surah_id}.name", name)

    # Revelation types
    add_key(entries, "quran.revelation_type.Meccan", "Mekki")
    add_key(entries, "quran.revelation_type.Medinan", "Medeni")

    # Quran dataset (full verses)
    quran_dataset_path = DATA_DIR / "quran_dataset.json"
    if quran_dataset_path.exists():
        data = json.loads(quran_dataset_path.read_text(encoding="utf-8"))
        for verse in data:
            key = f"quran.verse.{verse['surah_number']}:{verse['ayah_number']}.translation"
            add_key(entries, key, verse.get("turkish", ""))

    # Hadith dataset
    hadith_path = DATA_DIR / "hadith_dataset.json"
    if hadith_path.exists():
        data = json.loads(hadith_path.read_text(encoding="utf-8"))
        for hadith in data:
            hid = hadith.get("id")
            if not hid:
                continue
            add_key(entries, f"hadith.{hid}.text", hadith.get("text", ""))
            add_key(entries, f"hadith.{hid}.collection", hadith.get("collection", ""))
            add_key(entries, f"hadith.{hid}.reference", hadith.get("reference", ""))

    # Islamic knowledge dataset
    knowledge_path = DATA_DIR / "islamic_knowledge.json"
    if knowledge_path.exists():
        data = json.loads(knowledge_path.read_text(encoding="utf-8"))
        for card in data:
            kid = card.get("id")
            if not kid:
                continue
            add_key(entries, f"knowledge.{kid}.title", card.get("title", ""))
            add_key(entries, f"knowledge.{kid}.summary", card.get("summary", ""))

    return entries


def main():
    existing = {}
    if OUT_PATH.exists():
        existing = json.loads(OUT_PATH.read_text(encoding="utf-8"))

    entries = build_entries()
    merged = existing.get("keys", {})
    for key, vals in entries.items():
        merged.setdefault(key, {}).update({ "tr": vals["tr"] })

    payload = {
        "version": 1,
        "sourceLanguage": "tr",
        "keys": merged
    }

    OUT_PATH.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {OUT_PATH} with {len(merged)} keys")


if __name__ == "__main__":
    main()
