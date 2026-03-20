import type { AppConfig } from "../types";

interface RobotsRules {
  allows: string[];
  disallows: string[];
  sitemaps: string[];
}

function pathMatchesRule(pathname: string, rule: string): boolean {
  if (!rule) {
    return false;
  }

  const normalizedRule = rule.replace(/\*/g, ".*");
  return new RegExp(`^${normalizedRule}`).test(pathname);
}

function isAllowedByRules(pathname: string, rules: RobotsRules): boolean {
  const matchingAllow = rules.allows.filter((rule) => pathMatchesRule(pathname, rule));
  const matchingDisallow = rules.disallows.filter((rule) => pathMatchesRule(pathname, rule));

  const longestAllow = matchingAllow.sort((left, right) => right.length - left.length)[0] ?? "";
  const longestDisallow = matchingDisallow.sort((left, right) => right.length - left.length)[0] ?? "";

  if (!longestDisallow) {
    return true;
  }

  return longestAllow.length >= longestDisallow.length;
}

function parseRobots(content: string, targetUserAgent: string): RobotsRules {
  const lines = content
    .split(/\r?\n/)
    .map((line) => line.replace(/#.*$/, "").trim())
    .filter(Boolean);

  const rules: RobotsRules = {
    allows: [],
    disallows: [],
    sitemaps: [],
  };

  let currentAgents: string[] = [];

  for (const line of lines) {
    const [fieldRaw = "", valueRaw = ""] = line.split(":", 2);
    const field = fieldRaw.trim().toLowerCase();
    const value = valueRaw.trim();

    if (field === "user-agent") {
      currentAgents = [value.toLowerCase()];
      continue;
    }

    if (field === "sitemap") {
      rules.sitemaps.push(value);
      continue;
    }

    const applies =
      currentAgents.includes("*") || currentAgents.some((agent) => targetUserAgent.includes(agent));

    if (!applies) {
      continue;
    }

    if (field === "allow" && value) {
      rules.allows.push(value);
    }

    if (field === "disallow" && value) {
      rules.disallows.push(value);
    }
  }

  return rules;
}

export class RobotsChecker {
  private readonly cache = new Map<string, RobotsRules | null>();

  public constructor(private readonly config: AppConfig) {}

  public async getRules(url: string): Promise<RobotsRules | null> {
    const host = new URL(url).origin;
    if (this.cache.has(host)) {
      return this.cache.get(host) ?? null;
    }

    try {
      const response = await fetch(`${host}/robots.txt`, {
        headers: {
          "user-agent": this.config.userAgent,
        },
        signal: AbortSignal.timeout(this.config.fetchTimeoutMs),
      });

      if (!response.ok) {
        this.cache.set(host, null);
        return null;
      }

      const text = await response.text();
      const rules = parseRobots(text, this.config.userAgent.toLowerCase());
      this.cache.set(host, rules);
      return rules;
    } catch {
      this.cache.set(host, null);
      return null;
    }
  }

  public async canFetch(url: string): Promise<boolean> {
    if (!this.config.respectRobots) {
      return true;
    }

    const rules = await this.getRules(url);
    if (!rules) {
      return true;
    }

    return isAllowedByRules(new URL(url).pathname, rules);
  }

  public async getSitemapHints(url: string): Promise<string[]> {
    const rules = await this.getRules(url);
    return rules?.sitemaps ?? [];
  }
}
