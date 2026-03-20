import test from "node:test";
import assert from "node:assert/strict";

import { getCannedResponse } from "../backend/lib/canned-responses/cannedResponses.js";
import { shouldEscalateToLLM } from "../backend/lib/canned-responses/messageClassifier.js";

test("her intent için temel canned eşleşme çalışır", () => {
  const cases = [
    { message: "selam", locale: "tr", intent: "greeting" },
    { message: "naber", locale: "tr", intent: "how_are_you" },
    { message: "thanks", locale: "en", intent: "thanks" },
    { message: "bye", locale: "en", intent: "goodbye" },
    { message: "tamam", locale: "tr", intent: "short_positive" },
    { message: "no", locale: "en", intent: "short_negative" },
    { message: "amin", locale: "tr", intent: "blessings" },
    { message: "🙂", locale: "tr", intent: "emoji_only" },
    { message: "kimsin", locale: "tr", intent: "who_are_you" },
    { message: "what can you do", locale: "en", intent: "what_can_you_do" }
  ] as const;

  for (const entry of cases) {
    const result = getCannedResponse(entry.message, entry.locale, {
      selectionSeed: 1
    });

    assert.equal(result.handled, true);
    if (result.handled) {
      assert.equal(result.intent, entry.intent);
      assert.equal(result.source, "canned");
      assert.ok(result.response.length > 0);
    }
  }
});

test("karışık selamlama ve ciddi ihtiyaç LLM'e eskale edilir", () => {
  const cases = [
    "merhaba dua öner",
    "selam içim daralıyor",
    "how are you i feel terrible"
  ];

  for (const message of cases) {
    assert.equal(shouldEscalateToLLM(message), true);
    const result = getCannedResponse(message, "tr");
    assert.equal(result.handled, false);
    assert.equal(result.reason, "escalate_to_llm");
  }
});

test("desteklenmeyen locale İngilizceye düşer", () => {
  const result = getCannedResponse("hello", "it", {
    selectionSeed: 5
  });

  assert.equal(result.handled, true);
  if (result.handled) {
    assert.equal(result.locale, "en");
    assert.equal(result.intent, "greeting");
  }
});

test("emoji-only mesajlar canned olarak döner", () => {
  const result = getCannedResponse("🙂✨", "tr");

  assert.equal(result.handled, true);
  if (result.handled) {
    assert.equal(result.intent, "emoji_only");
  }
});

test("uzatılmış harfler ve dağınık noktalama normalize edilir", () => {
  const result = getCannedResponse("Selaaaam!!!", "tr");

  assert.equal(result.handled, true);
  if (result.handled) {
    assert.equal(result.intent, "greeting");
    assert.ok(["synonym", "regex", "heuristic"].includes(result.matchType));
  }
});

test("Arapça, Farsça ve Urdu script eşleşmeleri çalışır", () => {
  const arabic = getCannedResponse("السلام عليكم", "ar");
  const persian = getCannedResponse("سلام", "fa");
  const urdu = getCannedResponse("آپ کون ہیں", "ur");

  assert.equal(arabic.handled, true);
  assert.equal(persian.handled, true);
  assert.equal(urdu.handled, true);

  if (arabic.handled) {
    assert.equal(arabic.intent, "greeting");
  }

  if (persian.handled) {
    assert.equal(persian.intent, "greeting");
  }

  if (urdu.handled) {
    assert.equal(urdu.intent, "who_are_you");
  }
});

test("aynı intentte son kullanılan cevap varsa farklı cevap tercih edilir", () => {
  const first = getCannedResponse("selam", "tr", {
    selectionSeed: 7
  });

  assert.equal(first.handled, true);
  if (!first.handled) {
    return;
  }

  const second = getCannedResponse("selam", "tr", {
    selectionSeed: 7,
    recentResponseKeys: [first.responseKey]
  });

  assert.equal(second.handled, true);
  if (second.handled) {
    assert.notEqual(second.responseKey, first.responseKey);
  }
});
