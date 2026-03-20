export const sourceHash = "2026-03-02-reset-1";

export function redirectSystemPath({
  path,
  initial,
}: {
  path: string;
  initial: boolean;
  sourceHash?: string;
}): string {
  void path;
  void initial;
  return "/";
}

export default {
  sourceHash,
  redirectSystemPath,
};