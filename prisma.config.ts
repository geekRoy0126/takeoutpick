// Prisma 7 reads its settings from this file (not from package.json or the schema's datasource block).
import "dotenv/config";
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
  },
  datasource: {
    // Not env("DATABASE_URL"): that throws when the variable is missing, which would break `npm install`
    // (postinstall runs `prisma generate`, which needs no database). Migrations still fail loudly without it.
    url: process.env.DATABASE_URL ?? "",
  },
});
