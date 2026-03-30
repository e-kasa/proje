/**
 * @fileoverview Document Manager - A comprehensive document management API.
 *
 * This is the main entry point for the Document Manager library. It provides
 * a complete solution for storing, retrieving, searching, and managing
 * documents with support for multiple content types, access control,
 * and lifecycle management.
 *
 * ## Features
 *
 * - **Multiple Document Types**: Support for text, markdown, HTML, JSON, and binary
 * - **Lifecycle Management**: Draft, published, archived, and deleted states
 * - **Access Control**: Public, internal, private, and confidential levels
 * - **Full-Text Search**: Search across titles and content
 * - **Metadata & Tags**: Flexible categorization and custom attributes
 * - **Pagination**: Efficient handling of large document collections
 * - **Validation**: Comprehensive input validation with detailed errors
 *
 * ## Quick Start
 *
 * ```typescript
 * import {
 *   DocumentManager,
 *   DocumentType,
 *   DocumentStatus
 * } from 'document-manager';
 *
 * // Create a document manager instance
 * const manager = new DocumentManager();
 *
 * // Create a document
 * const result = await manager.create({
 *   type: DocumentType.MARKDOWN,
 *   title: 'Getting Started',
 *   content: '# Welcome\n\nThis is your first document.',
 *   metadata: {
 *     author: 'developer@example.com',
 *     tags: ['welcome', 'getting-started']
 *   }
 * });
 *
 * if (result.success) {
 *   console.log('Document created:', result.data.id);
 *
 *   // Publish the document
 *   await manager.update(result.data.id, {
 *     status: DocumentStatus.PUBLISHED
 *   });
 * }
 *
 * // Search for documents
 * const searchResults = await manager.search({
 *   status: DocumentStatus.PUBLISHED,
 *   searchText: 'welcome',
 *   limit: 10
 * });
 *
 * console.log(`Found ${searchResults.total} documents`);
 * ```
 *
 * ## Configuration
 *
 * ```typescript
 * const manager = new DocumentManager({
 *   maxDocumentSize: 5 * 1024 * 1024, // 5MB limit
 *   maxTitleLength: 200,
 *   defaultAccessLevel: AccessLevel.INTERNAL,
 *   defaultStatus: DocumentStatus.DRAFT,
 *   enableVersioning: true,
 *   enableSoftDelete: true
 * });
 * ```
 *
 * ## Error Handling
 *
 * All operations return a Result type that explicitly indicates success or failure:
 *
 * ```typescript
 * const result = await manager.get('document-id');
 *
 * if (result.success) {
 *   // Access the document
 *   console.log(result.data.title);
 * } else {
 *   // Handle the error
 *   console.error(`Error ${result.error.code}: ${result.error.message}`);
 * }
 * ```
 *
 * @module document-manager
 * @version 1.0.0
 * @license MIT
 *
 * @see {@link DocumentManager} for the main API
 * @see {@link DocumentType} for supported document types
 * @see {@link DocumentStatus} for lifecycle states
 */

// Main API
export { DocumentManager, DocumentManagerConfig, DocumentStats } from './DocumentManager';

// Types
export {
  // Enums
  DocumentType,
  DocumentStatus,
  AccessLevel,

  // Interfaces
  Document,
  DocumentMetadata,
  CreateDocumentInput,
  UpdateDocumentInput,
  DocumentQuery,
  PaginatedResponse,
  ApiError,
  Result
} from './types';

// Utilities
export {
  // Validation
  validateDocumentId,
  validateTags,
  validateCategoryPath,
  validateDocumentType,
  validateDocumentStatus,
  validateAccessLevel,
  validateEmail,
  validateVersion,
  combineValidationResults,
  validResult,
  invalidResult,

  // Types
  ValidationResult,
  ValidationOptions
} from './utils';
