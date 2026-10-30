# TakeoutPick — Product Requirements (Project 2)

Owner: Ruoyu Wang + partner · Course: CS6983 AI Coding, Fall 2026 · Last updated: 2026-10-30

## 1. Problem

Students who order takeout 1–4 times a week lose 10–25 minutes per decision when they have no craving.
Our HW2 Mom Test interviews (3 participants, Oct 11–12, 2026) found:

- Delivery fee, service fee and tip only appear at checkout, and they change the decision (all 3 raised this unprompted).
- Deals pull people into unplanned orders; coupons are scattered across apps and expire unnoticed.
- One participant added a drink he didn't want just to reach a $20 deal minimum.
- Long searches end in repeating the same meal and regretting it.

Project 1 (a single-file Claude Web artifact with browser storage) proved the core loop for one person.
Project 2 turns it into a multi-user full-stack product.

## 2. What changes in P2

| P1 prototype | P2 product |
| --- | --- |
| One user, data in browser storage | Accounts, roles, PostgreSQL |
| Every diner types in their own restaurants and deals | Shared catalog; restaurant partners publish official deals |
| Decide alone | Group Pick rooms: roommates vote live (real-time) |
| No integrations | Public REST API v1 with OpenAPI docs |

New P2 hypotheses (not yet validated by interviews): roommates decide together often enough to want a shared vote,
and official partner deals reduce the "scattered coupons" problem. We will check both in the Sprint 1 demo.

## 3. Roles

| Role | Who | Can do |
| --- | --- | --- |
| Diner | Student who orders takeout | Browse catalog, compare, Pick for me, log orders, add community deals, host or join Group Pick rooms |
| Partner | Restaurant owner or staff | After admin approval: manage their restaurant's menu and fees, publish official deals |
| Admin | Course team / moderator | Approve partner requests, hide or delete deals, change user roles |

A new account is always a Diner. Only an Admin can grant Partner or Admin.

## 4. Pricing rules (shared by every feature)

All money is stored and computed as integer cents.

1. Subtotal = dish price × quantity.
2. Discount applies to the subtotal only, and only if subtotal ≥ the deal's minimum order.
   - Percent-off: `round(subtotal × percent / 100)`. Amount-off: the fixed amount, never more than the subtotal.
3. Delivery total = (subtotal − discount) + delivery fee + service fee + tip + tax.
   - Service fee = `round((subtotal − discount) × restaurant.serviceFeePercent / 100)`.
   - Tip = `round((subtotal − discount) × diner.tipPercent / 100)` (default 15%).
   - Tax = `round((subtotal − discount) × diner.taxRateBps / 10000)` (default 0; diner sets their local rate).
4. Pickup total = (subtotal − discount) + tax. No delivery fee, service fee or tip.
5. Rounding: `Math.round` to the nearest cent at each step above.

Deal status, computed from the current time (never stored):

| Status | Rule | Display |
| --- | --- | --- |
| Expired | now ≥ expiresAt | Greyed out, never applied |
| Expiring soon | expiresAt − now ≤ 72 hours | Amber badge |
| Active | otherwise | Green badge |

Hidden deals (moderated by an admin) are never shown or applied.

## 5. User stories and acceptance criteria

Priority uses MoSCoW. Issue numbers refer to the GitHub issues created by `scripts/setup-github-scrum.sh`.

### US1 — Account and roles (Must, #3)
As a diner, I want to register and log in, so that my orders and preferences follow me across devices.
- [ ] I can register with name, email and a password of at least 8 characters; duplicate emails are rejected with a clear message.
- [ ] I can log in and log out; the session lasts 7 days.
- [ ] The session is a signed JWT in an httpOnly, Secure, SameSite=Lax cookie.
- [ ] Partner pages require role PARTNER, admin pages require ADMIN; the API answers 401 when logged out and 403 for the wrong role.
- [ ] Passwords are hashed with bcrypt (cost 12) and never returned by any API.

### US2 — Restaurant and dish catalog (Must, #4)
As a diner, I want to browse restaurants and dishes with what they really cost, so that I don't get surprised at checkout.
- [ ] I can browse restaurants, filter by cuisine and open a restaurant's dish list.
- [ ] Each dish shows an estimated delivery total and pickup total (Section 4).
- [ ] Tapping or hovering a total reveals the breakdown: subtotal, discount, delivery fee, service fee, tip, tax.
- [ ] A diner can suggest a new restaurant; it shows as "Unverified" until an admin or its partner verifies it.
- [ ] Typical fees are prefilled ($3.99 delivery, 15% service) so adding a restaurant takes under 30 seconds.

### US3 — Deals with status (Must, #5)
As a diner, I want to see which deals I can still use and what a dish costs after the deal, so that deals stop expiring unnoticed.
- [ ] Each deal shows a status badge: Active, Expiring soon (≤ 72 h) or Expired (Section 4).
- [ ] A dish with an applicable deal shows its price before (struck through) and after the deal.
- [ ] If the order subtotal is below the deal's minimum, the deal is not applied and the UI shows "Add $X.XX more to use this deal".
- [ ] Official deals (from a partner) and community deals (from diners) carry different labels.
- [ ] `GET /api/v1/deals?status=active` returns only non-hidden, non-expired deals, soonest expiry first.

### US4 — Compare side by side (Should, #6)
As a diner, I want to compare 2–4 dishes by total cost and health level, so that I can trade off saving money and eating healthy.
- [ ] I can select 2–4 dishes: a table on desktop (≥ 768 px), stacked cards on a phone.
- [ ] A pickup/delivery toggle updates every total.
- [ ] The cheapest and the healthiest options are highlighted; "Healthiest" appears only when health levels differ.
- [ ] Options over my budget are flagged.

### US5 — Order log and variety (Should, #7)
As a diner, I want to log what I ordered, so that I see my spending and stop repeating the same meal.
- [ ] I can add, edit and delete orders; price and health level prefill from the dish.
- [ ] A 7-day summary shows the number of orders, total spent and health mix.
- [ ] When the price paid differs from the estimate by more than $2.00, the difference is shown.
- [ ] Each dish shows when I last had it; a "Haven't had lately" toggle hides dishes I ordered in the last 7 days.

### US6 — Pick for me (Must, #8)
As a diner, I want the app to pick for me from my budget, deals, health goal and mood, so that I decide in seconds.
- [ ] I answer at most 3 button questions: budget, health goal today, cuisine mood (or "surprise me").
- [ ] I see 1 top pick and up to 2 alternatives, each with its estimated total and a one-line "Why this".
- [ ] Options over budget are never suggested; dishes I ate in the last 7 days rank lower; active deals rank higher.
- [ ] "I ordered this" logs the order (US5).

### US7 — Group Pick room, real-time (Must, #9)
As a diner ordering with roommates, I want us to vote together, so that we decide in minutes instead of arguing.
- [ ] A host creates a room with an optional budget and cuisine and gets a 6-character code and a share link.
- [ ] Logged-in diners join with the code; each member can nominate up to 2 dishes.
- [ ] Each member has 1 vote and can change it until the room closes.
- [ ] Nominations, votes and the member list update for everyone within 2 seconds, without reloading.
- [ ] The host closes the room; everyone sees the winner. A tie goes to the lower delivery total.

### US8 — Partner portal (Must, #10)
As a restaurant partner, I want to manage my menu and publish official deals, so that students see accurate prices and my promotions.
- [ ] A diner can request partner access for a restaurant; the request is pending until an admin approves.
- [ ] An approved partner can edit their restaurant's fees and create, edit and delete its dishes.
- [ ] A partner can publish, edit and end official deals for their own restaurant only (403 otherwise).
- [ ] The portal lists the restaurant's deals with their status (US3).

### US9 — Admin console (Must, #11)
As an admin, I want to verify partners and moderate content, so that the catalog stays trustworthy.
- [ ] I see pending partner requests and can approve or reject each one; approval sets the user's role to PARTNER and links the restaurant.
- [ ] I can hide or delete any deal; hidden deals disappear from every list and from the API.
- [ ] I can change a user's role; I cannot remove my own admin role.

### US10 — Public API v1 (Must, #12)
As a developer, I want a documented API, so that other tools can read restaurants and deals.
- [ ] Public read endpoints: `GET /api/v1/restaurants`, `/restaurants/{id}`, `/restaurants/{id}/dishes`, `/deals`.
- [ ] Authenticated endpoints (`Authorization: Bearer <JWT>` or the session cookie): `GET` and `POST /api/v1/orders`.
- [ ] Every error uses `{ "error": { "code": string, "message": string } }` with a correct HTTP status.
- [ ] The OpenAPI 3.1 document is served at `/api/v1/openapi.json` and rendered with Swagger UI at `/api-docs`.

## 6. Non-functional requirements

| Area | Requirement |
| --- | --- |
| Responsive | Works from 375 px wide; tap targets ≥ 44 × 44 px |
| Accessibility | WCAG 2.1 AA: labels on every input, visible focus, status never shown by color alone |
| Performance | API p95 < 500 ms on seeded data; first load < 2.5 s LCP on a mid-range phone |
| Security | Input validated with zod on every route; Prisma only (no raw SQL); secrets only in env vars |
| Testing | Unit + integration + E2E; ≥ 80% line coverage on `src/lib/domain` |

## 7. Out of scope

Payments, real delivery-app integrations, scraping deals from DoorDash or Uber Eats, native mobile apps.

## 8. Timeline

| Milestone | Dates | Goal |
| --- | --- | --- |
| Sprint 1 | Oct 31 – Nov 5, 2026 | Scaffold, CI, auth, catalog, deals, compare, order log |
| Sprint 2 | Nov 6 – Nov 11, 2026 | Pick for me, Group Pick (real-time), partner portal, admin, public API, security scans, docs |
| Submission | Nov 12, 2026 | Demo video, retrospectives, reflections |
