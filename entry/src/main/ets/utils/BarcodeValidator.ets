export class BarcodeValidator {
  static isValidBarcodeFormat(code: string): boolean {
    if (!code || code.length === 0) return false;

    if (/^[0-9]{8}$/.test(code)) return true;
    if (/^[0-9]{13}$/.test(code)) return true;
    if (/^[0-9]{12}$/.test(code) && BarcodeValidator.validateUpcAChecksum(code)) return true;

    if (code.startsWith('http://') || code.startsWith('https://')) {
      if (code.includes('openfoodfacts.org') || code.includes('foodscan.familyfood.app')) {
        return true;
      }
    }

    return false;
  }

  static extractBarcodeFromUrl(url: string): string | null {
    const match = url.match(/\/product\/(\d+)/);
    return match ? match[1] : null;
  }

  private static validateUpcAChecksum(code: string): boolean {
    let sum = 0;
    for (let i = 0; i < 11; i++) {
      sum += parseInt(code[i]) * (i % 2 === 0 ? 3 : 1);
    }
    const checksum = (10 - (sum % 10)) % 10;
    return checksum === parseInt(code[11]);
  }
}
