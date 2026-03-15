/**
 * Generate a prefixed unique ID.
 * Not cryptographically secure - fine for demo purposes.
 */
export function generateId(prefix: string): string {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 8);
  return `${prefix}_${timestamp}${random}`;
}

/**
 * Basic email validation.
 */
export function validateEmail(email: string): boolean {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
}

/**
 * Format a Date into a readable ISO-like string.
 */
export function formatTimestamp(date: Date): string {
  return date.toISOString();
}

/**
 * Clamp a number between min and max.
 */
export function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

/**
 * Parse pagination query params with sensible defaults.
 */
export function parsePagination(query: {
  page?: string;
  limit?: string;
}): { page: number; limit: number; offset: number } {
  const page = Math.max(1, parseInt(query.page || "1", 10) || 1);
  const limit = clamp(parseInt(query.limit || "20", 10) || 20, 1, 100);
  const offset = (page - 1) * limit;
  return { page, limit, offset };
}

/**
 * Simple slugify for strings.
 */
export function slugify(text: string): string {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, "")
    .replace(/[\s_]+/g, "-")
    .replace(/^-+|-+$/g, "");
}
