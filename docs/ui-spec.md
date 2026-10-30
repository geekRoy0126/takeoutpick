# TakeoutPick — UI spec

This spec turns the Project 1 prototype (a Claude Web artifact, link in the HW3 submission) into rules for P2.
The prototype was tested step by step against three interview-based scenarios; keep its interaction choices unless
an issue says otherwise.

## 1. Look and feel

- Calm, food-app warmth: one brand color (tomato, `brand-*` tokens), warm greys, lots of white space.
- Mobile first. Design at 375 px, then widen to a centered column (max 768 px for content, 1024 px for tables).
- Tokens live in `src/app/globals.css`. Use semantic utilities (`bg-surface-muted`, `text-ink-muted`,
  `bg-deal-soon`) — never raw hex values or arbitrary colors.
- Every status pairs color with a text label or icon (color-blind safe).
- Tap targets ≥ 44 × 44 px (`min-h-11 min-w-11`).

## 2. What the prototype established

| Pattern | Rule for P2 |
| --- | --- |
| Totals, not menu prices | Show the estimated total first, the menu price second. Default mode is delivery. |
| Price breakdown | Desktop: breakdown on hover/focus of the total. Phone: tap the total to reveal it inline (no hover). |
| Deal badges on cards | A restaurant card shows a badge with the best applicable deal and its status. |
| Variety dots | A row of up to 5 small dots, one per cuisine ordered in the last 7 days. |
| "Healthiest" label | Only shown when the compared options have different health levels. |
| Compare layout | Table at ≥ 768 px; stacked cards below. |
| Pick for me | At most 3 questions, buttons only, no typing. |

## 3. Key components

| Component | Location | Expected behavior |
| --- | --- | --- |
| `DealBadge` | `components/deals/` | Pill with label "Active", "Expiring soon" or "Expired" + icon; colors `deal-active` / `deal-soon` / `deal-expired`; "Official" or "Community" tag beside it. |
| `PriceWithDeal` | `components/deals/` | Struck-through total before the deal, bold total after. When below the minimum: no discount, plus `MinOrderHint`. |
| `MinOrderHint` | `components/deals/` | Text "Add $X.XX more to use this deal" in `text-deal-soon`, announced via `aria-live="polite"` when it changes. |
| `PriceBreakdown` | `components/pricing/` | Rows: subtotal, discount, delivery fee, service fee, tip, tax, total. Pickup hides delivery fee, service fee and tip. |
| `HealthTag` | `components/ui/` | Pill "Healthy" / "Balanced" / "Indulgent" with `health-*` color and a leaf / scale / cake icon. |
| `DishCard` | `components/restaurants/` | Name, `HealthTag`, `PriceWithDeal`, "Last had: 3 days ago" or "New to you". |
| `RestaurantCard` | `components/restaurants/` | Name, cuisine, fees summary, best `DealBadge`, "Unverified" tag when not verified. |
| `CompareView` | `components/compare/` | 2–4 dishes; pickup/delivery toggle; "Cheapest", "Healthiest", "Over budget" labels. |
| `PickWizard` | `components/pick/` | 3 steps (budget → health goal → cuisine or "Surprise me"), back button, then 1 top pick + up to 2 alternatives with a "Why this" line. |
| `RoomPanel` | `components/rooms/` | Room code + copy-link button, live member list, nominations with vote counts, "Your vote" highlight, host-only "Close room". |
| `EmptyState` | `components/ui/` | Icon, one sentence, one primary action. Every list has one. |

Loading: skeletons that match the final layout (no spinners for page content). Errors: inline message with a retry
button; never a blank screen.

## 4. User flows to follow

1. **Pick for me** — Home → "Pick for me" → budget ($10 / $15 / $20 / $25+) → health goal (Healthy / Balanced /
   Treat myself) → cuisine (chips + "Surprise me") → result card with top pick → "I ordered this" logs it and shows a
   toast with Undo (5 s).
2. **Deal-aware browsing** — Restaurants list (filter chips by cuisine) → restaurant → dish cards with totals → tap a
   total for the breakdown → choose quantity → if below a deal minimum, `MinOrderHint` updates live.
3. **Group Pick** — Host taps "Start a room" → sets budget/cuisine (optional) → gets code + share link → members
   join → each nominates up to 2 dishes → everyone votes → counts update live → host closes → winner card for all.
4. **Become a partner** — Diner opens a restaurant → "I run this restaurant" → short message → request pending →
   admin approves → partner sees "Partner" nav item → edits menu and publishes official deals.
5. **Moderation** — Admin → "Requests" tab (approve/reject) → "Deals" tab (hide/delete) → "Users" tab (change role).

## 5. Navigation

Phone: bottom tab bar (Home, Browse, Pick, Rooms, Me). Desktop: top bar with the same items; "Partner" and "Admin"
appear only for those roles.
