# GhostKey — Competitor Features Gap Analysis

**Date:** 2026-06-20  
**Scope:** GhostKey (local codebase) vs ente Auth (reference), plus research on Aegis, 2FAS, Google Authenticator, Authy, Raivo, Bitwarden Authenticator  
**Goal:** Identify features missing from GhostKey, prioritize for Home tab and Heirs tab replacements.

---

## HOW WE GOT HERE: Current GhostKey Tab State

### Home tab (`VaultDashboard`)
- **What it shows:** Static demo data — "Good morning, Alex 👋" (hardcoded), a Dead Man's Switch card showing "65 days left" (static), stats cards ("34 Secrets", "12 Crypto Assets", "3 Heirs" — hardcoded), and an activity feed with 3 fake entries. The notification bell has a hardcoded badge dot.
- **Problem:** All data is simulated; nothing is real or functional. The "Check in now" button does nothing. No actual Dead Man's Switch logic exists. The activity log is a hardcoded list. The tab currently has zero utility.
- **Opportunity:** This tab is prime real estate for a real dashboard — security overview, recent activity tracking, Dead Man's Switch management, and quick actions.

### Heirs tab (`HeirsPage`)
- **What it shows:** A hardcoded list of 3 fake heirs ("Sarah Ahmed", "Ahmed Rahman", "John Smith") with fake relations and shares. The "Add Heir" button does nothing. There is no storage, no UI for adding/managing heirs, no inheritance logic, no real feature behind it.
- **Problem:** Entirely cosmetic — static data, no CRUD, no logic, no persistence.
- **Opportunity:** Real inheritance/trustee management — or if that's too ambitious, repurpose the tab for something actually useful.

---

## CATEGORIZED MISSING FEATURES

### PRIORITY P0 — HOME TAB REPLACEMENT FEATURES (Critical)
*These features would give the Home tab real purpose and are feasible to implement quickly.*

| # | Feature | Present in | GhostKey Status | Description |
|---|---------|------------|-----------------|-------------|
| 1 | **Real Dashboard with Live Stats** | ente, Aegis | ❌ Stub (hardcoded) | Show real counts: total TOTP codes, pinned items, trashed items, vault items. Track last-sync/backup timestamp. Use real data from CodeStore + VaultStore. |
| 2 | **Activity Log / Audit Trail** | ente | ❌ Stub (fake data) | Track real events: code added/edited/deleted, login times, backup events, export events. Store in SQLite with timestamps. |
| 3 | **Quick Actions Row** | ente, Aegis, Authy | ❌ Missing | Floating action buttons or row: Add Code (scan QR), Add Vault Item, Import, Create Backup. Ente shows these as rounded action buttons on home. |
| 4 | **Recently Used Codes** | ente (sort option) | ❌ Not on home page | GhostKey has `recentlyUsed` sort but no dedicated "recent" section on the dashboard. Show last 5 tapped codes with timestamps. |
| 5 | **Security Score / Status Card** | Bitwarden | ❌ Missing | Show vault health: number of weak/pending items, last backup date, lock status, sync status. Single card summarizing security posture. |

### PRIORITY P0 — HEIRS TAB REPLACEMENT FEATURES (Critical)
*These features would give the Heirs tab real purpose — or replace it entirely.*

| # | Feature | Present in | GhostKey Status | Description |
|---|---------|------------|-----------------|-------------|
| 6 | **Real Heir/Trustee Management** | (GhostKey's own concept) | ❌ Stub | Full CRUD for heirs: add with name/email/phone, assign portions, set inheritance rules. Model + storage + UI. Dead Man's Switch integration. |
| 7 | **OR: Tags & Groups Management** | ente (Tags), Aegis (Groups), 2FAS (Folders) | ⚠️ Data model exists, no UI | GhostKey's `CodeDisplay` already has `tags` field! But there's zero UI to create/edit/assign/filter-by-tags. This is the easiest win — add a tag management screen on the Heirs tab (or replace it). Aegis groups + ente tags show this is a top-requested feature. |
| 8 | **OR: Trash / Recently Deleted** | ente (trash), Aegis | ⚠️ `trashed` field exists but no UI | GhostKey's `CodeDisplay` has `trashed` flag and codes are filtered out in HomePage, but there's no trash view to recover or permanently delete trashed codes. Perfect use for the Heirs tab slot. |
| 9 | **OR: Code Notes Browser** | ente | ⚠️ `note` field exists but no UI | GhostKey's `CodeDisplay` has `note` field but no way to view/edit notes inline. A tab showing all codes with notes would be useful. |
| 10 | **OR: All-Codes Browser (flat list)** | ente Home | ❌ Missing merged view | GhostKey splits codes across "Vault" (2FA tab) and "Vault" tab (filtered). No single "all codes everywhere" view. |

### PRIORITY P1 — Data Management (High)

| # | Feature | Present in | GhostKey Status | Description |
|---|---------|------------|-----------------|-------------|
| 11 | **Encrypted Cloud Sync** | ente, Authy, Bitwarden | ❌ Local-only | End-to-end encrypted sync across devices. Ente uses their own server; GhostKey would need a backend. This is ambitious but the biggest differentiator. |
| 12 | **Export: Encrypted** | ente | ❌ Stub ("coming soon") | Password-encrypted JSON export. Ente uses libsodium XChaCha20-Poly1305 + Argon2id KDF. |
| 13 | **Export: Plain Text** | ente | ❌ Stub ("coming soon") | Simple otpauth:// URI text file. |
| 14 | **Export: HTML** | ente | ❌ Missing | Generates a human-readable HTML page with all codes, issuer icons, and QR codes. Great for printing. |
| 15 | **Local Auto-Backup** | ente, Aegis | ❌ Stub ("coming soon") | Scheduled automatic backups to a device folder. Ente supports daily automatic encrypted backups. |
| 16 | **Backup Password** | ente, Aegis | ❌ Missing | Password-protect the backup file. Separate from app unlock. |
| 17 | **Duplicate Code Detection** | ente | ❌ Missing | Detect and bulk-delete duplicate entries. Ente has a dedicated `DuplicateCodePage`. GhostKey currently allows adding same code multiple times. |
| 18 | **Bulk Code Management** | ente, Aegis | ⚠️ Partial | GhostKey has multi-select for pin/unpin/delete but no batch tag assignment, batch export, or batch move operations. |

### PRIORITY P1 — Security & Authentication (High)

| # | Feature | Present in | GhostKey Status | Description |
|---|---------|------------|-----------------|-------------|
| 19 | **App Lock (Idle Timeout)** | ente, Aegis, Authy | ❌ Missing | Auto-lock after configurable idle time (immediately, 1min, 5min, 15min, etc.). GhostKey has PIN/biometric unlock on startup but no re-lock on background/inactivity. |
| 20 | **Hide Codes (Privacy Mode)** | ente, Aegis | ❌ Missing | Toggle to hide all TOTP codes behind blurred dots by default. Double-tap to reveal. Prevents shoulder-surfing. |
| 21 | **Screen Capture Prevention** | Aegis, 2FAS | ❌ Missing | Android: `FLAG_SECURE` to prevent screenshots/recording. iOS: `UIApplication.isIdleTimerDisabled` equivalent. |
| 22 | **Compact Mode** | ente, Aegis | ❌ Missing | Denser code list — smaller icons, less padding, more codes per screen. |
| 23 | **Minimize on Copy** | ente (Android) | ❌ Missing | Auto-minimize app after copying a TOTP code (so the code is immediately pastable in the target app). |

### PRIORITY P2 — UI & UX (Medium)

| # | Feature | Present in | GhostKey Status | Description |
|---|---------|------------|-----------------|-------------|
| 24 | **Tags Management UI** | ente, Aegis | ⚠️ Model exists, no UI | Create/edit/delete tags, assign to codes via multi-select, filter by tag. The data model (`CodeDisplay.tags`) and DB schema already support this. Only UI is missing. |
| 25 | **Trash / Recently Deleted View** | ente, Aegis | ⚠️ Model exists, no UI | View trashed codes, recover or permanently delete. The `trashed` field exists in `CodeDisplay`. |
| 26 | **Code Notes UI** | ente | ⚠️ Model exists, no UI | View/edit notes attached to each code. The `note` field exists in `CodeDisplay`. |
| 27 | **Custom Icons / App Icon Pack** | ente, Aegis, 2FAS | ❌ Missing | Let user choose from multiple app icon packs (ente lets you change the app's home screen icon). Brand SVG icons exist but custom icon selection per-code is in model but likely not exposed. |
| 28 | **Large Icons Toggle** | ente | ❌ Missing | Show larger/brand icons in the code list. |
| 29 | **Multi-Language Support** | ente (i18n), Aegis (i18n) | ❌ English only | Full i18n system. Ente supports 20+ languages. |
| 30 | **Dark Theme / AMOLED Theme** | Aegis, ente, Authy | ❌ Light only | GhostKey has only light mode. Aegis has multiple dark themes including pure black AMOLED. |
| 31 | **Color-Coded Groups/Categories** | Aegis (groups), 2FAS (folders) | ❌ Missing | Assign codes to color-coded groups. Aegis allows custom group icons and colors. |

### PRIORITY P2 — Code Sharing & Collaboration (Medium)

| # | Feature | Present in | GhostKey Status | Description |
|---|---------|------------|-----------------|-------------|
| 32 | **Time-Limited Code Sharing** | ente | ❌ Missing | Share a time-limited encrypted link to a TOTP code. Ente generates links like `https://auth.ente.com/share?...` that expire after 2/5/10 minutes. |
| 33 | **Share Codes via Native Share** | ente, Aegis | ❌ Missing | Share individual codes or bulk via OS share sheet. |
| 34 | **QR Code Display** | ente, Aegis | ❌ Missing | Show QR code of an otpauth:// URI for a code, allowing easy transfer to another device. |

### PRIORITY P3 — Platform Integration (Low)

| # | Feature | Present in | GhostKey Status | Description |
|---|---------|------------|-----------------|-------------|
| 35 | **Apple Watch Companion App** | Raivo, 2FAS, Authy | ❌ Missing | View TOTP codes on Apple Watch. |
| 36 | **Wear OS Companion App** | Aegis (via tile), 2FAS | ❌ Missing | View TOTP codes on Wear OS watch/tile. |
| 37 | **Browser Extension** | Bitwarden, 2FAS | ❌ Missing | Auto-fill TOTP codes via browser extension. |
| 38 | **Auto-fill Service (Android/iOS)** | Bitwarden, Authy, Aegis | ❌ Missing | System-level autofill provider that auto-fills TOTP codes. |
| 39 | **Desktop App** | ente (cross-platform), Authy | ❌ Missing | GhostKey runs on desktop (Flutter) but isn't positioned as a desktop auth app. |
| 40 | **Push Notification for HOTP Sync** | Raivo | ❌ Missing | For HOTP codes, push notification to sync counter between devices. |

### PRIORITY P3 — Account & Cloud (Low/Deferred)

| # | Feature | Present in | GhostKey Status | Description |
|---|---------|------------|-----------------|-------------|
| 41 | **Account Management** | ente | ❌ Missing | Change email, change password, recovery key, view active sessions, delete account. GhostKey has stub auth screens but no real backend. |
| 42 | **Passkey Support** | ente | ❌ Missing | Passkey-based recovery for account access. |
| 43 | **Email MFA** | ente | ❌ Missing | MFA on the auth app account itself (not TOTP codes — protecting access to the app). |
| 44 | **Billing/Subscription** | ente | ❌ Missing | Pro tier management, payment methods. GhostKey has a static "GhostKey Pro" card in settings. |
| 45 | **Offline Mode Toggle** | ente | ❌ Missing | Explicit online/offline mode switch. Ente shows this on the onboarding page. |

### PRIORITY P3 — Quality of Life (Low)

| # | Feature | Present in | GhostKey Status | Description |
|---|---------|------------|-----------------|-------------|
| 46 | **Search Auto-Focus** | ente | ❌ Missing | Option to auto-focus on search bar when entering the app. |
| 47 | **Minimize to System Tray** | ente (desktop) | ❌ Missing | Desktop: minimize to system tray on close instead of quitting. |
| 48 | **Crash & Error Reporting** | ente | ❌ Missing | Opt-in crash reporting to improve app stability. |
| 49 | **In-App Update Notification** | ente | ❌ Missing | Check for and notify about app updates. |
| 50 | **Rate Us Prompt** | ente | ❌ Missing | Prompt user to rate the app on Play Store/App Store. |
| 51 | **Social Links** | ente | ❌ Missing | Links to blog, Discord, Twitter, GitHub, etc. |
| 52 | **FAQ / Help Links** | ente | ❌ Missing | In-app FAQ and help links. |

---

## RECOMMENDED HOME TAB REPLACEMENT (Quick Wins)

The Home tab currently shows fake data. Here's a phased plan to make it useful:

### Phase 1 (Implement in hours/days):
1. **Real stat cards** — pull actual counts from CodeStore + VaultStore
2. **Recently Used Codes section** — query codes sorted by `lastUsedAt`
3. **Real activity log** — store events (code added/removed/viewed) in the existing SQLite DB with a simple event table
4. **Quick actions row** — "Scan QR", "Add Vault Item", "Create Backup" buttons

### Phase 2 (Implement in days/weeks):
5. **Dead Man's Switch live status** — real countdown, check-in mechanism, timer display
6. **Security summary card** — last backup, lock status, total items count

## RECOMMENDED HEIRS TAB REPLACEMENT (Quick Wins)

The Heirs tab is entirely fake. Top candidates to replace it:

### Best Option: Tags & Notes Management
GhostKey **already has the data model** for tags and notes in `CodeDisplay`. Only the UI is missing. Building a tag management view here would:
- Be quick to implement (no new DB schema needed)
- Deliver immediate value (users can organize codes)
- Match features in ente (Tags), Aegis (Groups), and 2FAS (Folders)

### Second Option: Trash View
Also already in the data model (`trashed` field). A trash view with restore/permanent-delete would fill the tab nicely and add safety.

### Third Option: Code Notes Browser
The `note` field exists in `CodeDisplay` but has no UI anywhere. A notes-focused tab where users can browse codes that have notes attached would be useful.

---

## SUMMARY TABLE — Top 10 Quick Wins

| Rank | Feature | Tab Fit | Effort | Impact |
|------|---------|---------|--------|--------|
| 1 | **Tags Management UI** | Heirs tab | Low | High |
| 2 | **Real Dashboard Stats** | Home tab | Low | High |
| 3 | **Trash View** | Heirs tab | Low | Medium |
| 4 | **Recently Used Codes** | Home tab | Low | Medium |
| 5 | **Real Activity Log** | Home tab | Medium | Medium |
| 6 | **Code Notes UI** | Heirs tab | Low | Medium |
| 7 | **Duplicate Code Detection** | Settings → Data | Medium | Medium |
| 8 | **Encrypted Export** | Settings → Data | Medium | Medium |
| 9 | **Hide Codes (Privacy)** | Settings → General | Low | Medium |
| 10 | **App Lock Timeout** | Settings → Security | Medium | High |
