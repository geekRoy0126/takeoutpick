// Money helpers. All amounts are integer cents; never store or compute money as floating-point dollars.

const usd = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" });

/** 1234 -> "$12.34" */
export function formatCents(cents: number): string {
  assertCents(cents);
  return usd.format(cents / 100);
}

/** round(cents × percent / 100), e.g. a 15% service fee. */
export function percentOf(cents: number, percent: number): number {
  assertCents(cents);
  return Math.round((cents * percent) / 100);
}

/** round(cents × bps / 10000), e.g. a 9.38% tax rate is 938 bps. */
export function basisPointsOf(cents: number, bps: number): number {
  assertCents(cents);
  return Math.round((cents * bps) / 10_000);
}

function assertCents(cents: number): void {
  if (!Number.isInteger(cents)) {
    throw new TypeError(`Expected integer cents, got ${cents}`);
  }
}
