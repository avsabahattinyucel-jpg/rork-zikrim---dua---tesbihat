#!/usr/bin/env python3
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request
import urllib.error
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "ZikrimDuaVeTesbihat" / "Data" / "content_localizations.json"

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

PROTECTED_TERMS = [
    "Subhanallah",
    "Sübhânallâh",
    "Sübhânallah",
    "Elhamdülillah",
    "Alhamdulillah",
    "Allahu Akbar",
    "Allâhu Ekber",
    "Allahu Ekber",
    "Sübhâneke yâ lâ ilâhe illâ ente el-emânül-emân, neccinâ minen-nâr",
    "Kur'an",
    "Kur’an",
    "Qur'an",
    "Qur’an",
    "Bismillah",
    "Bismillâh",
]

PROTECTED_REGEX = re.compile("|".join(sorted(map(re.escape, PROTECTED_TERMS), key=len, reverse=True)))


def escape_xml(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
    )


def protect(text: str) -> str:
    escaped = escape_xml(text)
    body = escaped.replace("Allah", "<keep>Allah</keep>")
    body = PROTECTED_REGEX.sub(lambda m: f"<keep>{m.group(0)}</keep>", body)
    return f"<txt>{body}</txt>"


def _strip_allah_quotes(text: str) -> str:
    for q in ['"Allah"', '“Allah”', '«Allah»', '”Allah”', '„Allah“', '‹Allah›', '「Allah」', '『Allah』', '«Allah»', '”Allah”', '„Allah“', '‚Allah‘']:
        text = text.replace(q, "Allah")
    return text


def _strip_allah_pronoun(text: str, lang: str) -> str:
    patterns = {
        "en": ["He ", "She "],
        "de": ["Er ", "Sie "],
        "fr": ["Il ", "Elle "],
        "id": ["Dia "],
        "ms": ["Dia "],
        "ru": ["Он ", "Она "],
        "ar": ["إنه ", "إنها "],
        "fa": ["او "],
        "ur": ["وہ "],
    }
    if not text.startswith("Allah "):
        return text
    for p in patterns.get(lang, []):
        if text.startswith(f"Allah {p}"):
            return "Allah " + text[len(f"Allah {p}") :]
    return text


def _cleanup_allah_misfire(text: str) -> str:
    replacements = [
        (r"Prophet Muhammad\s*\(Allah\)", "Allah"),
        (r"Peygamber Muhammed\s*\(Allah\)", "Allah"),
        (r"النبي محمد\s*\(Allah\)", "Allah"),
        (r"Muhammad\s*\(Allah\)", "Allah"),
        (r"محمد\s*\(Allah\)", "Allah"),
    ]
    for pattern, repl in replacements:
        text = re.sub(pattern, repl, text)
    text = text.replace("Allah (Allah)", "Allah")
    text = text.replace("(Allah)", "")
    return text


def unprotect(text: str, lang: str) -> str:
    cleaned = text.replace("<keep>", "").replace("</keep>", "")
    cleaned = cleaned.replace("<txt>", "").replace("</txt>", "")
    cleaned = cleaned.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
    cleaned = _strip_allah_quotes(cleaned)
    cleaned = _strip_allah_pronoun(cleaned, lang)
    cleaned = _cleanup_allah_misfire(cleaned)
    cleaned = re.sub(r"\s{2,}", " ", cleaned).strip()
    return cleaned


def _endpoint_for_key(api_key: str) -> str:
    return DEEPL_ENDPOINT_FREE if api_key.strip().endswith(":fx") else DEEPL_ENDPOINT_PRO


def deepl_translate(texts, target_lang, api_key, source_lang="TR"):
    if not texts:
        return []
    data = {
        "source_lang": source_lang,
        "target_lang": target_lang,
        "tag_handling": "xml",
        "ignore_tags": "keep",
    }
    for t in texts:
        data.setdefault("text", []).append(t)
    encoded = urllib.parse.urlencode(data, doseq=True).encode("utf-8")
    req = urllib.request.Request(_endpoint_for_key(api_key), data=encoded)
    req.add_header("Authorization", f"DeepL-Auth-Key {api_key}")
    try:
        with urllib.request.urlopen(req) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
        return [t["text"] for t in payload.get("translations", [])]
    except urllib.error.HTTPError as err:
        body = err.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"DeepL error {err.code}: {body}") from err


def deepl_translate_debug(text, target_lang, api_key, source_lang="TR"):
    protected = protect(text)
    data = {
        "source_lang": source_lang,
        "target_lang": target_lang,
        "tag_handling": "xml",
        "ignore_tags": "keep",
        "text": [protected],
    }
    encoded = urllib.parse.urlencode(data, doseq=True).encode("utf-8")
    req = urllib.request.Request(_endpoint_for_key(api_key), data=encoded)
    req.add_header("Authorization", f"DeepL-Auth-Key {api_key}")
    with urllib.request.urlopen(req) as resp:
        raw = resp.read().decode("utf-8")
    payload = json.loads(raw)
    translations = [t["text"] for t in payload.get("translations", [])]
    final = unprotect(translations[0], target_lang.lower()) if translations else ""
    return {
        "source": text,
        "protected": protected,
        "request_text": protected,
        "raw_response": raw,
        "final": final,
    }


def main():
    api_key = os.getenv("DEEPL_API_KEY")
    if not api_key:
        print("Missing DEEPL_API_KEY env var", file=sys.stderr)
        sys.exit(1)

    if not DATA_PATH.exists():
        print(f"Missing {DATA_PATH}", file=sys.stderr)
        sys.exit(1)

    limit = None
    only_key = None
    debug_key = False
    force_prefixes = []
    force_regex = None
    force_keys = set()
    target_langs = []
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--key" and i + 1 < len(args):
            only_key = args[i + 1]
            i += 2
            continue
        if arg == "--debug-key":
            debug_key = True
            i += 1
            continue
        if arg.startswith("--key="):
            only_key = arg.split("=", 1)[1]
            i += 1
            continue
        if arg == "--limit" and i + 1 < len(args):
            limit = int(args[i + 1])
            i += 2
            continue
        if arg == "--force-prefix" and i + 1 < len(args):
            force_prefixes.append(args[i + 1])
            i += 2
            continue
        if arg.startswith("--force-prefix="):
            force_prefixes.append(arg.split("=", 1)[1])
            i += 1
            continue
        if arg == "--force-regex" and i + 1 < len(args):
            force_regex = re.compile(args[i + 1])
            i += 2
            continue
        if arg.startswith("--force-regex="):
            force_regex = re.compile(arg.split("=", 1)[1])
            i += 1
            continue
        if arg == "--force-keys" and i + 1 < len(args):
            force_keys.update([k.strip() for k in args[i + 1].split(",") if k.strip()])
            i += 2
            continue
        if arg.startswith("--force-keys="):
            force_keys.update([k.strip() for k in arg.split("=", 1)[1].split(",") if k.strip()])
            i += 1
            continue
        if arg.startswith("--limit="):
            limit = int(arg.split("=", 1)[1])
            i += 1
            continue
        target_langs.append(arg)
        i += 1
    if not target_langs:
        target_langs = ["en"]

    payload = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    keys = payload["keys"]

    def _is_forced(key: str) -> bool:
        if key in force_keys:
            return True
        if force_prefixes and any(key.startswith(p) for p in force_prefixes):
            return True
        if force_regex and force_regex.search(key):
            return True
        return False

    for lang in target_langs:
        if lang not in SUPPORTED_LANGS:
            print(f"Skipping unsupported language for DeepL: {lang}")
            continue

        target_code = SUPPORTED_LANGS[lang]
        if debug_key and only_key:
            source = keys.get(only_key, {}).get("tr", "")
            if not source:
                print(f"Missing source text for key: {only_key}")
                continue
            debug = deepl_translate_debug(source, target_code, api_key)
            print(f"[debug:{lang}] source={debug['source']}")
            print(f"[debug:{lang}] protected={debug['protected']}")
            print(f"[debug:{lang}] request_text={debug['request_text']}")
            print(f"[debug:{lang}] raw_response={debug['raw_response']}")
            print(f"[debug:{lang}] final={debug['final']}")
            # write back
            keys.setdefault(only_key, {})["tr"] = source
            keys[only_key][lang] = debug["final"]
            continue
        missing = [k for k, v in keys.items() if lang not in v or _is_forced(k)]
        # Skip Quran translations (handled via API)
        missing = [k for k in missing if not k.startswith("quran.")]
        # Skip numeric references (keep as-is)
        missing = [
            k for k in missing
            if not (k.endswith(".reference") and str(keys[k].get("tr", "")).strip().isdigit())
        ]
        # Skip hadith collections (canonical)
        missing = [k for k in missing if not k.startswith("hadith.") or not k.endswith(".collection")]
        if only_key:
            if only_key in missing:
                missing = [only_key]
            else:
                print(f"Key not missing for {lang}: {only_key}")
                continue
        if limit is not None:
            missing = missing[:limit]
        if not missing:
            print(f"No missing keys for {lang}")
            continue

        print(f"Translating {len(missing)} keys for {lang}...")

        batch = []
        batch_keys = []
        results = {}
        debug_info = []
        for key in missing:
            source = keys[key].get("tr", "")
            if not source.strip():
                continue
            protected = protect(source)
            batch.append(protected)
            batch_keys.append(key)
            if debug_key and only_key:
                debug_info.append((source, protected))

            if len(batch) >= 30:
                texts = list(batch)
                try:
                    translated = deepl_translate(texts, target_code, api_key)
                except RuntimeError as err:
                    print(f"Failed translating {lang}: {err}")
                    results = {}
                    batch = []
                    batch_keys = []
                    break
                for idx, t in enumerate(translated):
                    results[batch_keys[idx]] = unprotect(t, lang)
                batch = []
                batch_keys = []
                time.sleep(0.6)

        if batch:
            texts = list(batch)
            try:
                translated = deepl_translate(texts, target_code, api_key)
            except RuntimeError as err:
                print(f"Failed translating {lang}: {err}")
                translated = []
            for idx, t in enumerate(translated):
                results[batch_keys[idx]] = unprotect(t, lang)

        for key, value in results.items():
            keys[key][lang] = value

        if debug_key and only_key:
            for source, protected in debug_info:
                print(f"[debug:{lang}] source={source}")
                print(f"[debug:{lang}] protected={protected}")
                print(f"[debug:{lang}] translated={keys[only_key].get(lang,'')}")

        print(f"Filled {len(results)} keys for {lang}")

    DATA_PATH.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Updated {DATA_PATH}")


if __name__ == "__main__":
    main()
