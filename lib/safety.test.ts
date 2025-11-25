import { SafetyService } from './safety';

describe('SafetyService', () => {
    describe('checkMedication', () => {
        it('should allow safe Tylenol dosage', () => {
            const result = SafetyService.checkMedication('Tylenol', '5', 6);
            expect(result.isSafe).toBe(true);
        });

        it('should warn on high Tylenol dosage', () => {
            const result = SafetyService.checkMedication('Tylenol', '50', 6);
            expect(result.isSafe).toBe(false);
            expect(result.action).toBe('warn');
            expect(result.warning).toContain('High Dosage');
        });

        it('should block Ibuprofen for infants under 6 months', () => {
            const result = SafetyService.checkMedication('Ibuprofen', '2.5', 3);
            expect(result.isSafe).toBe(false);
            expect(result.action).toBe('block');
            expect(result.warning).toContain('DANGER');
        });

        it('should allow Ibuprofen for infants over 6 months', () => {
            const result = SafetyService.checkMedication('Ibuprofen', '5', 7);
            expect(result.isSafe).toBe(true);
        });

        it('should handle unknown drugs gracefully', () => {
            const result = SafetyService.checkMedication('UnknownDrug', '10', 6);
            expect(result.isSafe).toBe(true);
        });
    });
});
