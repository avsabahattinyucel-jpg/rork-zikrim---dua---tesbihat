import { describe, expect, it } from "vitest";

import { normalizeParsedPage } from "../pipeline/normalize";
import { toContentHash } from "../utils/hash";
import { deriveStableId, normalizeUrl } from "../utils/url";

describe("normalization", () => {
  it("produces stable content hashes", () => {
    const value = "Başlık\nSoru\nCevap";
    expect(toContentHash(value)).toBe(toContentHash(value));
  });

  it("generates stable canonical ids from numeric URLs", () => {
    expect(
      deriveStableId(
        "https://kurul.diyanet.gov.tr/soru/1106/dua-ederken-tevessul-caiz-midir",
        "qa",
      ),
    ).toBe("diyk_qa_1106");
  });

  it("normalizes Diyanet list URLs to avoid duplicate crawl branches", () => {
    expect(
      normalizeUrl(
        "https://kurul.diyanet.gov.tr/Konu-Cevap-Ara/01933666-74ba-730a-1575-1c7ca5452841/zekatin-verilecegi-yerler?enc=AHA%2BHk6MQxWJ6yi80nKvBA%3D%3D&sayfa=1",
      ),
    ).toBe(
      "https://kurul.diyanet.gov.tr/Konu-Cevap-Ara/01933666-74ba-730a-1575-1c7ca5452841/zekatin-verilecegi-yerler",
    );

    expect(
      normalizeUrl(
        "https://kurul.diyanet.gov.tr/Konu-Cevap-Ara/01933666-74ba-730a-1575-1c7ca5452841/zekatin-verilecegi-yerler?enc=AHA%2BHk6MQxWJ6yi80nKvBA%3D%3D&sayfa=3",
      ),
    ).toBe(
      "https://kurul.diyanet.gov.tr/Konu-Cevap-Ara/01933666-74ba-730a-1575-1c7ca5452841/zekatin-verilecegi-yerler?sayfa=3",
    );
  });

  it("rejects empty or invalid pages and normalizes valid pages", () => {
    const valid = normalizeParsedPage({
      source_url: "https://kurul.diyanet.gov.tr/soru/1106/dua-ederken-tevessul-caiz-midir",
      source_domain: "kurul.diyanet.gov.tr",
      page_type: "qa",
      title: "Dua ederken tevessül caiz midir?",
      question: "Dua ederken tevessül caiz midir?",
      answer_html: "<p>Dua ibadeti yalnız Allah'a yapılır.</p>",
      answer_text: "Dua ibadeti yalnız Allah'a yapılır.",
      breadcrumb: ["İNANÇ", "DUA"],
      category_labels: ["İNANÇ", "DUA"],
      decision: {
        decision_kind: null,
        decision_year: null,
        decision_no: null,
        subject: null,
      },
      language: "tr",
      canonical_identifier: "1106",
      discovered_at: "2026-03-16T00:00:00.000Z",
      fetched_at: "2026-03-16T00:00:01.000Z",
      parsed_at: "2026-03-16T00:00:02.000Z",
      raw_path: "/tmp/qa.html",
      low_confidence: false,
      invalid_reason: null,
    });

    expect(valid.accepted?.id).toBe("diyk_qa_1106");
    expect(valid.accepted?.answer_text_clean).toContain("Allah'a yapılır");

    const invalid = normalizeParsedPage({
      source_url: "https://kurul.diyanet.gov.tr/soru/9999/kayit-bulunamadi",
      source_domain: "kurul.diyanet.gov.tr",
      page_type: "qa",
      title: "Kayıt Bulunamadı",
      question: null,
      answer_html: "<p>Kayıt Bulunamadı</p>",
      answer_text: "Kayıt Bulunamadı",
      breadcrumb: [],
      category_labels: [],
      decision: {
        decision_kind: null,
        decision_year: null,
        decision_no: null,
        subject: null,
      },
      language: "tr",
      canonical_identifier: null,
      discovered_at: "2026-03-16T00:00:00.000Z",
      fetched_at: "2026-03-16T00:00:01.000Z",
      parsed_at: "2026-03-16T00:00:02.000Z",
      raw_path: "/tmp/not-found.html",
      low_confidence: true,
      invalid_reason: "record_not_found",
    });

    expect(invalid.rejected?.reason).toBe("record_not_found");
  });
});
