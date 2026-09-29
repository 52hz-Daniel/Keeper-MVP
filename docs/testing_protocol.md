# Automated AI Testing Protocol (Antigravity + Maestro)

**System:** Keeper Ecosystem
**Version:** 2.0 (Vision-Enabled)
**Tooling:** Antigravity IDE (Gemini 3) + Maestro (iOS Simulator)

## 1. The Core Philosophy
We separate "Action" from "Perception."
*   **The Muscle (Maestro):** Executes clicks and navigation. Reliable, fast, deterministic.
*   **The Eyes (Antigravity):** Analyzes why something failed using Computer Vision.

## 2. Environment Setup
The user must ensure:
*   iOS Simulator is open.
*   Expo Development Build is installed (`npx expo run:ios`).
*   Maestro is installed (`curl -Ls "https://get.maestro.mobile.dev" | bash`).

## 3. The "Vision Loop" (Agent Instructions)

### Step A: Write & Run (The Muscle)
When you implement a feature, create a `.yaml` test in `.maestro/` and run it:
```bash
maestro test .maestro/feature_name.yaml
```

### Step B: The Fork (Pass vs. Fail)
*   **IF PASS:** ✅ Done.
*   **IF FAIL:** 🛑 Do not guess. Proceed to Step C.

### Step C: Vision Debugging (The Eyes)
If Maestro fails, it usually means the UI didn't match the expectation.
1.  **Capture:** Run the Maestro debug command to get a screenshot:
    *   `maestro hierarchy` (dumps the UI tree)
    *   OR Update the YAML to take a screenshot at the point of failure:
        ```yaml
        - takeScreenshot: failure_debug
        ```
2.  **Analyze (Antigravity Capability):**
    *   Look at `failure_debug.png`.
    *   **Self-Prompt:** "I am looking at the simulator screenshot. Why is the 'Save' button not visible? Is it covered by the keyboard? Is the color contrast too low? Is the loading spinner still there?"
3.  **Fix:** Based on visual evidence, apply the fix (e.g., `KeyboardAvoidingView` or `extendedWait`).

## 4. Best Practices for Antigravity Agents

### 1. Visual Verification of "Themes"
Since we are building a 3-Stage app (Dawn/Midnight/Daylight themes), text assertions are not enough.
*   **Test:** "Verify the background is dark in Infant Mode."
*   **Action:** Take a screenshot.
*   **Vision Check:** "Is the background color hex code close to `#0F172A` (Midnight Slate)?"

### 2. The "Ghost Log" Visual Check
The "Ghost Log" card is dashed. This is a visual style trait.
*   Maestro cannot easily check "dashed border".
*   Antigravity CAN.
*   **Command:** "Verify ghost_card has a dashed border style." (Agent checks code style + visual screenshot).

## 5. Troubleshooting Guide
*   **Error:** "Maestro cannot find element X."
    *   **Solution:** The Agent should immediately check `app/_layout.tsx` to see if the component is actually rendered in the current "Stage" (Pre-Natal vs Infant).
*   **Error:** "Antigravity cannot see the simulator."
    *   **Solution:** Ensure the Simulator window is not minimized. Antigravity's "Computer Use" needs the window to be painted on the OS desktop.

## 6. Example: The "Vision" Test Flow

**File:** `.maestro/visual_theme_check.yaml`
```yaml
appId: com.keeper.app
---
- launchApp
# Navigate to Infant Mode
- tapOn: "Baby"
# Verify UI Elements exist (The Muscle)
- assertVisible: "mic_button"
# Capture Visual State (The Eyes)
- takeScreenshot: theme_verification
```

**Agent Action:**
"I have run the test. I am now analyzing `theme_verification.png`. I confirm the background is Dark Slate and the buttons are Indigo, matching the 'Midnight' theme requirements."
