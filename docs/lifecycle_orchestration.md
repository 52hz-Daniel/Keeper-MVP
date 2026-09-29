# Master Lifecycle Orchestration Document

**Project:** Keeper Ecosystem Expansion
**Status:** Active Directive
**Reference:** Based on "Keeper Expansion" & "MPID Refined"

## 1. The Core Philosophy: "Happiness First"
**Primary Directive for AI:**
Our goal is to reduce the "Mental Load" of parents so they can focus on the joy of parenting.
*   **Do not** build features that make the parent a "Data Entry Clerk."
*   **Do not** interrupt moments of connection with complex forms.
*   **Do** prioritize Voice-First interactions. The parent should be looking at the baby, not the phone.
*   **Do** use AI to infer context. If the user says "He's fussy," the AI should look at the last feed time and suggest "Maybe he's hungry?" rather than just logging "Fussiness."

## 2. The "3-Stage" Architecture
We are moving from a single-app utility to a Lifecycle Operating System. The app effectively morphs into three different tools based on the child's age.

### The Stages (Mutually Exclusive Views)

| Stage | Context | Theme Code | AI Persona | Primary Anxiety |
| :--- | :--- | :--- | :--- | :--- |
| **1. Pre-Natal** | Pregnancy to Birth | `THEME_DAWN` (Sage/Cream) | "The Project Manager" | "Am I prepared? Is this symptom normal?" |
| **2. Infant** | 0 to 12 Months | `THEME_MIDNIGHT` (Indigo/Dark) | "The Night Nurse" | "Is he alive? Is he fed? Did he sleep?" |
| **3. Early Ed** | 12 Months to 5 Years | `THEME_DAYLIGHT` (Primary Colors) | "The Pattern Keeper" | "Why is he acting this way? Is he developing?" |

**Technical Rule:**
The User Interface MUST only load the components relevant to the Current Stage. Do not pollute the Infant interface with Toddler vocabulary features.
*   **Exception:** A "Time Travel" button in Settings allows manual switching, but the default view is strictly locked to the calculated stage.

## 3. The "Zero-Onboarding" Flow (UX Logic)
**Objective:** Eliminate the "Sign Up Wall." Value must precede commitment.

### Step 1: The "One Question" Entry
On first launch, do NOT ask for Email/Password. Ask only for the anchor date.
*   **UI:** A beautiful, minimal screen with one question.
*   **Copy:** "To help you best, we need to know where you are in your journey."
*   **Input:** Date Picker.
*   **Label:** "Due Date" OR "Birthday".
*   **Logic:**
    *   IF Date > Today -> Activate Pre-Natal Mode.
    *   IF Date < Today AND (Today - Date) < 1 Year -> Activate Infant Mode.
    *   IF Date < Today AND (Today - Date) > 1 Year -> Activate Early Ed Mode.

### Step 2: Immediate Immersion (Guest Mode)
*   Directly load the Chat Interface for that stage.
*   Create an anonymous session (using Supabase Anonymous Auth or local storage).
*   **Prompt:**
    *   **Pre-Natal:** "I'm ready. Tell me a symptom you're feeling, or let's start a registry list."
    *   **Infant:** "I'm listening. Tell me when the baby last ate or slept."
    *   **Toddler:** "I'm here. Noticed any new words or behaviors today?"

### Step 3: The "Value Threshold" (Conversion)
We do not ask for signup until the user has experienced the "Magic Moment."
*   **Trigger:** The user successfully confirms their 5th "Ghost Log."
*   **Interruption:** A gentle modal appears.
*   **Copy:** "Keeper has saved you [X] minutes of mental load. Secure your family's data permanently."
*   **Action:** Apple/Google Sign In.
*   **Commercial Logic:** Start Free Trial immediately upon Signup. Auto-convert to Subscription after 14 days if not cancelled.

## 4. Technical Implementation Strategy

### 4.1 Database Schema Evolution (Polymorphic Logs)
The logs table must evolve to handle different data structures without becoming messy.

**Directive for AI:**
Modify the logs table in Supabase.
*   Add `stage_context` (Enum: 'prenatal', 'infant', 'toddler').
*   Keep `structured_data` as a flexible JSONB column.
*   Do not create separate tables for each stage (e.g., `prenatal_logs`). Use the JSONB column to store stage-specific schemas.
    *   **Pre-Natal JSON Example:** `{ "type": "symptom", "pain_level": 4, "location": "lower_back" }`
    *   **Infant JSON Example:** `{ "type": "feed", "amount": 4, "unit": "oz" }`
    *   **Toddler JSON Example:** `{ "type": "milestone", "category": "speech", "word": "apple" }`

### 4.2 Dynamic System Prompts
The `lib/openai.ts` file must inject the correct "System Persona" based on the user's stage.

**Logic:**
```typescript
const getSystemPrompt = (stage: string, childAge: number) => {
  if (stage === 'prenatal') return PRENATAL_PERSONA; // Vigilant, Medical, List-focused
  if (stage === 'infant') return INFANT_PERSONA;     // Brief, "Night Nurse", Survival-focused
  return TODDLER_PERSONA;                            // Analytical, Connecting dots, Educational
}
```

### 4.3 The "Ghost Log" Component Factory
The UI component that displays the draft log (`GhostLogCard.tsx`) must be smart enough to render different "Cards" based on the data type.

**AI Task:**
Implement a switch case in the `GhostLogCard` component:
*   If `stage == prenatal`: Render `SymptomCard` (Focus on severity & doctor notes).
*   If `stage == infant`: Render `SurvivalCard` (Focus on time & quantity).
*   If `stage == toddler`: Render `InsightCard` (Focus on behavior triggers & photos).

## 5. Safety & Guardrails (The "Do No Harm" Rule)
Even though we are expanding, safety remains the #1 priority.
*   **Pre-Natal Guardrail:** If keywords suggest Preeclampsia (headache, blurred vision) or Labor (contractions < 5 min apart), the AI must immediately trigger a Red Card advising medical contact.
*   **Infant Guardrail:** (Existing) Medication dosage checks.
*   **Toddler Guardrail:** If behavior logs suggest physical harm or developmental regression, suggest "Pediatrician Consult" rather than offering advice.

## 6. Execution Roadmap for AI
You (The AI Developer) have autonomy to choose the best specific libraries (e.g., `date-fns` vs `dayjs`) to achieve these goals.

### Phase 1: The "Brain" Upgrade
*   Update Supabase Schema (`stage_context`).
*   Create the `useStage` hook to determine current stage based on DOB.
*   Refactor `openai.ts` to accept dynamic system prompts.

### Phase 2: The Onboarding Flow
*   Build the `WelcomeScreen` (Date Picker).
*   Implement Anonymous Auth logic.
*   Build the "Value Threshold" trigger.

### Phase 3: The Interface Skins
*   Implement Tailwind themes for Dawn/Midnight/Daylight.
*   Ensure the "Chat" feels different in each stage (e.g., Softer fonts for Pre-Natal, High Contrast for Infant).

**Final Note to AI:**
When building, ask yourself: Does this require the parent to think too much? If yes, simplify it. The AI should do the heavy lifting.
