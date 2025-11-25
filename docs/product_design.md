# Product Design (Final Version): Keeper – AI Baby and Family Management Tool

## Part 1: Strategic Overview (The 5 W's)

### 1. The Core Concept (WHAT)
We are building a **communication tool**, not a "tracker."
*   **The Shift:** Current apps (Huckleberry, BabyTracker) are *databases* that require work to fill. We are building a *Voice Assistant* that does the work for you.
*   **The Metaphor:** It is not a logbook; it is a "Chief of Staff" for the home. It listens to chaos, organizes it into facts, and briefs the parents.

### 2. The Target Audience (WHO)
**Primary:** First-time mothers in the "Survival Phase" (3rd Trimester to 12 months postpartum).
*   **Psychographics:** They are sleep-deprived, anxious about doing things "wrong," and feel a heavy "Mental Load" (the burden of remembering).
*   **Secondary:** The "Out of the Loop" Partner. Usually the father who wants to help but doesn't know the schedule and asks annoying questions ("When does he eat next?").

### 3. The Platform (WHERE)
**Mobile Application (iOS/Android).**
*   **Interface:** A simple Chat Interface (like WhatsApp/iMessage).
*   **Why:** Tired parents do not want to navigate menus or tabs. They want to dump information quickly via voice or text.

### 4. The Value Proposition (WHY)
"Cognitive Offloading."
The value isn't the data itself (knowing the baby pooped). The value is the release of responsibility. Once the parent speaks it to the AI, they can safely forget it, knowing the "Chief of Staff" has remembered it for them.

### 5. The User Journey (HOW)
*   **Input:** Mom holds the baby and speaks: "She just finished 4oz of formula and has a rash on her chin."
*   **Process:** The AI parses this natural language into structured data.
*   **Verification:** The AI shows a visual confirmation card (Crucial for safety).
*   **Sync:** Dad opens the app later. He sees the log and can ask: "How much has she eaten today?" The AI answers based on Mom's logs.

## Part 2: Feature Specifications & Risk Mitigation

### Feature A: The "Invisible" Logger
The Risk: You asked, "What if the AI understands things wrong? What if that causes a severe issue?"
The Reality: LLMs (Large Language Models) can "hallucinate." In a medical context (medication dosages), this is unacceptable.
The Mitigation Strategy: "Trust but Verify"
We never allow the AI to silently write to the database. We use a Ghost Log + Logic Guardrails system.

**1. The "Ghost Log" UI Pattern**
When a user speaks, the AI does *not* instantly save the data as fact.
*   **Step 1 (Drafting):** The AI presents a "Draft Card" in the chat.
    *   *User says:* "Give him 5ml of Tylenol."
    *   *AI shows:* `[Drug: Tylenol] [Dose: 5ml] [Time: 2:00 PM]`
*   **Step 2 (Visual Check):** The user must tap "Check/Confirm" or let it auto-save after 60 seconds. If the AI heard "50ml" (lethal dose), the user sees the wrong number immediately in the card and taps "Edit."

**2. Hard-Coded "Anomaly Watchdogs"**
We do not rely on AI for safety checks. We use standard, deterministic code (If/Then logic) for medical boundaries.
*   **Rule:** `IF input_type == 'medication' AND dosage > safe_limit THEN trigger_alert`
*   **Scenario:** Parent says "50ml Tylenol." AI extracts "50ml." The *code* catches that 50ml is impossible for an infant.
*   **Response:** The app turns red and replies: "⚠️ **Safety Warning:** 50ml is a very high dose. Did you mean 5ml? Please confirm."

**3. The "Raw Audio" Audit Trail**
*   **Feature:** Every log keeps the original voice recording attached to it.
*   **Value:** If a parent is confused later ("Did I really give him that much?"), they can tap the log to replay their own voice. This removes the fear that the "AI lied."

### Feature B: The "Partner Sync"
*   **Function:** A shared state between two accounts.
*   **Implementation:** When Mom logs an event, it pushes a silent notification to Dad's device. Dad can query the AI: "When is nap time?" The AI reads the database of Mom's logs to answer.

### Feature C: The "Conflicting Advice" Filter
*   **Function:** Onboarding asks: "What is your parenting style? (e.g., Scientific, Gentle, Attachment)."
*   **Implementation:** When the user asks "Why is he crying?", the System Prompt injects their profile.
    *   *Prompt to AI:* "The user follows 'Scientific Parenting' (AAP Guidelines). Do not suggest homeopathic remedies. Focus on sleep pressure and hunger cues."

## Part 3: Technical Implementation (The "Cheapest" Path)

To minimize "Burn Rate," we avoid complex cloud architecture. We use the *"F It" Stack*: simple, proven, and scalable.

### The Tech Stack
*   **Frontend:** **React Native (Expo)**.
    *   *Why:* One codebase for both iPhone and Android. Very fast to build.
*   **Backend & Database:** **Supabase**.
    *   *Why:* Open-source alternative to Firebase. Uses PostgreSQL (Structured Query Language), which is safer for medical/timeline data than NoSQL.
    *   *Cost:* Excellent Free Tier.
*   **AI Engine:** **OpenAI GPT-4o-mini**.
    *   *Why:* It is the current price-performance leader. It is smart enough for data extraction but 30x cheaper than GPT-4.

## Part 4: Cost Analysis & Business Model

### 1. Token Cost (The Math)
AI costs are measured in "Tokens" (approx. 0.75 words).
*   **GPT-4o-mini Price:**
    *   Input: $0.15 per 1,000,000 tokens.
    *   Output: $0.60 per 1,000,000 tokens.

**Scenario: A "Heavy User" (Newborn Phase)**
*   **Daily Usage:**
    *   20 Logs (Diapers, Feed, Sleep).
    *   5 Questions ("Is this normal?").
    *   5 Partner Queries.
    *   *Total:* 30 interactions/day.
*   **Tokens per Interaction:**
    *   Input (System instructions + User text): ~520 tokens.
    *   Output (AI reply): ~20 tokens.
*   **Monthly Volume:**
    *   900 interactions x 520 input = 468,000 tokens.
    *   900 interactions x 20 output = 18,000 tokens.
*   **Monthly AI Cost Per User:**
    *   Input: $0.07
    *   Output: $0.01
    *   **Total: $0.08 per user / month.**

### 2. Total Startup Operating Costs (Estimated)
Assuming 1,000 active users.

| Expense Item | Service / Provider | Monthly Cost | Notes |
| :--- | :--- | :--- | :--- |
| **Database** | Supabase (Pro Plan) | $25.00 | Free tier works until ~5k users. |
| **AI Fees** | OpenAI API | $80.00 | 1,000 users x $0.08. |
| **App Hosting** | Vercel / Expo EAS | $15.00 | For web landing page & build tools. |
| **Apple Developer** | Apple App Store | $8.25 | ($99/year amortized). |
| **Google Developer** | Google Play Store | $0.00 | ($25 one-time fee). |
| **Error Logging** | Sentry | $0.00 | Free tier is sufficient. |
| **TOTAL BURN** | | **~$128.25** | **Break-even at ~15 subscribers.** |

### 3. Business Model
**Primary:** **"Sanity" Subscription (SaaS)**
*   **Price:** $9.99 / month or $99 / year.
*   **Margin:** At $9.99 price and $0.08 cost, your gross margin is >99%.
*   **Trial Strategy:** 14-Day Free Trial. This gets them through one "crisis" (e.g., a sleep regression), proving the value.

## Part 5: Execution Roadmap

**Step 1: The "Wizard of Oz" Test (Cost: $0)**
*   Do not write code yet.
*   Create a WhatsApp group with 3 pregnant friends.
*   Tell them to text you their logs.
*   **You** act as the AI. You manually reply "Logged."
*   *Goal:* Test the "Safety Protocol." Make a mistake on purpose (record 50ml instead of 5ml). See if they catch it. If they don't, you know the UI needs to be bolder.

**Step 2: The "Wrapper" MVP (Weeks 1-4)**
*   Build the React Native shell.
*   Connect to OpenAI API.
*   Implement the "Draft Card" UI (Safety feature).
*   Launch to the first 50 users (Manual recruitment).

**Step 3: Validation & Scale (Month 2+)**
*   Measure **Cohort Retention**. If users stop logging after 3 weeks, the chat interface is too slow.
*   Iterate: Add "One-tap quick buttons" for common items (Breastfeed Left/Right) to speed up data entry.
