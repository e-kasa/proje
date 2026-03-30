/**
 * @fileoverview Validation utilities for document management.
 *
 * This module provides a comprehensive set of validation functions for
 * ensuring data integrity and security when working with documents.
 * All validators follow a consistent pattern, returning detailed
 * validation results that can be used for error reporting.
 *
 * @module utils/validation
 * @version 1.0.0
 *
 * @example
 * ```typescript
 * import {
 *   validateDocumentId,
 *   validateTags,
 *   validateCategoryPath,
 *   ValidationResult
 * } from './utils/validation';
 *
 * // Validate a document ID
 * const idResult = validateDocumentId(userInput);
 * if (!idResult.isValid) {
 *   throw new Error(idResult.errors.join(', '));
 * }
 *
 * // Validate tags before saving
 * const tagsResult = validateTags(userTags);
 * if (!tagsResult.isValid) {
 *   console.warn('Invalid tags:', tagsResult.errors);
 * }
 * ```
 */

import { DocumentType, DocumentStatus, AccessLevel } from '../types';

/**
 * Result of a validation operation.
 *
 * Provides detailed information about validation success or failure,
 * including all errors and optional warnings for non-critical issues.
 *
 * @example
 * ```typescript
 * const result: ValidationResult = {
 *   isValid: false,
 *   errors: ['Tag contains invalid characters'],
 *   warnings: ['Tag is very long and may affect search performance']
 * };
 * ```
 */
export interface ValidationResult {
  /** Whether the validation passed */
  isValid: boolean;

  /** Array of error messages (empty if valid) */
  errors: string[];

  /** Array of warning messages (non-blocking issues) */
  warnings: string[];
}

/**
 * Configuration options for validators.
 *
 * Allows customizing validation behavior for different use cases.
 */
export interface ValidationOptions {
  /** Treat warnings as errors */
  strict?: boolean;

  /** Allow empty values */
  allowEmpty?: boolean;

  /** Maximum string length to allow */
  maxLength?: number;
}

/**
 * Creates a successful validation result.
 *
 * Utility function for creating consistent success responses.
 *
 * @returns A valid ValidationResult with no errors
 *
 * @example
 * ```typescript
 * function myValidator(value: string): ValidationResult {
 *   if (isValidValue(value)) {
 *     return validResult();
 *   }
 *   return invalidResult(['Value is invalid']);
 * }
 * ```
 */
export function validResult(): ValidationResult {
  return { isValid: true, errors: [], warnings: [] };
}

/**
 * Creates a failed validation result.
 *
 * Utility function for creating consistent error responses.
 *
 * @param errors - Array of error messages
 * @param warnings - Optional array of warning messages
 * @returns An invalid ValidationResult with the specified errors
 *
 * @example
 * ```typescript
 * return invalidResult(
 *   ['Required field is missing'],
 *   ['Consider adding more detail']
 * );
 * ```
 */
export function invalidResult(
  errors: string[],
  warnings: string[] = []
): ValidationResult {
  return { isValid: false, errors, warnings };
}

/**
 * Validates a document ID format.
 *
 * Document IDs must be valid UUID v4 strings. This validator checks:
 *
 * - Non-empty string
 * - Correct UUID v4 format (8-4-4-4-12 hex pattern)
 * - Lowercase letters (warning if uppercase)
 *
 * @param id - The document ID to validate
 * @returns Validation result indicating if the ID is valid
 *
 * @example
 * ```typescript
 * // Valid UUID
 * validateDocumentId('550e8400-e29b-41d4-a716-446655440000');
 * // => { isValid: true, errors: [], warnings: [] }
 *
 * // Invalid format
 * validateDocumentId('not-a-uuid');
 * // => { isValid: false, errors: ['Invalid UUID format'], warnings: [] }
 *
 * // Empty ID
 * validateDocumentId('');
 * // => { isValid: false, errors: ['Document ID is required'], warnings: [] }
 * ```
 */
export function validateDocumentId(id: string): ValidationResult {
  if (!id || id.trim().length === 0) {
    return invalidResult(['Document ID is required']);
  }

  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

  if (!uuidRegex.test(id)) {
    return invalidResult(['Invalid UUID format']);
  }

  const warnings: string[] = [];
  if (id !== id.toLowerCase()) {
    warnings.push('UUID should be lowercase');
  }

  return { isValid: true, errors: [], warnings };
}

/**
 * Validates an array of tags.
 *
 * Tags are used for categorization and search. This validator ensures:
 *
 * - Each tag is a non-empty string
 * - Tags contain only alphanumeric characters, hyphens, and underscores
 * - Tags don't exceed 50 characters
 * - No duplicate tags exist
 * - Array doesn't exceed 20 tags (warning if over 10)
 *
 * @param tags - Array of tags to validate
 * @param options - Validation options
 * @returns Validation result for all tags
 *
 * @example Valid Tags
 * ```typescript
 * validateTags(['javascript', 'web-dev', 'tutorial_2024']);
 * // => { isValid: true, errors: [], warnings: [] }
 * ```
 *
 * @example Invalid Tags
 * ```typescript
 * validateTags(['valid', 'has spaces', 'also@invalid']);
 * // => {
 * //   isValid: false,
 * //   errors: [
 * //     'Tag "has spaces" contains invalid characters',
 * //     'Tag "also@invalid" contains invalid characters'
 * //   ],
 * //   warnings: []
 * // }
 * ```
 *
 * @example With Options
 * ```typescript
 * validateTags([], { allowEmpty: true });
 * // => { isValid: true, errors: [], warnings: [] }
 *
 * validateTags(['a'.repeat(60)], { maxLength: 50 });
 * // => { isValid: false, errors: ['Tag exceeds 50 characters'], warnings: [] }
 * ```
 */
export function validateTags(
  tags: string[],
  options: ValidationOptions = {}
): ValidationResult {
  const errors: string[] = [];
  const warnings: string[] = [];
  const maxLength = options.maxLength ?? 50;

  if (!tags || tags.length === 0) {
    if (options.allowEmpty) {
      return validResult();
    }
    return invalidResult(['At least one tag is required']);
  }

  if (tags.length > 20) {
    errors.push('Maximum of 20 tags allowed');
  } else if (tags.length > 10) {
    warnings.push('Consider using fewer tags for better organization');
  }

  const tagPattern = /^[a-zA-Z0-9_-]+$/;
  const seenTags = new Set<string>();

  for (const tag of tags) {
    if (!tag || tag.trim().length === 0) {
      errors.push('Tags cannot be empty strings');
      continue;
    }

    const normalizedTag = tag.toLowerCase().trim();

    if (seenTags.has(normalizedTag)) {
      warnings.push(`Duplicate tag: "${tag}"`);
      continue;
    }
    seenTags.add(normalizedTag);

    if (!tagPattern.test(tag)) {
      errors.push(`Tag "${tag}" contains invalid characters (use only letters, numbers, hyphens, underscores)`);
    }

    if (tag.length > maxLength) {
      errors.push(`Tag "${tag}" exceeds maximum length of ${maxLength} characters`);
    }
  }

  if (errors.length > 0 || (options.strict && warnings.length > 0)) {
    return { isValid: false, errors, warnings };
  }

  return { isValid: true, errors: [], warnings };
}

/**
 * Validates a category path.
 *
 * Categories use a hierarchical path format (e.g., 'docs/api/v2').
 * This validator ensures:
 *
 * - Path uses forward slashes as separators
 * - Each segment contains only valid characters
 * - Path doesn't start or end with a slash
 * - No empty segments (consecutive slashes)
 * - Maximum depth of 10 levels
 * - Each segment max 50 characters
 *
 * @param category - The category path to validate
 * @param options - Validation options
 * @returns Validation result for the category path
 *
 * @example Valid Categories
 * ```typescript
 * validateCategoryPath('docs/api/v2');
 * // => { isValid: true, errors: [], warnings: [] }
 *
 * validateCategoryPath('engineering');
 * // => { isValid: true, errors: [], warnings: [] }
 * ```
 *
 * @example Invalid Categories
 * ```typescript
 * validateCategoryPath('/docs/api/');
 * // => {
 * //   isValid: false,
 * //   errors: ['Category path cannot start or end with "/"'],
 * //   warnings: []
 * // }
 *
 * validateCategoryPath('docs//api');
 * // => {
 * //   isValid: false,
 * //   errors: ['Category path contains empty segments'],
 * //   warnings: []
 * // }
 * ```
 */
export function validateCategoryPath(
  category: string,
  options: ValidationOptions = {}
): ValidationResult {
  if (!category || category.trim().length === 0) {
    if (options.allowEmpty) {
      return validResult();
    }
    return invalidResult(['Category path is required']);
  }

  const errors: string[] = [];
  const warnings: string[] = [];

  // Check for leading/trailing slashes
  if (category.startsWith('/') || category.endsWith('/')) {
    errors.push('Category path cannot start or end with "/"');
  }

  // Check for backslashes
  if (category.includes('\\')) {
    errors.push('Use forward slashes "/" instead of backslashes');
  }

  // Check for empty segments
  if (category.includes('//')) {
    errors.push('Category path contains empty segments (consecutive slashes)');
  }

  const segments = category.split('/');
  const segmentPattern = /^[a-zA-Z0-9_-]+$/;
  const maxSegmentLength = options.maxLength ?? 50;

  // Check depth
  if (segments.length > 10) {
    errors.push('Category path exceeds maximum depth of 10 levels');
  } else if (segments.length > 5) {
    warnings.push('Deep category hierarchies may be hard to navigate');
  }

  // Validate each segment
  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i];

    if (!segment || segment.length === 0) {
      continue; // Already handled by // check
    }

    if (!segmentPattern.test(segment)) {
      errors.push(
        `Category segment "${segment}" at position ${i + 1} contains invalid characters`
      );
    }

    if (segment.length > maxSegmentLength) {
      errors.push(
        `Category segment "${segment}" exceeds maximum length of ${maxSegmentLength} characters`
      );
    }
  }

  if (errors.length > 0 || (options.strict && warnings.length > 0)) {
    return { isValid: false, errors, warnings };
  }

  return { isValid: true, errors: [], warnings };
}

/**
 * Validates a document type value.
 *
 * Ensures the type is one of the supported DocumentType enum values.
 *
 * @param type - The type value to validate
 * @returns Validation result
 *
 * @example
 * ```typescript
 * validateDocumentType('markdown');
 * // => { isValid: true, errors: [], warnings: [] }
 *
 * validateDocumentType('pdf');
 * // => { isValid: false, errors: ['Invalid document type: pdf'], warnings: [] }
 * ```
 */
export function validateDocumentType(type: string): ValidationResult {
  const validTypes = Object.values(DocumentType);

  if (!validTypes.includes(type as DocumentType)) {
    return invalidResult(
      [`Invalid document type: ${type}. Valid types: ${validTypes.join(', ')}`]
    );
  }

  return validResult();
}

/**
 * Validates a document status value.
 *
 * Ensures the status is one of the supported DocumentStatus enum values.
 *
 * @param status - The status value to validate
 * @returns Validation result
 *
 * @example
 * ```typescript
 * validateDocumentStatus('published');
 * // => { isValid: true, errors: [], warnings: [] }
 *
 * validateDocumentStatus('pending');
 * // => { isValid: false, errors: ['Invalid status: pending'], warnings: [] }
 * ```
 */
export function validateDocumentStatus(status: string): ValidationResult {
  const validStatuses = Object.values(DocumentStatus);

  if (!validStatuses.includes(status as DocumentStatus)) {
    return invalidResult(
      [`Invalid document status: ${status}. Valid statuses: ${validStatuses.join(', ')}`]
    );
  }

  return validResult();
}

/**
 * Validates an access level value.
 *
 * Ensures the access level is one of the supported AccessLevel enum values.
 *
 * @param level - The access level value to validate
 * @returns Validation result
 *
 * @example
 * ```typescript
 * validateAccessLevel('internal');
 * // => { isValid: true, errors: [], warnings: [] }
 *
 * validateAccessLevel('secret');
 * // => { isValid: false, errors: ['Invalid access level: secret'], warnings: [] }
 * ```
 */
export function validateAccessLevel(level: string): ValidationResult {
  const validLevels = Object.values(AccessLevel);

  if (!validLevels.includes(level as AccessLevel)) {
    return invalidResult(
      [`Invalid access level: ${level}. Valid levels: ${validLevels.join(', ')}`]
    );
  }

  return validResult();
}

/**
 * Validates an email address format.
 *
 * Performs RFC 5322 compliant email validation with the following checks:
 *
 * - Contains exactly one @ symbol
 * - Local part (before @) is non-empty and valid
 * - Domain part (after @) is non-empty and contains at least one dot
 * - No consecutive dots
 * - Valid characters throughout
 *
 * @param email - The email address to validate
 * @param options - Validation options
 * @returns Validation result
 *
 * @example Valid Emails
 * ```typescript
 * validateEmail('user@example.com');
 * // => { isValid: true, errors: [], warnings: [] }
 *
 * validateEmail('user.name+tag@subdomain.example.co.uk');
 * // => { isValid: true, errors: [], warnings: [] }
 * ```
 *
 * @example Invalid Emails
 * ```typescript
 * validateEmail('not-an-email');
 * // => { isValid: false, errors: ['Invalid email format'], warnings: [] }
 *
 * validateEmail('user@');
 * // => { isValid: false, errors: ['Invalid email format'], warnings: [] }
 * ```
 */
export function validateEmail(
  email: string,
  options: ValidationOptions = {}
): ValidationResult {
  if (!email || email.trim().length === 0) {
    if (options.allowEmpty) {
      return validResult();
    }
    return invalidResult(['Email address is required']);
  }

  // RFC 5322 compliant email regex (simplified)
  const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;

  if (!emailRegex.test(email)) {
    return invalidResult(['Invalid email format']);
  }

  const warnings: string[] = [];

  // Check for common typos
  const commonDomains = ['gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com'];
  const domain = email.split('@')[1]?.toLowerCase();

  if (domain) {
    for (const common of commonDomains) {
      if (domain !== common && levenshteinDistance(domain, common) <= 2) {
        warnings.push(`Did you mean ${common}?`);
        break;
      }
    }
  }

  return { isValid: true, errors: [], warnings };
}

/**
 * Validates a semantic version string.
 *
 * Checks if the version follows semantic versioning (semver) format:
 * MAJOR.MINOR.PATCH with optional prerelease and build metadata.
 *
 * @param version - The version string to validate
 * @param options - Validation options
 * @returns Validation result
 *
 * @example Valid Versions
 * ```typescript
 * validateVersion('1.0.0');
 * // => { isValid: true, errors: [], warnings: [] }
 *
 * validateVersion('2.1.3-beta.1+build.123');
 * // => { isValid: true, errors: [], warnings: [] }
 * ```
 *
 * @example Invalid Versions
 * ```typescript
 * validateVersion('1.0');
 * // => { isValid: false, errors: ['Invalid semver format'], warnings: [] }
 *
 * validateVersion('v1.0.0');
 * // => { isValid: false, errors: ['Remove "v" prefix'], warnings: [] }
 * ```
 */
export function validateVersion(
  version: string,
  options: ValidationOptions = {}
): ValidationResult {
  if (!version || version.trim().length === 0) {
    if (options.allowEmpty) {
      return validResult();
    }
    return invalidResult(['Version is required']);
  }

  if (version.startsWith('v') || version.startsWith('V')) {
    return invalidResult(['Remove "v" prefix from version (use "1.0.0" not "v1.0.0")']);
  }

  // Semantic versioning regex
  const semverRegex = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/;

  if (!semverRegex.test(version)) {
    return invalidResult([
      'Invalid semantic version format. Expected: MAJOR.MINOR.PATCH (e.g., "1.0.0")'
    ]);
  }

  const warnings: string[] = [];
  const [major] = version.split('.');

  if (parseInt(major, 10) === 0) {
    warnings.push('Version 0.x.x indicates initial development; API may change');
  }

  return { isValid: true, errors: [], warnings };
}

/**
 * Combines multiple validation results into a single result.
 *
 * Useful when validating multiple fields of an object. The combined
 * result is valid only if all individual results are valid.
 *
 * @param results - Array of validation results to combine
 * @returns Combined validation result
 *
 * @example
 * ```typescript
 * const idResult = validateDocumentId(doc.id);
 * const tagsResult = validateTags(doc.tags);
 * const categoryResult = validateCategoryPath(doc.category);
 *
 * const combined = combineValidationResults([
 *   idResult,
 *   tagsResult,
 *   categoryResult
 * ]);
 *
 * if (!combined.isValid) {
 *   console.log('Validation errors:', combined.errors);
 * }
 * ```
 */
export function combineValidationResults(
  results: ValidationResult[]
): ValidationResult {
  const allErrors: string[] = [];
  const allWarnings: string[] = [];

  for (const result of results) {
    allErrors.push(...result.errors);
    allWarnings.push(...result.warnings);
  }

  return {
    isValid: allErrors.length === 0,
    errors: allErrors,
    warnings: allWarnings
  };
}

/**
 * Calculates the Levenshtein distance between two strings.
 *
 * Used internally for fuzzy matching (e.g., suggesting email domain corrections).
 *
 * @param a - First string
 * @param b - Second string
 * @returns The edit distance between the strings
 * @internal
 */
function levenshteinDistance(a: string, b: string): number {
  const matrix: number[][] = [];

  for (let i = 0; i <= b.length; i++) {
    matrix[i] = [i];
  }

  for (let j = 0; j <= a.length; j++) {
    matrix[0][j] = j;
  }

  for (let i = 1; i <= b.length; i++) {
    for (let j = 1; j <= a.length; j++) {
      if (b.charAt(i - 1) === a.charAt(j - 1)) {
        matrix[i][j] = matrix[i - 1][j - 1];
      } else {
        matrix[i][j] = Math.min(
          matrix[i - 1][j - 1] + 1, // substitution
          matrix[i][j - 1] + 1,     // insertion
          matrix[i - 1][j] + 1      // deletion
        );
      }
    }
  }

  return matrix[b.length][a.length];
}
