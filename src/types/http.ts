export interface ApiRequestLike {
  method?: string;
  query?: Record<string, string | string[] | undefined>;
  body?: unknown;
}

export interface ApiResponseLike {
  setHeader(name: string, value: string): ApiResponseLike | void;
  status(code: number): ApiResponseLike;
  send(body: string): void;
}
