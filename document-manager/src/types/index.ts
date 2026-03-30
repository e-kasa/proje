/**
 * @fileoverview Core type definitions for the Document Manager API.
 *
 * This module defines all the fundamental types, interfaces, and enumerations
 * used throughout the document management system. These types provide strong
 * typing for documents, metadata, search operations, and API responses.
 *
 * @module types
 * @version 1.0.0
 */

/**
 * Supported document types in the system.
 *
 * The document manager supports multiple content types, each with specific
 * handling and validation rules. The type affects how content is stored,
 * indexed, and rendered.
 *
 * @example
 * ```typescript
 * // Creating a text document
 * const textDoc: Document = {
 *   id: 'doc-123',
 *   type: DocumentType.TEXT,
 *   title: 'Meeting Notes',
 *   content: 'Notes from today...',
 *   // ...
 * };
 *
 * // Creating an HTML document
 * const htmlDoc: Document = {
 *   id: 'doc-456',
 *   type: DocumentType.HTML,
 *   title: 'Report',
 *   content: '<h1>Annual Report</h1>...',
 *   // ...
 * };
 * ```
 */
export enum DocumentType {
  /** Plain text documents without formatting */
  TEXT = 'text',
  /** Markdown formatted documents */
  MARKDOWN = 'markdown',
  /** HTML formatted documents */
  HTML = 'html',
  /** JSON structured data documents */
  JSON = 'json',
  /** Binary data (base64 encoded when stored) */
  BINARY = 'binary'
}

/**
 * Document status indicating its current lifecycle state.
 *
 * Documents progress through various states during their lifecycle.
 * Status affects visibility, editability, and retention policies.
 *
 * @remarks
 * State transitions follow these rules:
 * - DRAFT can transition to: PUBLISHED, ARCHIVED
 * - PUBLISHED can transition to: ARCHIVED, DRAFT
 * - ARCHIVED can transition to: PUBLISHED (restore), DELETED
 * - DELETED is a terminal state (soft delete, can be purged)
 */
export enum DocumentStatus {
  /** Working document, not visible to general users */
  DRAFT = 'draft',
  /** Published and visible to authorized users */
  PUBLISHED = 'published',
  /** Archived for historical reference, read-only */
  ARCHIVED = 'archived',
  /** Soft deleted, pending permanent removal */
  DELETED = 'deleted'
}

/**
 * Access control levels for documents.
 *
 * Determines who can view and interact with a document.
 * Higher levels include all permissions of lower levels.
 */
export enum AccessLevel {
  /** Accessible to anyone, no authentication required */
  PUBLIC = 'public',
  /** Requires authentication to access */
  INTERNAL = 'internal',
  /** Restricted to specific users or groups */
  PRIVATE = 'private',
  /** Highly sensitive, requires elevated permissions */
  CONFIDENTIAL = 'confidential'
}

/**
 * Metadata associated with a document.
 *
 * Contains supplementary information about the document including
 * categorization, ownership, and custom attributes. All fields are
 * optional to allow flexible document organization.
 *
 * @example
 * ```typescript
 * const metadata: DocumentMetadata = {
 *   author: 'john.doe@example.com',
 *   tags: ['quarterly', 'finance', '2024'],
 *   category: 'reports/financial',
 *   version: '2.1',
 *   customFields: {
 *     department: 'Finance',
 *     reviewedBy: 'Jane Smith',
 *     approvalDate: '2024-03-15'
 *   }
 * };
 * ```
 */
export interface DocumentMetadata {
  /** Email or identifier of the document author */
  author?: string;

  /** Searchable tags for categorization */
  tags?: string[];

  /** Hierarchical category path (e.g., 'reports/financial/quarterly') */
  category?: string;

  /** Semantic version of the document content */
  version?: string;

  /** Custom key-value pairs for application-specific data */
  customFields?: Record<string, unknown>;
}

/**
 * Core document interface representing a stored document.
 *
 * This is the primary data structure for all documents in the system.
 * Documents are immutable once created; updates create new versions
 * while preserving the original.
 *
 * @example
 * ```typescript
 * // Full document example
 * const document: Document = {
 *   id: 'doc_a1b2c3d4e5f6',
 *   type: DocumentType.MARKDOWN,
 *   title: 'API Documentation',
 *   content: '# Getting Started\n\nWelcome to...',
 *   status: DocumentStatus.PUBLISHED,
 *   accessLevel: AccessLevel.INTERNAL,
 *   metadata: {
 *     author: 'developer@example.com',
 *     tags: ['api', 'documentation', 'getting-started'],
 *     category: 'docs/api',
 *     version: '1.0.0'
 *   },
 *   createdAt: new Date('2024-01-15T10:30:00Z'),
 *   updatedAt: new Date('2024-02-20T14:45:00Z')
 * };
 * ```
 */
export interface Document {
  /** Unique identifier (UUID v4 format) */
  id: string;

  /** Content type of the document */
  type: DocumentType;

  /** Human-readable title (max 500 characters) */
  title: string;

  /** Document content (size limit varies by type) */
  content: string;

  /** Current lifecycle status */
  status: DocumentStatus;

  /** Access control level */
  accessLevel: AccessLevel;

  /** Associated metadata */
  metadata: DocumentMetadata;

  /** Timestamp of document creation (immutable) */
  createdAt: Date;

  /** Timestamp of last modification */
  updatedAt: Date;
}

/**
 * Input for creating a new document.
 *
 * Omits system-generated fields (id, createdAt, updatedAt) which are
 * automatically populated during creation. Status defaults to DRAFT
 * if not specified.
 *
 * @example
 * ```typescript
 * const input: CreateDocumentInput = {
 *   type: DocumentType.TEXT,
 *   title: 'New Document',
 *   content: 'Initial content...',
 *   metadata: {
 *     author: 'user@example.com',
 *     tags: ['draft']
 *   }
 * };
 *
 * const doc = await documentManager.create(input);
 * ```
 */
export interface CreateDocumentInput {
  /** Content type - determines validation rules */
  type: DocumentType;

  /** Document title (required, non-empty) */
  title: string;

  /** Document content */
  content: string;

  /** Initial status (defaults to DRAFT) */
  status?: DocumentStatus;

  /** Access level (defaults to PRIVATE) */
  accessLevel?: AccessLevel;

  /** Optional metadata */
  metadata?: DocumentMetadata;
}

/**
 * Input for updating an existing document.
 *
 * All fields are optional; only provided fields will be updated.
 * The updatedAt timestamp is automatically set on any change.
 *
 * @example
 * ```typescript
 * // Update only the title and status
 * const update: UpdateDocumentInput = {
 *   title: 'Updated Title',
 *   status: DocumentStatus.PUBLISHED
 * };
 *
 * const doc = await documentManager.update('doc-id', update);
 * ```
 */
export interface UpdateDocumentInput {
  /** New document type (triggers re-validation) */
  type?: DocumentType;

  /** New title */
  title?: string;

  /** New content */
  content?: string;

  /** New status */
  status?: DocumentStatus;

  /** New access level */
  accessLevel?: AccessLevel;

  /** Metadata updates (merged with existing) */
  metadata?: Partial<DocumentMetadata>;
}

/**
 * Search/filter criteria for querying documents.
 *
 * All criteria are combined with AND logic. Empty or undefined
 * criteria are ignored. For OR logic, perform multiple queries.
 *
 * @example
 * ```typescript
 * // Find all published markdown documents tagged 'important'
 * const query: DocumentQuery = {
 *   type: DocumentType.MARKDOWN,
 *   status: DocumentStatus.PUBLISHED,
 *   tags: ['important'],
 *   limit: 20,
 *   offset: 0
 * };
 *
 * const results = await documentManager.search(query);
 * ```
 */
export interface DocumentQuery {
  /** Filter by document type */
  type?: DocumentType;

  /** Filter by status */
  status?: DocumentStatus;

  /** Filter by access level */
  accessLevel?: AccessLevel;

  /** Filter by author (exact match) */
  author?: string;

  /** Filter by tags (documents must have ALL specified tags) */
  tags?: string[];

  /** Filter by category (prefix match) */
  category?: string;

  /** Full-text search in title and content */
  searchText?: string;

  /** Filter by creation date (on or after) */
  createdAfter?: Date;

  /** Filter by creation date (on or before) */
  createdBefore?: Date;

  /** Maximum number of results (default: 100, max: 1000) */
  limit?: number;

  /** Number of results to skip for pagination */
  offset?: number;

  /** Sort field */
  sortBy?: 'createdAt' | 'updatedAt' | 'title';

  /** Sort direction */
  sortOrder?: 'asc' | 'desc';
}

/**
 * Paginated response wrapper for list operations.
 *
 * Provides metadata about the result set for implementing
 * pagination in client applications.
 *
 * @typeParam T - The type of items in the results array
 *
 * @example
 * ```typescript
 * const response: PaginatedResponse<Document> = {
 *   items: [...documents],
 *   total: 150,
 *   limit: 20,
 *   offset: 40,
 *   hasMore: true
 * };
 *
 * // Calculate current page: Math.floor(offset / limit) + 1 = 3
 * // Calculate total pages: Math.ceil(total / limit) = 8
 * ```
 */
export interface PaginatedResponse<T> {
  /** Array of result items */
  items: T[];

  /** Total count of matching items (before pagination) */
  total: number;

  /** Page size used for this query */
  limit: number;

  /** Number of items skipped */
  offset: number;

  /** Whether more results are available */
  hasMore: boolean;
}

/**
 * Standard error response structure.
 *
 * Provides consistent error information across all API operations.
 * The code field contains a machine-readable identifier for
 * programmatic error handling.
 *
 * @example
 * ```typescript
 * // Example error response
 * const error: ApiError = {
 *   code: 'DOCUMENT_NOT_FOUND',
 *   message: 'Document with ID "doc-123" not found',
 *   details: {
 *     documentId: 'doc-123',
 *     searchedAt: new Date().toISOString()
 *   }
 * };
 * ```
 */
export interface ApiError {
  /** Machine-readable error code (e.g., 'DOCUMENT_NOT_FOUND') */
  code: string;

  /** Human-readable error description */
  message: string;

  /** Additional context about the error */
  details?: Record<string, unknown>;
}

/**
 * Result type for operations that may fail.
 *
 * Implements the Result pattern for explicit error handling
 * without throwing exceptions. Callers must check the success
 * flag before accessing data or error.
 *
 * @typeParam T - The type of the success data
 *
 * @example
 * ```typescript
 * const result = await documentManager.get('doc-id');
 *
 * if (result.success) {
 *   console.log('Document:', result.data.title);
 * } else {
 *   console.error('Error:', result.error.message);
 * }
 * ```
 */
export type Result<T> =
  | { success: true; data: T }
  | { success: false; error: ApiError };
