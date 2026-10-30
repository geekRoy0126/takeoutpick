// HTTP helpers shared by every route handler under src/app/api.
// Every error response uses the same envelope: { "error": { "code": string, "message": string } }.
import type { z } from "zod";

export type ErrorCode =
  | "BAD_REQUEST"
  | "VALIDATION_FAILED"
  | "UNAUTHENTICATED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "CONFLICT"
  | "INTERNAL";

const STATUS: Record<ErrorCode, number> = {
  BAD_REQUEST: 400,
  VALIDATION_FAILED: 422,
  UNAUTHENTICATED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL: 500,
};

export class ApiError extends Error {
  constructor(
    readonly code: ErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export function ok<T>(data: T, init?: ResponseInit): Response {
  return Response.json({ data }, init);
}

export function errorResponse(code: ErrorCode, message: string): Response {
  return Response.json({ error: { code, message } }, { status: STATUS[code] });
}

/** Turns thrown errors into the envelope. Unknown errors become a generic 500 so internals never leak. */
export function toErrorResponse(err: unknown): Response {
  if (err instanceof ApiError) return errorResponse(err.code, err.message);
  console.error(err);
  return errorResponse("INTERNAL", "Something went wrong.");
}

/** Parses input with a zod schema or throws a 422 ApiError listing the first problem. */
export function parseOrThrow<S extends z.ZodType>(schema: S, input: unknown): z.infer<S> {
  const result = schema.safeParse(input);
  if (!result.success) {
    const issue = result.error.issues[0];
    const path = issue?.path.join(".") || "input";
    throw new ApiError("VALIDATION_FAILED", `${path}: ${issue?.message ?? "invalid"}`);
  }
  return result.data;
}
