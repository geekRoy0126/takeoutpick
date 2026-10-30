// Integration tests call route handlers directly with a real Request and (when needed) a real Postgres.
// Run with `npm run test:int` after `docker compose up -d db` and `npx prisma migrate deploy`.
import { describe, expect, it } from "vitest";

import { GET } from "@/app/api/v1/health/route";

describe("GET /api/v1/health", () => {
  it("returns ok in the data envelope", async () => {
    const res = GET();
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ data: { status: "ok" } });
  });
});
