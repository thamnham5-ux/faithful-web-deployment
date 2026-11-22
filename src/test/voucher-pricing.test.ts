import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { runInNewContext } from "node:vm";
import { describe, expect, it } from "vitest";

type VoucherQuote = { subtotal: number; discount: number; total: number };
type VoucherPricing = {
  available: (voucher: { used_at: string | null } | null) => boolean;
  quote: (subtotal: number, eligible: boolean) => VoucherQuote;
};

const sandbox: { CQVoucherPricing?: VoucherPricing } = {};
const source = readFileSync(resolve(process.cwd(), "public/voucher-pricing.js"), "utf8");
runInNewContext(source, sandbox);

const pricing = sandbox.CQVoucherPricing;
if (!pricing) throw new Error("Voucher pricing helper did not load");

describe("voucher pricing", () => {
  it("applies the 5% account voucher", () => {
    expect(pricing.quote(100_000, true)).toEqual({ subtotal: 100_000, discount: 5_000, total: 95_000 });
  });

  it("marks a voucher unavailable after its one use", () => {
    expect(pricing.available({ used_at: null })).toBe(true);
    expect(pricing.available({ used_at: "2026-11-22T00:00:00Z" })).toBe(false);
  });
});