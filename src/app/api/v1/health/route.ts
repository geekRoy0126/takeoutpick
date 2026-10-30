// GET /api/v1/health — liveness check used by CI smoke tests and deploy previews.
import { ok } from "@/lib/api/http";

export function GET(): Response {
  return ok({ status: "ok" });
}
