import Link from "next/link";

const sections = [
  { href: "/restaurants", title: "Browse", body: "Real totals with fees, tip and tax." },
  { href: "/pick", title: "Pick for me", body: "Three taps to a decision." },
  { href: "/rooms", title: "Group Pick", body: "Vote with roommates in real time." },
];

export default function HomePage() {
  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-8 px-4 py-12">
      <header className="flex flex-col gap-2">
        <h1 className="text-3xl font-semibold tracking-tight">TakeoutPick</h1>
        <p className="text-ink-muted">Decide what to order in seconds, with what it really costs.</p>
      </header>

      <ul className="grid gap-3 sm:grid-cols-3">
        {sections.map((s) => (
          <li key={s.href}>
            <Link
              href={s.href}
              className="flex min-h-11 flex-col gap-1 rounded-xl border border-line bg-surface-muted p-4 hover:border-brand-500 focus-visible:outline-2 focus-visible:outline-brand-600"
            >
              <span className="font-medium">{s.title}</span>
              <span className="text-sm text-ink-muted">{s.body}</span>
            </Link>
          </li>
        ))}
      </ul>
    </main>
  );
}
