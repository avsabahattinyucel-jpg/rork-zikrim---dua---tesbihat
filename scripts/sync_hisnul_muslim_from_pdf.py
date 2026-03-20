#!/usr/bin/env python3

from __future__ import annotations

import json
import re
from pathlib import Path

try:
    import fitz
except ModuleNotFoundError as error:
    raise SystemExit(
        "PyMuPDF is required. Install it with `python3 -m pip install --user pymupdf`."
    ) from error


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PDF_PATH = Path("/Users/aliyucel/Desktop/tr_Hisnul_Muslim.pdf")
DATASET_PATH = PROJECT_ROOT / "content" / "duas" / "hisnul-muslim.json"

ENTRY_START_RE = re.compile(r'(?m)^\s*(\d{1,3})(?=\s*(?:-|\.|\(|"|“))')
ARABIC_RE = re.compile(
    r"[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDCF\uFDF0-\uFDFF\uFE70-\uFEFF]+"
)
FOOTNOTE_RE = re.compile(
    r'^\d+\s*(?:'
    r'Buhâri|Buhârî|Müslim|Tirmizi|Tirmizî|Ebu|Ebû|İbn|Hakim|Hâkim|Bkz\.?|Ahmed|Nesâi|Nesâî|'
    r'Bakara|Âl-i|Nas|İhlas|Felak|"Her|Kim|Akşam|Sabah'
    r")"
)
SOURCE_CITATION_RE = re.compile(
    r"\b(?:"
    r"Buhâri|Buhârî|Müslim|Tirmizi|Tirmizî|Ebu Dâvud|Hakim|Hâkim|Ahmed|"
    r"Nesâi|Nesâî|Bkz\.?|Yevmi ve’l-Leyle|Fethu’l-Bârî|Sahihü|Sahihu|"
    r"Silsiletu|Tuhfetu|Zâdü’l-Meâd|Mecmau|Mevârid|Muğni|Durûsu|Şerhu|"
    r"Sünen sahipleri|Amelü’l-Yevmi"
    r")\b"
)
CHAPTER_ID_RE = re.compile(r"hisn_chapter_(\d+)")


def collapse_spaces(value: str) -> str:
    value = value.replace("\r", "")
    value = re.sub(r"[ \t]+", " ", value)
    value = re.sub(r"\s+([,.;:!?])", r"\1", value)
    return value.strip()


def clean_heading(value: str) -> str:
    cleaned = collapse_spaces(value).rstrip(":").strip()
    replacements = {
        "KO RKAN": "KORKAN",
        "İ ÇİN": "İÇİN",
        "91 TEVBE VE İSTİĞFAR HAKKINDA": "TEVBE VE İSTİĞFAR HAKKINDA",
        "TESBÎH, TAHMÎD,TEHLÎL VE TEKBÎR GETİRMENİN FAZÎLETİ3": "TESBÎH, TAHMÎD,TEHLÎL VE TEKBÎR GETİRMENİN FAZÎLETİ",
        "SELÂMDAN SONRA YAPILAN DUÂLAR": "NAMAZDA SELÂMDAN SONRA YAPILAN DUÂLAR",
    }
    for old, new in replacements.items():
        cleaned = cleaned.replace(old, new)
    return cleaned


def strip_arabic(value: str) -> str:
    return ARABIC_RE.sub(" ", value)


def has_latin_text(value: str) -> bool:
    return bool(re.search(r"[A-Za-zÇĞİÖŞÜçğıöşüÂâÎîÛû]", value))


def is_heading_fragment(value: str) -> bool:
    candidate = value.strip()
    letters = [char for char in candidate if char.isalpha()]
    if not letters:
        return False

    uppercase_letters = sum(1 for char in letters if char.upper() == char)
    return uppercase_letters / len(letters) > 0.7


def is_heading_line(value: str) -> bool:
    return value.strip().endswith(":") and is_heading_fragment(value)


def extract_toc_titles(document: fitz.Document) -> list[str]:
    lines: list[str] = []
    for page_index in range(1, 7):
        text = document[page_index].get_text("text")
        lines.extend(line.strip() for line in text.splitlines() if line.strip())

    entries: list[str] = []
    buffer: list[str] = []

    for line in lines:
        if line == "İÇİNDEKİLER" or (line.isdigit() and len(line) <= 2):
            continue

        buffer.append(line)
        merged = " ".join(buffer)

        if re.search(r"\.{5,}\s*\d+$", merged):
            entry = re.sub(r"\s*\.{5,}\s*\d+$", "", merged).strip()
            entries.append(entry)
            buffer = []

    split_entries: list[str] = []
    for entry in entries:
        current = entry
        while True:
            match = re.search(r":\s*\d+\s+([A-ZÇĞİÖŞÜ\"(])", current)
            if not match:
                split_entries.append(current.strip())
                break

            split_entries.append(current[: match.start() + 1].strip())
            current = re.sub(r"^:\s*\d+\s*", "", current[match.start() + 1 :]).strip()

    chapter_titles = [clean_heading(title) for title in split_entries[2:]]
    if len(chapter_titles) != 132:
        raise RuntimeError(f"Expected 132 PDF chapter titles, found {len(chapter_titles)}")

    return chapter_titles


def extract_entry_blocks(document: fitz.Document) -> dict[int, str]:
    text = "\n".join(page.get_text("text") for page in document[13:])
    first_positions: dict[int, int] = {}

    for match in ENTRY_START_RE.finditer(text):
        number = int(match.group(1))
        if 1 <= number <= 267 and number not in first_positions:
            first_positions[number] = match.start()

    if len(first_positions) != 267:
        raise RuntimeError(
            f"Expected to capture 267 PDF entries, captured {len(first_positions)}"
        )

    accepted = sorted((start, number) for number, start in first_positions.items())

    blocks: dict[int, str] = {}
    for index, (start, number) in enumerate(accepted):
        end = accepted[index + 1][0] if index + 1 < len(accepted) else len(text)
        blocks[number] = text[start:end].strip()

    return blocks


def extract_entry_headings(document: fitz.Document) -> dict[int, str]:
    lines: list[str] = []
    for page in document[13:]:
        lines.extend(page.get_text("text").splitlines())

    current_heading: str | None = None
    buffer: list[str] = []
    entry_headings: dict[int, str] = {}

    for raw_line in lines:
        line = collapse_spaces(strip_arabic(raw_line))
        if not line:
            continue

        match = ENTRY_START_RE.match(line)
        if match:
            number = int(match.group(1))
            if 1 <= number <= 267 and number not in entry_headings and current_heading:
                entry_headings[number] = current_heading
            buffer = []
            continue

        if is_heading_fragment(line):
            buffer.append(line)
            if ":" in line:
                current_heading = clean_heading(" ".join(buffer))
                buffer = []
            continue

        buffer = []

    if len(entry_headings) != 267:
        raise RuntimeError(
            f"Expected to capture 267 PDF entry headings, captured {len(entry_headings)}"
        )

    return entry_headings


def extract_meaning(block: str) -> str:
    lines: list[str] = []
    started = False

    for raw_line in block.splitlines():
        line = collapse_spaces(strip_arabic(raw_line))
        if not line:
            continue
        if line.isdigit() and len(line) <= 3:
            continue
        if line in {"﴿", "﴾"}:
            continue
        if re.fullmatch(r"\[[^\]]+\]", line):
            continue
        if re.match(r"^\d+\s*(?:-|\.)", line):
            line = re.sub(r"^\d+\s*(?:-|\.)\s*", "", line)
        if FOOTNOTE_RE.match(line):
            continue
        if is_heading_line(line) and started:
            break
        if not has_latin_text(line):
            continue
        started = True
        lines.append(line)

    text = " ".join(lines)
    text = re.sub(r"^\(\d+/\d+\)\s*", "", text)
    text = re.sub(r'(?<=[A-Za-zÇĞİÖŞÜçğıöşüÂâÎîÛû"”’)])([1-9])\b', "", text)
    source_match = SOURCE_CITATION_RE.search(text)
    if source_match:
        text = text[: source_match.start()].rstrip(" .;,-")
    text = re.sub(r'([.?!])([A-ZÇĞİÖŞÜ"])', r"\1 \2", text)
    text = collapse_spaces(text)
    return text.strip()


def numeric_id(entry_id: str) -> int | None:
    match = re.search(r"-(\d+)$", entry_id)
    if not match:
        return None
    return int(match.group(1))


def chapter_number(category_id: str) -> int:
    match = CHAPTER_ID_RE.search(category_id)
    if not match:
        raise RuntimeError(f"Unexpected category id: {category_id}")
    return int(match.group(1))


def main() -> None:
    document = fitz.open(PDF_PATH)
    chapter_titles = extract_toc_titles(document)
    entry_blocks = extract_entry_blocks(document)
    entry_headings = extract_entry_headings(document)

    payload = json.loads(DATASET_PATH.read_text())
    duas = payload["duas"]

    kept_duas = []
    heading_counts: dict[str, int] = {}

    for dua in duas:
        number = numeric_id(dua["id"])
        if number is None or number not in entry_blocks:
            continue

        heading = entry_headings.get(number) or chapter_titles[chapter_number(dua["category_id"]) - 1]
        heading_counts[heading] = heading_counts.get(heading, 0) + 1
        kept_duas.append(dua)

    for dua in kept_duas:
        number = numeric_id(dua["id"])
        assert number is not None

        chapter_title = entry_headings.get(number) or chapter_titles[chapter_number(dua["category_id"]) - 1]
        display_title = (
            f"{chapter_title} ({number})"
            if heading_counts[chapter_title] > 1
            else chapter_title
        )

        dua["title"]["tr"] = display_title
        dua["category_title"]["tr"] = chapter_title
        dua["meaning"]["tr"] = extract_meaning(entry_blocks[number])
        dua["metadata"]["order_index"] = number

    payload["duas"] = kept_duas
    DATASET_PATH.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

    print(f"Synced {len(kept_duas)} Hisnul Muslim entries from PDF.")


if __name__ == "__main__":
    main()
