import { describe, expect, it, vi } from "vitest";
import { z } from "zod";

import { ApiError, errorResponse, ok, parseOrThrow, toErrorResponse } from "./http";

describe("ok", () => {
  it("wraps data in a data envelope", async () => {
    const res = ok({ id: "r1" });
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ data: { id: "r1" } });
  });
});

describe("errorResponse", () => {
  it("uses the error envelope and the matching status", async () => {
    const res = errorResponse("FORBIDDEN", "Partners only.");
    expect(res.status).toBe(403);
    expect(await res.json()).toEqual({ error: { code: "FORBIDDEN", message: "Partners only." } });
  });
});

describe("toErrorResponse", () => {
  it("passes ApiError through", async () => {
    const res = toErrorResponse(new ApiError("NOT_FOUND", "No such deal."));
    expect(res.status).toBe(404);
  });

  it("hides unknown errors behind a generic 500", async () => {
    vi.spyOn(console, "error").mockImplementation(() => {});
    const res = toErrorResponse(new Error("connection string leaked"));
    expect(res.status).toBe(500);
    expect(JSON.stringify(await res.json())).not.toContain("connection string");
  });
});

describe("parseOrThrow", () => {
  const schema = z.object({ minOrderCents: z.number().int().nonnegative() });

  it("returns parsed data when valid", () => {
    expect(parseOrThrow(schema, { minOrderCents: 2000 })).toEqual({ minOrderCents: 2000 });
  });

  it("throws a 422 ApiError naming the bad field", () => {
    expect(() => parseOrThrow(schema, { minOrderCents: -1 })).toThrow(/minOrderCents/);
  });
});
