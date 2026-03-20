#!/usr/bin/env python3
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Optional, Tuple

ROOT = Path(__file__).resolve().parents[1]
XCSTRINGS_PATH = ROOT / "Localizable.xcstrings"

DEEPL_ENDPOINT_FREE = "https://api-free.deepl.com/v2/translate"
DEEPL_ENDPOINT_PRO = "https://api.deepl.com/v2/translate"

SUPPORTED_LANGS = {
    "tr": "TR",
    "en": "EN",
    "ar": "AR",
    "de": "DE",
    "es": "ES",
    "fr": "FR",
    "id": "ID",
    "ur": "UR",
    "ms": "MS",
    "ru": "RU",
    "fa": "FA",
}

NON_TRANSLATABLE_KEYS = {
    "%lld": "%lld",
    "— %@": "— %@",
    "❝ %@ ❞": "❝ %@ ❞",
}

SOURCE_VALUE_OVERRIDES = {
    "%@ %@": "%1$@ %2$@",
}

PLACEHOLDER_RE = re.compile(r"%(\d+\$)?[@dfiuslld]+")


def endpoint_for_key(api_key: str) -> str:
    return DEEPL_ENDPOINT_FREE if api_key.strip().endswith(":fx") else DEEPL_ENDPOINT_PRO


def deepl_translate(text: str, target_lang: str, api_key: str, source_lang: str) -> str:
    data = {
        "source_lang": source_lang,
        "target_lang": target_lang,
        "text": [text],
    }
    encoded = urllib.parse.urlencode(data, doseq=True).encode("utf-8")
    req = urllib.request.Request(endpoint_for_key(api_key), data=encoded)
    req.add_header("Authorization", f"DeepL-Auth-Key {api_key}")
    try:
        with urllib.request.urlopen(req) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as err:
        body = err.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"DeepL error {err.code}: {body}") from err
    translations = payload.get("translations", [])
    return translations[0]["text"] if translations else ""


def is_non_translatable_key(key: str) -> bool:
    if key in NON_TRANSLATABLE_KEYS or key in SOURCE_VALUE_OVERRIDES:
        return True
    if not key:
        return False
    stripped = PLACEHOLDER_RE.sub("", key)
    stripped = "".join(ch for ch in stripped if not ch.isalnum())
    return stripped == key or stripped.strip() == key.strip()


def get_localized_value(entry: dict, lang: str) -> Optional[str]:
    return (((entry.get("localizations") or {}).get(lang) or {}).get("stringUnit") or {}).get("value")


def set_localized_value(entry: dict, lang: str, value: str) -> None:
    entry.setdefault("localizations", {})
    entry["localizations"].setdefault(lang, {})
    entry["localizations"][lang]["stringUnit"] = {
        "state": "translated",
        "value": value,
    }


def normalize_placeholders(text: str) -> str:
    return text.replace("%@", "%1$@").replace("%1$1$@", "%1$@")


def source_for_entry(key: str, entry: dict) -> Tuple[Optional[str], Optional[str]]:
    if key in SOURCE_VALUE_OVERRIDES:
        return SOURCE_VALUE_OVERRIDES[key], "TR"
    tr_value = get_localized_value(entry, "tr")
    en_value = get_localized_value(entry, "en")
    if tr_value:
        return tr_value, "TR"
    if en_value:
        return en_value, "EN"
    return None, None


def main() -> int:
    if not XCSTRINGS_PATH.exists():
        print(f"Missing {XCSTRINGS_PATH}", file=sys.stderr)
        return 1

    api_key = os.getenv("DEEPL_API_KEY", "").strip()
    payload = json.loads(XCSTRINGS_PATH.read_text(encoding="utf-8"))
    strings = payload.get("strings", {})
    supported_locale_codes = set(SUPPORTED_LANGS)

    translated = []
    skipped = []
    pruned = []

    for key, entry in strings.items():
        if not isinstance(entry, dict):
            continue

        localizations = entry.get("localizations") or {}
        for lang in sorted(set(localizations) - supported_locale_codes):
            del localizations[lang]
            pruned.append({"key": key, "lang": lang})

        missing_langs = []
        for lang in SUPPORTED_LANGS:
            value = get_localized_value(entry, lang)
            if value in (None, ""):
                missing_langs.append(lang)

        if not missing_langs:
            continue

        if key == "":
            skipped.append({"key": key, "reason": "empty_key_manual_review", "langs": missing_langs})
            continue

        if is_non_translatable_key(key):
            fill_value = NON_TRANSLATABLE_KEYS.get(key) or SOURCE_VALUE_OVERRIDES.get(key) or key
            fill_value = normalize_placeholders(fill_value)
            for lang in missing_langs:
                set_localized_value(entry, lang, fill_value)
                translated.append({"key": key, "lang": lang, "mode": "copied"})
            continue

        if not api_key:
            skipped.append({"key": key, "reason": "missing_deepl_api_key", "langs": missing_langs})
            continue

        source_text, source_lang = source_for_entry(key, entry)
        if not source_text or not source_lang:
            skipped.append({"key": key, "reason": "missing_source_text", "langs": missing_langs})
            continue

        for lang in missing_langs:
            target_lang = SUPPORTED_LANGS[lang]
            if target_lang == source_lang:
                set_localized_value(entry, lang, source_text)
                translated.append({"key": key, "lang": lang, "mode": "copied-source"})
                continue
            value = deepl_translate(source_text, target_lang, api_key, source_lang)
            set_localized_value(entry, lang, value)
            translated.append({"key": key, "lang": lang, "mode": "deepl"})

    XCSTRINGS_PATH.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    print(json.dumps({"translated": translated, "skipped": skipped, "pruned": pruned}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
