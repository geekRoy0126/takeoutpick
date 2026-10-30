import "@testing-library/jest-dom/vitest";

import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";

// Vitest globals are off, so Testing Library cannot register its auto-cleanup. Unmount after every test
// (found by both HW3 test runs; see AGENTS.md changelog v1.1).
afterEach(() => {
  cleanup();
});
