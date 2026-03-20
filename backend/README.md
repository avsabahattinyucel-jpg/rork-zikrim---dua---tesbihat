Zikrim backend routes in this repo:

- `POST /api/rabia`
  Strict in-app Rabia chat endpoint powered by OpenAI.

- `POST /api/generate`
  Non-Rabia text generation endpoint for other in-app AI features.

- `GET /api/khutbah-summary`
  Returns the stored weekly khutbah summary. On-demand generation is intentionally disabled.

- `GET /api/cron/khutbah-summary`
  Weekly cron entrypoint that fetches the latest khutbah, generates the summary once, and stores it.

Required environment variables:

- `OPENAI_API_KEY`

Optional environment variables:

- `KV_REST_API_URL`
- `KV_REST_API_TOKEN`
- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`
- `KHUTBAH_CONTENT_LANGUAGE`

Either the `KV_REST_*` pair or the `UPSTASH_REDIS_REST_*` pair can be used for production storage.

If no Redis/KV storage is configured, the cron and summary endpoint fall back to a local `.cache/khutbah-summary-store.json` file for development.
