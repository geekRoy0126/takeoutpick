import { describe, expect, it } from "vitest";

import { basisPointsOf, formatCents, percentOf } from "./money";

describe("formatCents", () => {
  it("formats integer cents as US dollars", () => {
    expect(formatCents(1234)).toBe("$12.34");
    expect(formatCents(0)).toBe("$0.00");
  });

  it("rejects non-integer input so dollar floats never slip in", () => {
    expect(() => formatCents(12.34)).toThrow(TypeError);
  });
});

describe("percentOf", () => {
  it("rounds to the nearest cent", () => {
    // 15% of $10.99 = 164.85 cents -> 165
    expect(percentOf(1099, 15)).toBe(165);
  });
});

describe("basisPointsOf", () => {
  it("applies a tax rate expressed in basis points", () => {
    // 9.38% of $20.00 = 187.6 cents -> 188
    expect(basisPointsOf(2000, 938)).toBe(188);
  });
});
