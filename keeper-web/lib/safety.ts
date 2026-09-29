export const SafetyService = {
    checkMedication(data: any) {
        if (!data) return null;

        // Mock Safety Checks (Hardcoded for MVP)
        const DANGEROUS_MEDS = ['aspirin', 'ibuprofen']; // Ibuprofen < 6mo is generally restricted

        if (DANGEROUS_MEDS.includes(data.medication_name?.toLowerCase())) {
            return "Consult pediatrician before giving this medication.";
        }

        if (data.dosage && parseInt(data.dosage) > 10) {
            return "Dosage seems high. Please double check.";
        }

        return null;
    }
};
