#!/usr/bin/env python3

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from pypdf import PdfReader


PAGE_MARKER_RE = re.compile(r"<<PAGE:(\d+)>>")
ARABIC_CLOSING_RE = re.compile(
    r"(?<!\d)(\d{1,3})\s*سُبْحَانَكَ.*?(?:خَلِّصْنَا|أَجِرْنَا|نَجِّنَا)\s+مِنَ\s+النَّارِ",
    re.S,
)
TURKISH_CLOSING_RE = re.compile(
    r"(?<!\d)(\d{1,3})\.\s*Sübhânsın.*?Cehennem[’']den!?",
    re.S,
)
ARABIC_ITEM_RE = re.compile(r"(?<!\d)(10|[1-9])\s*(?=[اأإآٱىيئةبتثجحخدذرزسشصضطظعغفقكلمنهو])")
TURKISH_ITEM_RE = re.compile(r"(?<!\d)(10|[1-9])\.\s*")
ARABIC_DIGITS = {
    0: "٠",
    1: "١",
    2: "٢",
    3: "٣",
    4: "٤",
    5: "٥",
    6: "٦",
    7: "٧",
    8: "٨",
    9: "٩",
    10: "١٠",
}

MANUAL_SECTION_OVERRIDES: dict[int, dict[str, list[str]]] = {
    73: {
        "arabic": [
            "هُوَ أَحَدٌ بِلاَ ضِدٍّ",
            "وَهُوَ فَرْدٌ بِلاَ نِدٍّ",
            "وَهُوَ صَمَدٌ بِلاَ عَيْبٍ",
            "وَهُوَ وِتْرٌ بِلاَ شَفْعٍ",
            "وَهُوَ رَبٌّ بِلاَ وَزِيرٍ",
            "وَهُوَ غَنِيٌّ بِلاَ فَقْرٍ",
            "وَهُوَ سُلْطَانٌ بِلاَ عَزْلٍ",
            "وَهُوَ مَلِكٌ بِلاَ عَجْزٍ",
            "وَهُوَ مَوْجُودٌ بِلاَ مِثْلٍ",
        ],
        "turkish": [
            "Zıddı olmayan bir olan",
            "Eşi benzeri olmayan tek olan",
            "Hiçbir kusuru bulunmayan, hiçbir şeye muhtaç olmayan",
            "Eşi bulunmayan tek olan",
            "Yardımcıya ihtiyacı olmayan Rab",
            "Fakirlikten münezzeh, zengin olan",
            "Saltanatı elinden alınamayan",
            "Acizlikten uzak hükümdar",
            "Benzeri olmayan varlık",
        ],
    },
    83: {
        "arabic": [
            "مَنْ جَعَلَ الْأَرْضَ مِهَادًا",
            "وَمَنْ جَعَلَ الْجِبَالَ أَوْتَادًا",
            "وَمَنْ جَعَلَ الشَّمْسَ سِرَاجًا",
            "وَمَنْ جَعَلَ الْقَمَرَ نُورًا",
            "وَمَنْ جَعَلَ اللَّيْلَ لِبَاسًا",
            "وَمَنْ جَعَلَ النَّهَارَ مَعَاشًا",
            "وَمَنْ جَعَلَ النَّوْمَ سُبَاتًا",
            "وَمَنْ جَعَلَ السَّمَاءَ بِنَاءً",
            "وَمَنْ جَعَلَ الْأَشْيَاءَ أَزْوَاجًا",
            "وَمَنْ جَعَلَ النَّارَ مِرْصَادًا",
        ],
        "turkish": [
            "Yeryüzünü döşek yapan",
            "Dağları direk yapan",
            "Güneşi bir kandil yapan",
            "Ay'ı nur yapan",
            "Geceyi örtü yapan",
            "Gündüzü geçim vakti yapan",
            "Uykuyu dinlenme yapan",
            "Göğü bir bina yapan",
            "Her şeyi çift yaratan",
            "Cehennemi gözetleyici kılan",
        ],
    },
    86: {
        "arabic": [
            "مَنْ لَا مُلْكَ إِلَّا مُلْكُهُ",
            "وَمَنْ لَا يُحْصَى ثَنَاؤُهُ",
            "وَمَنْ لَا تَبْلُغُ الْخَلَائِقُ جَلَالَهُ",
            "وَمَنْ لَا تُدْرِكُ الْأَبْصَارُ كَمَالَهُ",
            "وَمَنْ لَا تَنَالُ الْأَفْهَامُ صِفَاتِهِ",
            "وَمَنْ لَا يُحِيطُ الْإِنْسَانُ بِنُعُوتِهِ",
            "وَمَنْ لَا يُرَدُّ الْعِبَادُ قَضَاءَهُ",
            "وَمَنْ أَظْهَرَ فِي كُلِّ شَيْءٍ آيَاتِهِ",
        ],
        "turkish": [
            "Mülkü yalnız kendisine ait olan",
            "Senası sayılmakla bitmeyen",
            "Yaratılmışların azametini kavrayamadığı",
            "Gözlerin kemalini idrak edemediği",
            "Akılların sıfatlarını kavrayamadığı",
            "İnsanların niteliklerini kuşatamadığı",
            "Hükmü geri çevrilemeyen",
            "Her şeyde ayetlerini gösteren",
        ],
    },
    97: {
        "arabic": [
            "مَنْ لَا يُمَلُّ مِنْ إِلْحَاحِ الْمُلِحِّينَ",
            "وَمَنْ شَرَحَ صُدُورَ الْمُؤْمِنِينَ",
            "وَمَنْ أَنَارَ قُلُوبَ الذَّاكِرِينَ",
            "وَمَنْ لَا يَغِيبُ عَنْ قُلُوبِ الْمُخْبِتِينَ",
            "وَمَنْ هُوَ غَايَةُ مُرَادِ الْمُرِيدِينَ",
            "وَمَنْ لَا يَخْفَى عَلَيْهِ شَيْءٌ فِي الْعَالَمِينَ",
        ],
        "turkish": [
            "Israr edenlerin ısrarından usanmayan",
            "Müminlerin kalplerini genişleten",
            "Zikredenlerin kalplerini nurlandıran",
            "Kendisine yönelenlerin kalbinden kaybolmayan",
            "Arayanların en yüce maksadı olan",
            "Âlemde hiçbir şey kendisine gizli olmayan",
        ],
    },
}


@dataclass
class ParsedSection:
    section_number: int
    body: str
    closing: str
    page_start: int
    page_end: int


def main() -> int:
    if len(sys.argv) != 4:
        print(
            "Usage: parse_cevsen_pdf.py <input.pdf> <output_bundle.json> <output_report.json>",
            file=sys.stderr,
        )
        return 1

    pdf_path = Path(sys.argv[1]).expanduser()
    bundle_path = Path(sys.argv[2]).expanduser()
    report_path = Path(sys.argv[3]).expanduser()

    reader = PdfReader(str(pdf_path))

    arabic_sections, arabic_remainder = parse_sections(
        reader=reader,
        page_indexes=list(range(2, 90, 2)) + [90, 92],
        cleaner=lambda raw: normalize_lines(raw, arabic=True),
        closing_re=ARABIC_CLOSING_RE,
    )
    turkish_sections, turkish_remainder = parse_sections(
        reader=reader,
        page_indexes=list(range(3, 90, 2)) + [91, 93],
        cleaner=lambda raw: normalize_lines(raw, arabic=False),
        closing_re=TURKISH_CLOSING_RE,
    )

    arabic_by_number = {section.section_number: section for section in arabic_sections}
    turkish_by_number = {section.section_number: section for section in turkish_sections}

    sections = []
    flagged_for_manual_review: list[dict[str, object]] = []

    for section_number in range(1, 101):
        arabic = arabic_by_number.get(section_number)
        turkish = turkish_by_number.get(section_number)
        if arabic is None or turkish is None:
            flagged_for_manual_review.append(
                {
                    "sectionNumber": section_number,
                    "reason": "missing paired section",
                    "hasArabic": arabic is not None,
                    "hasTurkish": turkish is not None,
                }
            )
            continue

        ordered_arabic_items, arabic_item_notes = parse_arabic_items(arabic.body)
        ordered_turkish_items, turkish_preamble, turkish_item_notes = parse_turkish_items(turkish.body)

        closing_arabic = normalize_arabic_text(canonicalize_arabic_closing(arabic.closing))
        closing_turkish = normalize_turkish_text(canonicalize_turkish_closing(turkish.closing))

        override = MANUAL_SECTION_OVERRIDES.get(section_number)
        if override is not None:
            full_arabic = "\n\n".join(
                [*override["arabic"], closing_arabic]
            ).strip()
            full_turkish = "\n\n".join(
                [*[f"{index}. {text}" for index, text in enumerate(override["turkish"], start=1)], closing_turkish]
            ).strip()
            review_notes: list[str] = []
        else:
            full_arabic = "\n\n".join(
                [
                    *[format_arabic_item(number, text) for number, text in ordered_arabic_items],
                    closing_arabic,
                ]
            ).strip()

            meaning_parts = []
            if turkish_preamble:
                meaning_parts.append(turkish_preamble)
            meaning_parts.extend(format_turkish_item(number, text) for number, text in ordered_turkish_items)
            meaning_parts.append(closing_turkish)
            full_turkish = "\n\n".join(part for part in meaning_parts if part).strip()

            review_notes = arabic_item_notes + turkish_item_notes
            if len(ordered_arabic_items) != 10:
                review_notes.append(f"arabic item count={len(ordered_arabic_items)}")
            if len(ordered_turkish_items) != 10:
                review_notes.append(f"turkish item count={len(ordered_turkish_items)}")

        if review_notes:
            flagged_for_manual_review.append(
                {
                    "sectionNumber": section_number,
                    "reason": " ; ".join(review_notes),
                }
            )

        sections.append(
            {
                "id": f"cevsen_{section_number:03d}",
                "sectionNumber": section_number,
                "title": f"Cevşen {section_number}. Bab",
                "arabic": full_arabic,
                "meaningTr": full_turkish,
                "closingArabic": closing_arabic,
                "closingMeaningTr": closing_turkish,
                "previewTr": build_preview(full_turkish),
                "arabicPageRange": [arabic.page_start, arabic.page_end],
                "turkishPageRange": [turkish.page_start, turkish.page_end],
                "needsReview": bool(review_notes),
            }
        )

    supplement = build_supplement_entry(arabic_remainder, turkish_remainder)
    if supplement["needsReview"]:
        flagged_for_manual_review.append(
            {
                "sectionNumber": "supplement",
                "reason": "supplement extracted with normalization warnings",
            }
        )

    duplicate_ids = find_duplicates(section["id"] for section in sections)
    invalid_numbering = find_invalid_numbering(section["sectionNumber"] for section in sections)

    report = {
        "sourcePdf": str(pdf_path),
        "totalSectionsParsed": len(sections),
        "missingArabicCount": sum(1 for section in sections if not section["arabic"].strip()),
        "missingTurkishCount": sum(1 for section in sections if not section["meaningTr"].strip()),
        "duplicateIds": duplicate_ids,
        "invalidSectionNumbering": invalid_numbering,
        "sectionsFlaggedForManualReview": flagged_for_manual_review,
        "supplementIncluded": True,
        "supplementArabicLength": len(supplement["arabic"]),
        "supplementTurkishLength": len(supplement["meaningTr"]),
    }

    bundle = {
        "sourcePdf": pdf_path.name,
        "parserSummary": report,
        "sections": sections,
        "supplement": supplement,
    }

    bundle_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    bundle_path.write_text(json.dumps(bundle, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


def parse_sections(
    reader: PdfReader,
    page_indexes: Iterable[int],
    cleaner,
    closing_re: re.Pattern[str],
) -> tuple[list[ParsedSection], str]:
    buffer = ""
    sections: list[ParsedSection] = []

    for idx in page_indexes:
        page_no = idx + 1
        page_text = cleaner(reader.pages[idx].extract_text() or "")
        buffer += f" <<PAGE:{page_no}>> {page_text}"

        while True:
            match = closing_re.search(buffer)
            if match is None:
                break

            chunk = buffer[: match.end()]
            page_numbers = [int(value) for value in PAGE_MARKER_RE.findall(chunk)]
            clean_chunk = PAGE_MARKER_RE.sub(" ", chunk)
            clean_chunk = re.sub(r"\s+", " ", clean_chunk).strip()
            closing_match = closing_re.search(clean_chunk)
            if closing_match is None:
                break

            sections.append(
                ParsedSection(
                    section_number=int(closing_match.group(1)),
                    body=clean_chunk[: closing_match.start()].strip(),
                    closing=closing_match.group(0).strip(),
                    page_start=min(page_numbers) if page_numbers else page_no,
                    page_end=max(page_numbers) if page_numbers else page_no,
                )
            )
            buffer = buffer[match.end() :]

    remainder = PAGE_MARKER_RE.sub(" ", buffer)
    remainder = re.sub(r"\s+", " ", remainder).strip()
    return sections, remainder


def normalize_lines(raw: str, *, arabic: bool) -> str:
    text = raw.replace("\x00", " ")
    for ch in "•":
        text = text.replace(ch, " ")
    text = text.replace("\u00ad", "")
    text = text.replace("", "ش")
    if arabic:
        text = text.replace("ـ", "")

    lines = [line.strip() for line in text.splitlines() if line.strip()]
    merged: list[str] = []
    index = 0

    while index < len(lines):
        line = lines[index]
        if re.fullmatch(r"\d{1,3}", line):
            number = int(line)
            next_line = lines[index + 1] if index + 1 < len(lines) else ""
            if number > 10:
                if next_line and (
                    ("سُبْحَانَكَ" in next_line and not re.match(r"\d{1,3}\s", next_line))
                    or ("Sübhânsın" in next_line and not re.match(r"\d{1,3}\.", next_line))
                ):
                    merged.append(f"{line}{next_line}")
                    index += 2
                    continue
                index += 1
                continue
            if next_line:
                merged.append(f"{line}{next_line}")
                index += 2
                continue
        merged.append(line)
        index += 1

    joined = " ".join(merged)
    joined = re.sub(r"(\w)-\s+(\w)", r"\1\2", joined)
    if arabic:
        joined = re.sub(r"(?<=\d)(\d{2,3}\s+سُبْحَانَكَ)", r" \1", joined)
    else:
        joined = re.sub(r"(?<=\d)(\d{2,3}\.\s+Sübhânsın)", r" \1", joined)
    joined = re.sub(r"1\s+00(?=\s+سُبْحَانَكَ)", "100", joined)
    joined = re.sub(r"1\s+00(?=\.\s+Sübhânsın)", "100", joined)
    joined = re.sub(r"\s+", " ", joined).strip()
    return joined


def parse_arabic_items(body: str) -> tuple[list[tuple[int, str]], list[str]]:
    matches = list(ARABIC_ITEM_RE.finditer(body))
    if not matches:
        return [], ["arabic items not detected"]

    ordered: dict[int, str] = {}
    notes: list[str] = []

    for index, match in enumerate(matches):
        number = int(match.group(1))
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(body)
        text = normalize_arabic_text(body[start:end])
        if not text:
            notes.append(f"arabic item {number} empty")
            continue
        ordered[number] = text

    if set(ordered) != set(range(1, 11)):
        missing = [number for number in range(1, 11) if number not in ordered]
        extra = [number for number in ordered if number not in range(1, 11)]
        if missing:
            notes.append(f"arabic missing items={missing}")
        if extra:
            notes.append(f"arabic extra items={extra}")

    return [(number, ordered[number]) for number in sorted(ordered)], notes


def parse_turkish_items(body: str) -> tuple[list[tuple[int, str]], str, list[str]]:
    matches = list(TURKISH_ITEM_RE.finditer(body))
    if not matches:
        return [], normalize_turkish_text(body), ["turkish items not detected"]

    preamble = normalize_turkish_text(body[: matches[0].start()])
    ordered: dict[int, str] = {}
    notes: list[str] = []

    for index, match in enumerate(matches):
        number = int(match.group(1))
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(body)
        text = normalize_turkish_text(body[start:end])
        if not text:
            notes.append(f"turkish item {number} empty")
            continue
        ordered[number] = text

    if set(ordered) != set(range(1, 11)):
        missing = [number for number in range(1, 11) if number not in ordered]
        extra = [number for number in ordered if number not in range(1, 11)]
        if missing:
            notes.append(f"turkish missing items={missing}")
        if extra:
            notes.append(f"turkish extra items={extra}")

    return [(number, ordered[number]) for number in sorted(ordered)], preamble, notes


def canonicalize_arabic_closing(value: str) -> str:
    if "أَجِرْنَا" in value:
        return "سُبْحَانَكَ يَا لَا إِلٰهَ إِلَّا أَنْتَ الْأَمَانَ الْأَمَانَ أَجِرْنَا مِنَ النَّارِ"
    if "نَجِّنَا" in value:
        return "سُبْحَانَكَ يَا لَا إِلٰهَ إِلَّا أَنْتَ الْأَمَانَ الْأَمَانَ نَجِّنَا مِنَ النَّارِ"
    return "سُبْحَانَكَ يَا لَا إِلٰهَ إِلَّا أَنْتَ الْأَمَانَ الْأَمَانَ خَلِّصْنَا مِنَ النَّارِ"


def canonicalize_turkish_closing(value: str) -> str:
    return normalize_turkish_text(
        value.replace("’", "'")
        .replace("Sübhânsın yâ Rab!", "Sübhânsın yâ Rab!")
        .replace("Sen'den", "Sen’den")
        .replace("Cehennem'den", "Cehennem’den")
    )


def normalize_arabic_text(value: str) -> str:
    text = value.strip()
    text = text.replace("اَللّٰهُمَّ", "اللّٰهُمَّ").replace("اَللهُ", "اللهُ")
    text = re.sub(r"\bلَ (?=[اأإآٱىيئةبتثجحخدذرزسشصضطظعغفقكلمنهو])", "لَا ", text)
    text = text.replace("الْمَانَ", "الأَمَانَ")
    text = text.replace("الَْ", "الأَ")
    text = text.replace("الِْ", "الإِ")
    text = text.replace("الُْ", "الأُ")
    text = text.replace("  ", " ")
    text = re.sub(r"\s+", " ", text)
    return text.strip(" ،")


def normalize_turkish_text(value: str) -> str:
    text = value.strip()
    text = text.replace(" - ", "")
    text = re.sub(r"\s+", " ", text)
    return text.strip(" ,")


def format_arabic_item(number: int, text: str) -> str:
    return f"{ARABIC_DIGITS[number]}. {text}"


def format_turkish_item(number: int, text: str) -> str:
    return f"{number}. {text}"


def build_preview(text: str) -> str:
    sentence = text.split("\n", 1)[0].strip()
    return sentence[:220].rstrip()


def build_supplement_entry(arabic_remainder: str, turkish_remainder: str) -> dict[str, object]:
    arabic = normalize_arabic_text(arabic_remainder)
    turkish = normalize_turkish_text(turkish_remainder)
    needs_review = False

    if not arabic or not turkish:
        needs_review = True

    return {
        "id": "cevsen_supplement",
        "title": "Cevşen Son Dua",
        "arabic": arabic,
        "meaningTr": turkish,
        "previewTr": build_preview(turkish),
        "needsReview": needs_review,
    }


def find_duplicates(values: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    duplicates: list[str] = []
    for value in values:
        if value in seen and value not in duplicates:
            duplicates.append(value)
        seen.add(value)
    return duplicates


def find_invalid_numbering(values: Iterable[int]) -> list[int]:
    ordered = list(values)
    return [value for value in ordered if value < 1 or value > 100]


if __name__ == "__main__":
    raise SystemExit(main())
