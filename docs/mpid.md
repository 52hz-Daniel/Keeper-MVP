# Master Project Instruction Document (MPID)

**Project Name:** Keeper: AI Baby Log & Sync
**Version:** 2.0 (The "Intuitive" Edition)
**Status:** Active Construction
**Date:** November 24, 2025

## 1. Executive Summary & Value Proposition

### Objective (Logical Thinking)
Build a "Voice-First" parenting management system. Unlike traditional trackers (Huckleberry) that require manual data entry (tapping buttons), Keeper uses AI to parse natural language voice/text logs into structured data. It acts as a communication bridge between partners, reducing conflict and mental load.

### The "Hook" (Entrepreneurial Focus)
*   **Core Desire:** "Peace of Mind" & "Sleep." Parents want to offload the mental burden of remembering details.
*   **The "Aha" Moment:** The user speaks a messy sentence: *"She just ate 4oz and had a blowout diaper,"* and the app instantly converts it into a clean, structured log *and* updates the partner.
*   **Tagline:** "Keeper remembers, so you can sleep."

### Target Audience
*   **Primary:** First-time mothers (0-12 months postpartum). High anxiety, low sleep.
*   **Secondary:** The "Out of the Loop" partner (usually the father).

### Key Success Metrics (KPIs)
*   **The "5-Second Rule":** A new user must be able to log their first event within 5 seconds of opening the app (Zero-Onboarding).
*   **Accuracy:** User correction rate < 5% (The "Ghost Log" draft should be correct most of the time).
*   **Retention:** 30% of users logging data on Day 7.

## 2. Technical Architecture and Stack

**Principle:** "Speed & Safety." We use Expo for cross-platform speed and Supabase for backend stability.

### Core Stack
*   **Frontend:** **React Native (Expo)** with **Expo Router**.
    *   *Why:* Native mobile experience (Push Notifications, Audio Recording), with a "Next.js-like" file structure.
*   **UI Library:** **NativeWind** (Tailwind CSS for React Native) + **Lucide React Native** (Icons).
*   **Backend / DB:** **Supabase** (PostgreSQL).
    *   *Must use:* Row Level Security (RLS) policies from Day 1.
*   **AI Engine:** **OpenAI API** (Model: gpt-4o-mini).
*   **State Management:** **Zustand** (Simple, no boilerplate).

### The "Growth" Stack
*   **Auth:** **Supabase Auth** (Apple & Google Sign-In).
*   **Analytics:** **PostHog** (Capture "Log Created" events).

### UI Design References (North Stars)
*   **WhatsApp / iMessage:** The main view must look exactly like a chat. Bubbles on the right (User), Bubbles on the left (AI).
*   **Granola (AI Meeting Notes):** The "Draft/Ghost Log" pattern. We show a structured summary that the user must confirm.

## 3. Directory Structure (Strict Expo Router)

The AI Developer must follow this structure. Do not allow it to create random root files.

```
/
├── .cursor/rules/          # AI Rules
├── app/                    # Expo Router (File-system routing)
│   ├── (auth)/             # Login/Signup flows
│   ├── (app)/              # Protected Routes
│   │   ├── _layout.tsx
│   │   ├── index.tsx       # The Main Chat Interface
│   │   └── settings.tsx
│   └── _layout.tsx
├── components/
│   ├── ui/                 # Reusable atoms (Buttons, Input)
│   ├── chat/               # Chat-specific components (Bubbles, GhostLogCard)
│   └── safety/             # Medical guardrail components
├── lib/
│   ├── supabase.ts         # Supabase Client
│   ├── openai.ts           # AI Logic & Prompts
│   ├── safety.ts           # HARD-CODED Safety Logic (No AI here)
│   └── audio.ts            # Voice recording logic
├── types/
│   └── schema.ts           # TypeScript interfaces for DB
└── assets/
```

## 4. Functional Requirements (The "Plan.md")

### 4.1 General Plan

#### Phase 1: The "SLC" (Simple, Lovable, Complete)

**1. The Chat Interface (Trunk) & Zero-Onboarding**
*   **Goal:** A clean chat window.
*   **Flow:**
    *   **Splash:** "Keeper" Logo.
    *   **Screen 1:** Show Chat Interface immediately (No Login yet).
    *   **Empty State:** Show pulsing Mic and 3 example chips: [ "Ate 4oz" ], [ "Fell Asleep" ].
    *   **Action:** User records audio -> AI parses -> Ghost Log appears.
    *   **Auth Trigger:** Only ask to "Create Account" *after* the user confirms the first log.

**2. The "Ghost Log" Protocol (Core Feature)**
*   *Critical Safety Feature:* The AI never saves data directly.
*   **Flow:**
    *   User input: "Gave 5ml Tylenol."
    *   AI processes text -> returns JSON object `{ type: "medication", amount: "5ml", drug: "Tylenol" }`.
    *   **UI:** Displays a **"Draft Card"** (Ghost Log) in the chat stream with a dashed border.
    *   **Action:** User taps "Check/Confirm" (Green Button) on the card.
    *   **Commit:** Only *then* is data saved to Supabase.

**3. The Partner Sync (Trunk)**
*   **Goal:** Shared data access.
*   **Logic:** Users create a "Family" group. Logs are queried by family_id, not just user_id.
*   **UI:** If Dad opens the app, he sees the chat stream populated with Mom's logs.
*   **Latency:** Use Optimistic UI (show bubble immediately) but "Pessimistic Data" (wait for confirm to sync).

**4. The Medical Guardrails (Safety)**
*   **Rule:** Hard-coded limits in `lib/safety.ts`.
    *   `IF medication_amount > 7.5ml (Infant Limit) THEN show_red_warning_card.`
    *   `IF age < 6 months AND drug == 'Ibuprofen' THEN show_danger_card.`
*   **AI Instruction:** "If the AI detects a medication dosage that seems high, it must flag it in the JSON response."

#### Phase 2: Refinement (Next Steps)
*   **Data Visualization:** "Show me a graph of sleep."
*   **Voice Mode:** One-tap audio recording without holding the button.

### 4.2 UI/UX Design Specifications (The "Calm" Interface)

**Design Philosophy:** "One-Handed & Half-Asleep." The user is likely holding a crying baby at 3:00 AM. The UI must be high-contrast, forgiving of fat-finger taps, and visually soothing.

#### A. Global Styling (The "Vibe")
*   **Color Palette (Tailwind):**
    *   **Background:** `bg-slate-50` (Day) / `bg-slate-950` (Night - CRITICAL).
    *   **Primary Brand:** `bg-indigo-600` (A deep, calming blue/purple).
    *   **Ghost/Draft Surface:** `bg-white` (Day) / `bg-slate-900` (Night) with `border-dashed`.
    *   **Safety Warning:** `bg-red-50` text `text-red-700` border `border-red-200`.
*   **Typography:** Large by default. Base text size should be `text-lg` (18px) not `text-md`.
*   **Haptics:** Use `expo-haptics`.
    *   *Success:* Light vibration when a log is Confirmed.
    *   *Warning:* Heavy/Double vibration if Safety Guardrail is triggered.

#### B. The Main View (Chat Interface)
**Reference:** WhatsApp / iMessage. **Structure:**
*   **Header:** Minimal. Left: "Family Chief of Staff". Right: "Partner Status" (Online/Last seen).
*   **Message List:** `flex-col-reverse` (Newest at bottom).
*   **Input Area:** Fixed at bottom.

**Component: The "Big Mic" Button**
*   **Problem:** Parents can't type while nursing/feeding.
*   **Solution:** The Microphone icon is not a small icon inside the text box. It is a **Floating Action Button (FAB)** on the bottom right, separate from the text input.
*   **Interaction:**
    *   *Tap:* Start Recording (Show visual waveform).
    *   *Tap Again:* Stop & Send.
    *   *State:* Pulse animation while recording `animate-pulse`.

#### C. Component: The "Ghost Log" Card (The "Granola" Pattern)
This is the most important UI element. It distinguishes "Chat" from "Data."

**Visual State 1: The Draft (Pending)**
*   **Appearance:** Looks like a "Ticket" or a "Sticky Note" inserted into the chat stream.
*   **Styling:**
    *   Border: `border-2 border-dashed border-indigo-300`.
    *   Background: `bg-indigo-50`.
*   **Content:**
    *   **Icon:** Large Lucide Icon (e.g., `<Milk />` or `<Pill />`).
    *   **Headline:** "Formula Feed" (Bold).
    *   **Details:** "4oz" (Large text).
    *   **Time:** "2:15 PM" (Editable).
*   **Actions (Buttons):**
    *   `[ Confirm (Checkmark) ]` -> Large, Green, full width or prominent right side.
    *   `[ Edit (Pencil) ]` -> Smaller, subtle gray.

**Visual State 2: Confirmed (Saved)**
*   **Transition:** When confirmed, the card *morphs*.
*   **Styling:**
    *   Border: `border-none` or `border-solid border-slate-200`.
    *   Background: `bg-white` (Solid) / `bg-slate-800` (Night).
    *   **Indicator:** A small "Synced" checkmark appears (indicating Supabase commit).

#### D. Component: The "Safety Guardrail" (The Brake)
**Trigger:** Triggered by `lib/safety.ts`. **Visuals:**
*   **Do not use a subtle toast.** This must block the flow.
*   **Appearance:** Red background Card `bg-red-100`.
*   **Icon:** `<AlertTriangle />` (Animated/Wiggling).
*   **Text:** "⚠️ **High Dosage Detected (15ml)**. Standard infant dose is ~3-5ml."
*   **Actions:**
    *   `[ Correct to 3.5ml ]` (Smart suggestion button).
    *   `[ I know what I'm doing ]` (Secondary, requires a long-press to override).

#### E. Partner Sync Indicators
**Logic:** Dad needs to know Mom logged this. **Visual:**
*   Next to every "Confirmed" log card, show a tiny Avatar bubble of the user who created it.
*   **Live Updates:** If Mom is typing/recording, show "Mom is logging..." at the bottom of Dad's screen.

### 4.3 Backend Design Specifications

#### Latency & Perceived Performance (The "Natural" Feel)
**Philosophy:** "Speed is a Feature." If the AI takes 5 seconds to think, the user loses trust.

**1. Optimistic Audio Upload**
*   **Action:** When user releases the Mic button, *immediately* show a gray "Processing..." bubble in the chat.
*   **Technical:** Do not wait for Supabase Storage to confirm the upload before showing the UI bubble.

**2. Streaming Responses (Optional for V1, Recommended V2)**
*   **Action:** If `gpt-4o-mini` takes > 2 seconds, stream the text response so the user sees *something* happening.
*   **V1 Fallback:** Show a high-quality, fluid "Waveform" animation while the AI is thinking. It acts as a visual "heartbeat" to reassure the user the app hasn't frozen.

**3. Offline-First Architecture (Supabase)**
*   **Scenario:** User logs a diaper in a basement with bad WiFi.
*   **Action:** The App must accept the log, queue it locally (AsyncStorage/WatermelonDB), and sync when online. **Never** show a "No Internet" error blocking the input. A parent cannot wait for WiFi to log a pill.

#### 4. Notification Architecture (The "Sleep-Saver" Logic)
**Philosophy:** "Do not wake the partner unless necessary."
**Scenario:** A user edits a log 3 times in 1 minute. We cannot send 3 notifications.
**Logic:**
*   **Idempotency & Debounce:** Database triggers for notifications must be debounced by 60 seconds.
*   **Significance Check:**
    *   *Create Log:* Notify immediately (Debounced).
    *   *Edit Log (Minor):* If only `notes` changed -> Silent update (No Push).
    *   *Edit Log (Major):* If `medication_amount` or `time` changes -> Send Push "⚠️ Log Updated: Tylenol dose changed."
*   **Self-Exclusion:** Ensure the notification logic filters out the `auth.uid()` of the actor. Do not notify me of my own logs.

#### 5. Storage Lifecycle (Ephemeral Audio)
**Philosophy:** "We keep the memory, not the noise."
**Risk:** Storing thousands of user voice recordings is a privacy liability and unnecessary cost.
**Policy:** Audio files are **temporary artifacts** used solely for transcription.
**Implementation:**
*   Create a Supabase Storage Bucket `raw_audio` with RLS (Private to Family).
*   **Auto-Cleanup:** Write a Scheduled Edge Function (Cron) that runs every 24 hours:
    *   `DELETE * FROM storage.objects WHERE bucket_id = 'raw_audio' AND created_at < NOW() - INTERVAL '48 hours'`
*   **User Promise:** Explicitly state in Privacy Policy: "Voice recordings are deleted after 48 hours. We only keep the text."

#### 6. Conflict Resolution (The "Last-Touch" Rule)
**Scenario:** Both parents edit the same log while one is offline.
**Logic:** Use **Last-Write-Wins (LWW)** based on the client-generated timestamp, not the server arrival time.
*   Table `logs` must have a `last_modified_by` (UUID) and `client_updated_at` (ISO Timestamp) column.
*   When syncing an offline queue, if `incoming.client_updated_at < current.client_updated_at`, **discard** the update.
*   *Medical Exception:* If a Medical Log has a conflict, **duplicate** it rather than overwrite it. It is safer to show two conflicting Tylenol doses than to accidentally hide one.

#### 7. AI Resilience & Failure Handling
**Scenario:** OpenAI API is down or times out (500 Error).
**Action:** The app must degrade gracefully, not crash.
**Logic:**
*   **The "Pending" State:** If the Edge Function fails, the UI keeps the "Ghost Log" but marks it as "Transcription Failed."
*   **Manual Override:** The user can tap the failed card to manually type the details.
*   **Background Retry:** The audio ID is added to a `retry_queue` in Supabase. A background job attempts to re-parse it every 5 minutes for up to 30 minutes.

#### 8. Testing Protocols & Mock Data Strategy (Instructions for AI)
**Philosophy:** "If it isn't tested, it's broken." The backend logic defined above is invisible to the user but critical for trust. You (the AI Developer) must write specific test cases using `jest` or Supabase local testing.

**A. Testing Notification Debounce (The "Spam Check")**
*   **Goal:** Prove that 3 rapid edits result in only 1 Notification.
*   **Mock Setup:**
    *   Create a mock `logs` entry.
    *   Create a mock `notifications` table listener.
*   **Test Case 1 (Rapid Fire):**
    *   Update `log_id_123` at `T=0s`.
    *   Update `log_id_123` at `T=10s`.
    *   Update `log_id_123` at `T=45s`.
    *   **Expectation:** `notifications` table count == 1.
*   **Test Case 2 (Significant Edit):**
    *   Update `notes` field (Minor). -> **Expectation:** 0 Notifications.
    *   Update `medication_amount` (Major). -> **Expectation:** 1 Notification (Warning Type).

**B. Testing Conflict Resolution (The "Time Travel" Check)**
*   **Goal:** Ensure the *newest* data wins, regardless of when it hits the server.
*   **Mock Data:**
    ```javascript
    const serverLog = { id: 'log_A', client_updated_at: '10:00 AM', amount: '4oz' };
    const staleUpdate = { id: 'log_A', client_updated_at: '09:55 AM', amount: '2oz' }; // Old offline data
    const freshUpdate = { id: 'log_A', client_updated_at: '10:05 AM', amount: '6oz' }; // New data
    ```
*   **Test Case 3 (Stale Overwrite Prevention):**
    *   Attempt to merge `staleUpdate` into `serverLog`.
    *   **Expectation:** `serverLog.amount` remains '4oz'. (Update rejected).
*   **Test Case 4 (Medical Safety Exception):**
    *   Scenario: `serverLog` is type `medication`.
    *   Attempt merge with `freshUpdate` (Conflict).
    *   **Expectation:** Do NOT overwrite. Create NEW log entry `log_B` with '6oz'. Result: 2 Logs exist.

**C. Testing AI Failure (The "Dumb Mode" Check)**
*   **Goal:** Ensure UI functions when the "Brain" is dead.
*   **Mock Setup:** Intercept the OpenAI API call and force return `500 Server Error`.
*   **Test Case 5 (Graceful Degradation):**
    *   Trigger `parseLog(audioFile)`.
    *   **Expectation:**
        *   Function does NOT throw fatal error.
        *   Returns JSON: `{ status: 'failed', retry_queued: true }`.
        *   Check `retry_queue` table: Count == 1.

**D. Testing Storage Cleanup (The "Janitor" Check)**
*   **Goal:** Verify the SQL logic for deleting old files.
*   **Test Case 6 (SQL Logic):**
    *   Insert Mock File A: `created_at = NOW() - 50 hours`.
    *   Insert Mock File B: `created_at = NOW() - 10 hours`.
    *   Run the Cleanup SQL Query.
    *   **Expectation:** File A is DELETED. File B REMAINS.

## 5. Constraints & Standards (Vibe Coding Protocol)

### Architecture Risk Assessment
*   **TRUNK (Zero Tech Debt):** Database Schema, Auth Flow, Privacy (RLS).
    *   *Rule:* Never bypass RLS. Every database query must be scoped to family_id.
*   **LEAF (Fast Coding):** The UI styling of the chat bubbles, animations.

### Implementation Order (The Test-Loop)
1.  **Schema First:** Define the logs table in Supabase SQL editor.
2.  **Type It:** Update types/schema.ts to match.
3.  **API:** Write the OpenAI function to parse text to JSON.
4.  **UI:** Build the Chat Interface to display that JSON.

### Security Rules
*   **No Medical Advice:** The System Prompt must explicitly state: *"You are a data logger. You are NOT a doctor. Do not give medical advice."*
*   **Environment:** Store EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY in .env.

### 5.1 Code Standards & Workflow Protocol

#### A. Design Patterns (The "Mental Model")
*   **The "Optimistic UI" Pattern (Modified):**
    *   *Standard:* Update UI immediately, then sync.
    *   *Our Exception:* For **Medical Logs**, we use **"Pessimistic UI"**. We *never* assume the data is correct until the user confirms the Ghost Log.
    *   *Chat Bubble:* Show "Sending..." state only for the audio upload.
*   **The "Service Layer" Pattern (Backend):**
    *   *Rule:* Never write business logic inside a UI component or a Route handler.
    *   *Implementation:* Logic goes into `lib/services/`.
    *   *Bad:* Calculating Tylenol dosage inside `ChatScreen.tsx`.
    *   *Good:* `ChatScreen.tsx` calls `SafetyService.checkDosage()`.

#### B. Testing Strategy (The "Safety Net")
We cannot test everything, but we **MUST** test safety.
*   **Mandatory Unit Tests (`npm test`):**
    *   Target: `lib/safety.ts`.
    *   *Requirement:* You must write a test file `lib/safety.test.ts` that runs through 20+ scenarios (e.g., "50ml Tylenol", "Motrin at 2 months") and asserts that the correct Warning/Error flags are returned.
    *   *CI Rule:* You cannot deploy if `safety.test.ts` fails.

#### C. Version Control (Git Workflow)
*   **Role Definition:**
    *   **AI (The Coder):** Writes code, creates files, fixes bugs.
    *   **Human (The Gatekeeper):** Runs Git commands.
*   **The Loop:**
    *   **Prompt:** "Build the Ghost Log Card component."
    *   **AI Action:** Creates `GhostLogCard.tsx`.
    *   **Human Verification:** Check the UI. Does it look right?
    *   **Human Action:**
        *   `git add .`
        *   `git commit -m "feat: added ghost log card"`
        *   `git push`

## 6. Implementation Guidelines for AI

### A. The System Prompt (Copy this to lib/openai.ts)
"You are Keeper, the Family Chief of Staff. Your job is to extract structured parenting data from natural language.
Tone: Calm, Brief, Alert, Warm. (e.g., 'Logged.' not 'Great job mama!')
Current Date: [Insert Date] (the backend design should be able to give the AI the exact time stamp.

INPUT: 'He drank 4oz of milk.'
OUTPUT: JSON { 'event': 'feed', 'subtype': 'formula', 'amount': 4, 'unit': 'oz', 'time': 'current_time' }

INPUT: 'Gave him Tylenol.'
OUTPUT: JSON { 'event': 'medication', 'drug': 'Tylenol', 'amount': null, 'warning': 'missing_dosage' }

If the user asks a question ('Is this normal?'), reply with plain text based on standard AAP guidelines, but keep it brief."

### B. Database Schema (Supabase)
*   **Table:** profiles (id, email, family_id, role)
*   **Table:** families (id, created_at, invite_code)
*   **Table:** logs
    *   id (uuid)
    *   family_id (uuid, fk) - *CRITICAL: All queries filter by this.*
    *   creator_id (uuid, fk)
    *   event_type (text: 'sleep', 'feed', 'diaper', 'medication')
    *   raw_text (text) - *The original user input*
    *   structured_data (jsonb) - *The AI parsed data*
    *   is_confirmed (boolean) - *The Ghost Log check*

### C. Developer Experience
*   **Mocking:** If OpenAI API fails or credits run out, fallback to a local mock parser that always returns a "Diaper Change" log so UI work can continue.

## 7. Interaction Protocol (For the AI IDE)
**Trigger:** When I ask you to "Build the Log Feature."
**Action:**
1.  Check types/schema.ts to see what a "Log" looks like.
2.  Create the Supabase migration file.
3.  Create the UI Component (GhostLogCard.tsx).
4.  Connect them using the OpenAI function.

**You are the Senior Engineer.** If I ask for something that breaks the "Safety First" rule (like auto-saving medical data without confirmation), **refuse** and reference this document.
