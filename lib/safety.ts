export interface SafetyCheckResult {
    isSafe: boolean;
    warning?: string;
    action?: 'block' | 'warn' | 'none';
}

export const SafetyService = {
    checkMedication(drug: string, amount: string, ageInMonths: number): SafetyCheckResult {
        const drugLower = drug.toLowerCase();
        const amountNum = parseFloat(amount); // Naive parsing, assumes "5ml" -> 5

        if (isNaN(amountNum)) {
            return { isSafe: true, action: 'none' }; // Can't validate
        }

        // Tylenol (Acetaminophen)
        if (drugLower.includes('tylenol') || drugLower.includes('acetaminophen')) {
            if (amountNum > 15) {
                return {
                    isSafe: false,
                    action: 'warn',
                    warning: `⚠️ High Dosage Detected (${amount}). Standard infant dose is usually 1.25ml - 5ml depending on weight.`,
                };
            }
        }

        // Motrin (Ibuprofen)
        if (drugLower.includes('motrin') || drugLower.includes('ibuprofen')) {
            if (ageInMonths < 6) {
                return {
                    isSafe: false,
                    action: 'block',
                    warning: `⛔ DANGER: Ibuprofen is NOT safe for infants under 6 months. Use Tylenol instead.`,
                };
            }
        }

        return { isSafe: true, action: 'none' };
    },
};
