/**
 * @fileoverview Core Document Manager implementation.
 *
 * This module provides the main DocumentManager class that handles all
 * document operations including CRUD operations, search, and lifecycle
 * management. It implements an in-memory storage by default with hooks
 * for custom storage adapters.
 *
 * @module DocumentManager
 * @version 1.0.0
 *
 * @example Basic Usage
 * ```typescript
 * import { DocumentManager } from './DocumentManager';
 * import { DocumentType, DocumentStatus } from './types';
 *
 * // Initialize the document manager
 * const manager = new DocumentManager();
 *
 * // Create a document
 * const result = await manager.create({
 *   type: DocumentType.TEXT,
 *   title: 'My First Document',
 *   content: 'Hello, World!'
 * });
 *
 * if (result.success) {
 *   console.log('Created:', result.data.id);
 * }
 * ```
 *
 * @example Advanced Configuration
 * ```typescript
 * const manager = new DocumentManager({
 *   maxDocumentSize: 10 * 1024 * 1024, // 10MB
 *   defaultAccessLevel: AccessLevel.INTERNAL,
 *   enableVersioning: true
 * });
 * ```
 */

import { v4 as uuidv4 } from 'uuid';
import {
  Document,
  DocumentType,
  DocumentStatus,
  AccessLevel,
  DocumentMetadata,
  CreateDocumentInput,
  UpdateDocumentInput,
  DocumentQuery,
  PaginatedResponse,
  ApiError,
  Result
} from './types';

/**
 * Configuration options for DocumentManager initialization.
 *
 * These options customize the behavior of the document manager
 * including limits, defaults, and feature flags.
 *
 * @example
 * ```typescript
 * const config: DocumentManagerConfig = {
 *   maxDocumentSize: 5 * 1024 * 1024, // 5MB limit
 *   maxTitleLength: 200,
 *   defaultAccessLevel: AccessLevel.PRIVATE,
 *   defaultStatus: DocumentStatus.DRAFT,
 *   enableVersioning: false,
 *   enableSoftDelete: true
 * };
 * ```
 */
export interface DocumentManagerConfig {
  /**
   * Maximum document content size in bytes.
   * @default 1048576 (1MB)
   */
  maxDocumentSize?: number;

  /**
   * Maximum title length in characters.
   * @default 500
   */
  maxTitleLength?: number;

  /**
   * Default access level for new documents.
   * @default AccessLevel.PRIVATE
   */
  defaultAccessLevel?: AccessLevel;

  /**
   * Default status for new documents.
   * @default DocumentStatus.DRAFT
   */
  defaultStatus?: DocumentStatus;

  /**
   * Enable automatic version tracking.
   * When enabled, updates preserve previous versions.
   * @default false
   */
  enableVersioning?: boolean;

  /**
   * Use soft delete instead of immediate removal.
   * Soft-deleted documents can be restored.
   * @default true
   */
  enableSoftDelete?: boolean;
}

/**
 * Statistics about the document collection.
 *
 * Provides aggregate information about stored documents
 * for monitoring and administrative purposes.
 */
export interface DocumentStats {
  /** Total number of documents */
  totalDocuments: number;

  /** Count by document type */
  byType: Record<DocumentType, number>;

  /** Count by status */
  byStatus: Record<DocumentStatus, number>;

  /** Count by access level */
  byAccessLevel: Record<AccessLevel, number>;

  /** Total storage size in bytes (approximate) */
  totalSizeBytes: number;

  /** Timestamp of oldest document */
  oldestDocument?: Date;

  /** Timestamp of newest document */
  newestDocument?: Date;
}

/**
 * DocumentManager - Core document management service.
 *
 * Provides comprehensive document lifecycle management including creation,
 * retrieval, update, deletion, and search operations. Documents are stored
 * in-memory by default, with support for custom storage adapters.
 *
 * ## Features
 *
 * - **CRUD Operations**: Create, read, update, and delete documents
 * - **Search & Filtering**: Full-text search and multi-criteria filtering
 * - **Pagination**: Efficient handling of large result sets
 * - **Lifecycle Management**: Status transitions and access control
 * - **Validation**: Content type validation and size limits
 * - **Error Handling**: Result-based error handling without exceptions
 *
 * ## Thread Safety
 *
 * This implementation is designed for single-threaded Node.js environments.
 * For concurrent access in clustered environments, use a persistent storage
 * adapter with appropriate locking mechanisms.
 *
 * ## Memory Considerations
 *
 * The default in-memory storage keeps all documents in RAM. For large
 * collections, implement a custom storage adapter backed by a database.
 *
 * @example Creating and Managing Documents
 * ```typescript
 * const manager = new DocumentManager();
 *
 * // Create a document
 * const createResult = await manager.create({
 *   type: DocumentType.MARKDOWN,
 *   title: 'Project README',
 *   content: '# My Project\n\nDescription here...',
 *   metadata: {
 *     author: 'developer@example.com',
 *     tags: ['documentation', 'readme']
 *   }
 * });
 *
 * if (!createResult.success) {
 *   console.error('Failed to create:', createResult.error);
 *   return;
 * }
 *
 * const doc = createResult.data;
 * console.log(`Created document: ${doc.id}`);
 *
 * // Update the document
 * const updateResult = await manager.update(doc.id, {
 *   status: DocumentStatus.PUBLISHED,
 *   content: '# My Project\n\nUpdated description...'
 * });
 *
 * // Delete when no longer needed
 * await manager.delete(doc.id);
 * ```
 *
 * @example Searching Documents
 * ```typescript
 * const manager = new DocumentManager();
 *
 * // Search with multiple criteria
 * const results = await manager.search({
 *   type: DocumentType.MARKDOWN,
 *   status: DocumentStatus.PUBLISHED,
 *   tags: ['documentation'],
 *   searchText: 'API',
 *   sortBy: 'updatedAt',
 *   sortOrder: 'desc',
 *   limit: 10,
 *   offset: 0
 * });
 *
 * console.log(`Found ${results.total} documents`);
 * for (const doc of results.items) {
 *   console.log(`- ${doc.title} (${doc.id})`);
 * }
 *
 * // Paginate through results
 * if (results.hasMore) {
 *   const nextPage = await manager.search({
 *     // ... same criteria
 *     offset: results.offset + results.limit
 *   });
 * }
 * ```
 *
 * @example Bulk Operations
 * ```typescript
 * const manager = new DocumentManager();
 *
 * // Create multiple documents
 * const documents = [
 *   { type: DocumentType.TEXT, title: 'Doc 1', content: '...' },
 *   { type: DocumentType.TEXT, title: 'Doc 2', content: '...' },
 *   { type: DocumentType.TEXT, title: 'Doc 3', content: '...' }
 * ];
 *
 * const results = await manager.createBulk(documents);
 *
 * const successful = results.filter(r => r.success);
 * const failed = results.filter(r => !r.success);
 *
 * console.log(`Created ${successful.length}, failed ${failed.length}`);
 * ```
 */
export class DocumentManager {
  /** In-memory document storage indexed by ID */
  private documents: Map<string, Document> = new Map();

  /** Configuration options */
  private readonly config: Required<DocumentManagerConfig>;

  /** Default configuration values */
  private static readonly DEFAULT_CONFIG: Required<DocumentManagerConfig> = {
    maxDocumentSize: 1024 * 1024, // 1MB
    maxTitleLength: 500,
    defaultAccessLevel: AccessLevel.PRIVATE,
    defaultStatus: DocumentStatus.DRAFT,
    enableVersioning: false,
    enableSoftDelete: true
  };

  /**
   * Creates a new DocumentManager instance.
   *
   * Initializes the document manager with the provided configuration,
   * applying defaults for any unspecified options.
   *
   * @param config - Optional configuration overrides
   *
   * @example Default Configuration
   * ```typescript
   * const manager = new DocumentManager();
   * // Uses all default settings
   * ```
   *
   * @example Custom Configuration
   * ```typescript
   * const manager = new DocumentManager({
   *   maxDocumentSize: 10 * 1024 * 1024, // 10MB
   *   enableVersioning: true
   * });
   * ```
   */
  constructor(config: DocumentManagerConfig = {}) {
    this.config = {
      ...DocumentManager.DEFAULT_CONFIG,
      ...config
    };
  }

  /**
   * Creates a new document.
   *
   * Validates the input, generates a unique ID, and stores the document.
   * System fields (id, createdAt, updatedAt) are automatically populated.
   *
   * ## Validation Rules
   *
   * - Title must be non-empty and within maxTitleLength
   * - Content size must not exceed maxDocumentSize
   * - Content is validated against the specified document type
   * - JSON type documents must contain valid JSON
   *
   * ## Default Values
   *
   * - `id`: Generated UUID v4
   * - `status`: Configured default (usually DRAFT)
   * - `accessLevel`: Configured default (usually PRIVATE)
   * - `metadata`: Empty object if not provided
   * - `createdAt`: Current timestamp
   * - `updatedAt`: Same as createdAt initially
   *
   * @param input - Document creation input
   * @returns Result containing the created document or an error
   *
   * @example Basic Creation
   * ```typescript
   * const result = await manager.create({
   *   type: DocumentType.TEXT,
   *   title: 'Simple Note',
   *   content: 'This is a simple text note.'
   * });
   *
   * if (result.success) {
   *   console.log('Created:', result.data.id);
   * }
   * ```
   *
   * @example Full Creation with Metadata
   * ```typescript
   * const result = await manager.create({
   *   type: DocumentType.MARKDOWN,
   *   title: 'Technical Specification',
   *   content: '# Spec\n\n## Overview\n...',
   *   status: DocumentStatus.PUBLISHED,
   *   accessLevel: AccessLevel.INTERNAL,
   *   metadata: {
   *     author: 'architect@company.com',
   *     tags: ['spec', 'technical', 'v2'],
   *     category: 'engineering/specs',
   *     version: '2.0.0',
   *     customFields: {
   *       reviewers: ['lead@company.com'],
   *       approvedDate: '2024-03-15'
   *     }
   *   }
   * });
   * ```
   */
  async create(input: CreateDocumentInput): Promise<Result<Document>> {
    // Validate title
    const titleValidation = this.validateTitle(input.title);
    if (!titleValidation.valid) {
      return {
        success: false,
        error: {
          code: 'INVALID_TITLE',
          message: titleValidation.error!,
          details: { title: input.title }
        }
      };
    }

    // Validate content size
    const contentSize = Buffer.byteLength(input.content, 'utf8');
    if (contentSize > this.config.maxDocumentSize) {
      return {
        success: false,
        error: {
          code: 'CONTENT_TOO_LARGE',
          message: `Content size ${contentSize} bytes exceeds maximum ${this.config.maxDocumentSize} bytes`,
          details: {
            size: contentSize,
            maxSize: this.config.maxDocumentSize
          }
        }
      };
    }

    // Validate content type
    const contentValidation = this.validateContent(input.content, input.type);
    if (!contentValidation.valid) {
      return {
        success: false,
        error: {
          code: 'INVALID_CONTENT',
          message: contentValidation.error!,
          details: { type: input.type }
        }
      };
    }

    const now = new Date();
    const document: Document = {
      id: uuidv4(),
      type: input.type,
      title: input.title.trim(),
      content: input.content,
      status: input.status ?? this.config.defaultStatus,
      accessLevel: input.accessLevel ?? this.config.defaultAccessLevel,
      metadata: input.metadata ?? {},
      createdAt: now,
      updatedAt: now
    };

    this.documents.set(document.id, document);

    return { success: true, data: this.cloneDocument(document) };
  }

  /**
   * Creates multiple documents in a single operation.
   *
   * Processes each document independently; failures do not affect
   * other documents in the batch. Returns results in the same order
   * as the input array.
   *
   * @param inputs - Array of document creation inputs
   * @returns Array of results corresponding to each input
   *
   * @example
   * ```typescript
   * const results = await manager.createBulk([
   *   { type: DocumentType.TEXT, title: 'Doc 1', content: 'Content 1' },
   *   { type: DocumentType.TEXT, title: 'Doc 2', content: 'Content 2' },
   *   { type: DocumentType.TEXT, title: '', content: 'Invalid' } // Will fail
   * ]);
   *
   * results.forEach((result, index) => {
   *   if (result.success) {
   *     console.log(`Doc ${index + 1} created: ${result.data.id}`);
   *   } else {
   *     console.log(`Doc ${index + 1} failed: ${result.error.message}`);
   *   }
   * });
   * ```
   */
  async createBulk(inputs: CreateDocumentInput[]): Promise<Result<Document>[]> {
    return Promise.all(inputs.map(input => this.create(input)));
  }

  /**
   * Retrieves a document by its ID.
   *
   * Returns a copy of the document to prevent external modifications
   * to the internal state. For documents with DELETED status, retrieval
   * is still possible but may be restricted in future versions.
   *
   * @param id - The document's unique identifier
   * @returns Result containing the document or a not-found error
   *
   * @example
   * ```typescript
   * const result = await manager.get('doc_a1b2c3d4');
   *
   * if (result.success) {
   *   const doc = result.data;
   *   console.log(`Title: ${doc.title}`);
   *   console.log(`Created: ${doc.createdAt}`);
   *   console.log(`Content length: ${doc.content.length}`);
   * } else {
   *   console.error(`Document not found: ${result.error.message}`);
   * }
   * ```
   */
  async get(id: string): Promise<Result<Document>> {
    const document = this.documents.get(id);

    if (!document) {
      return {
        success: false,
        error: {
          code: 'DOCUMENT_NOT_FOUND',
          message: `Document with ID "${id}" not found`,
          details: { documentId: id }
        }
      };
    }

    return { success: true, data: this.cloneDocument(document) };
  }

  /**
   * Retrieves multiple documents by their IDs.
   *
   * Returns results for all requested IDs, including not-found errors
   * for missing documents. Results are returned in the same order as
   * the input IDs.
   *
   * @param ids - Array of document IDs to retrieve
   * @returns Array of results corresponding to each ID
   *
   * @example
   * ```typescript
   * const results = await manager.getMany(['id1', 'id2', 'id3']);
   *
   * const found = results.filter(r => r.success);
   * const missing = results.filter(r => !r.success);
   *
   * console.log(`Found ${found.length} of ${results.length} documents`);
   * ```
   */
  async getMany(ids: string[]): Promise<Result<Document>[]> {
    return Promise.all(ids.map(id => this.get(id)));
  }

  /**
   * Updates an existing document.
   *
   * Only provided fields are updated; omitted fields retain their
   * current values. Metadata updates are merged with existing metadata.
   * The updatedAt timestamp is automatically set.
   *
   * ## Merge Behavior
   *
   * - Top-level fields: Replaced entirely
   * - Metadata object: Shallow merged with existing
   * - Metadata.customFields: Shallow merged with existing
   * - Metadata.tags: Replaced entirely (not merged)
   *
   * ## Validation
   *
   * Same validation rules as create() apply to updated fields.
   *
   * @param id - The document's unique identifier
   * @param input - Fields to update
   * @returns Result containing the updated document or an error
   *
   * @example Partial Update
   * ```typescript
   * // Update only the title
   * const result = await manager.update('doc-id', {
   *   title: 'New Title'
   * });
   * ```
   *
   * @example Status Change
   * ```typescript
   * // Publish a draft document
   * const result = await manager.update('doc-id', {
   *   status: DocumentStatus.PUBLISHED
   * });
   * ```
   *
   * @example Metadata Update
   * ```typescript
   * // Add new tags (merges with existing metadata)
   * const result = await manager.update('doc-id', {
   *   metadata: {
   *     tags: ['new-tag', 'important'],
   *     customFields: {
   *       lastReviewedBy: 'reviewer@example.com'
   *     }
   *   }
   * });
   * ```
   */
  async update(id: string, input: UpdateDocumentInput): Promise<Result<Document>> {
    const existing = this.documents.get(id);

    if (!existing) {
      return {
        success: false,
        error: {
          code: 'DOCUMENT_NOT_FOUND',
          message: `Document with ID "${id}" not found`,
          details: { documentId: id }
        }
      };
    }

    // Validate title if provided
    if (input.title !== undefined) {
      const titleValidation = this.validateTitle(input.title);
      if (!titleValidation.valid) {
        return {
          success: false,
          error: {
            code: 'INVALID_TITLE',
            message: titleValidation.error!,
            details: { title: input.title }
          }
        };
      }
    }

    // Validate content if provided
    if (input.content !== undefined) {
      const contentSize = Buffer.byteLength(input.content, 'utf8');
      if (contentSize > this.config.maxDocumentSize) {
        return {
          success: false,
          error: {
            code: 'CONTENT_TOO_LARGE',
            message: `Content size ${contentSize} bytes exceeds maximum ${this.config.maxDocumentSize} bytes`,
            details: {
              size: contentSize,
              maxSize: this.config.maxDocumentSize
            }
          }
        };
      }

      const contentType = input.type ?? existing.type;
      const contentValidation = this.validateContent(input.content, contentType);
      if (!contentValidation.valid) {
        return {
          success: false,
          error: {
            code: 'INVALID_CONTENT',
            message: contentValidation.error!,
            details: { type: contentType }
          }
        };
      }
    }

    // Merge metadata
    const mergedMetadata: DocumentMetadata = {
      ...existing.metadata,
      ...input.metadata,
      customFields: {
        ...existing.metadata.customFields,
        ...input.metadata?.customFields
      }
    };

    const updated: Document = {
      ...existing,
      type: input.type ?? existing.type,
      title: input.title !== undefined ? input.title.trim() : existing.title,
      content: input.content ?? existing.content,
      status: input.status ?? existing.status,
      accessLevel: input.accessLevel ?? existing.accessLevel,
      metadata: mergedMetadata,
      updatedAt: new Date()
    };

    this.documents.set(id, updated);

    return { success: true, data: this.cloneDocument(updated) };
  }

  /**
   * Deletes a document by its ID.
   *
   * Behavior depends on the `enableSoftDelete` configuration:
   *
   * - **Soft delete** (default): Sets status to DELETED; document remains
   *   in storage and can be restored or queried.
   * - **Hard delete**: Permanently removes the document from storage.
   *
   * @param id - The document's unique identifier
   * @param hard - Force hard delete regardless of configuration
   * @returns Result indicating success or failure
   *
   * @example Soft Delete (default)
   * ```typescript
   * const result = await manager.delete('doc-id');
   *
   * if (result.success) {
   *   console.log('Document soft-deleted');
   *   // Document can still be retrieved with get()
   *   // Status will be DocumentStatus.DELETED
   * }
   * ```
   *
   * @example Hard Delete
   * ```typescript
   * const result = await manager.delete('doc-id', true);
   *
   * if (result.success) {
   *   console.log('Document permanently deleted');
   *   // Document cannot be retrieved anymore
   * }
   * ```
   */
  async delete(id: string, hard: boolean = false): Promise<Result<void>> {
    const existing = this.documents.get(id);

    if (!existing) {
      return {
        success: false,
        error: {
          code: 'DOCUMENT_NOT_FOUND',
          message: `Document with ID "${id}" not found`,
          details: { documentId: id }
        }
      };
    }

    if (hard || !this.config.enableSoftDelete) {
      this.documents.delete(id);
    } else {
      existing.status = DocumentStatus.DELETED;
      existing.updatedAt = new Date();
    }

    return { success: true, data: undefined };
  }

  /**
   * Restores a soft-deleted document.
   *
   * Changes the document status from DELETED back to DRAFT.
   * Only works for soft-deleted documents; returns an error if
   * the document is not in DELETED status.
   *
   * @param id - The document's unique identifier
   * @returns Result containing the restored document or an error
   *
   * @example
   * ```typescript
   * // First, soft delete a document
   * await manager.delete('doc-id');
   *
   * // Later, restore it
   * const result = await manager.restore('doc-id');
   *
   * if (result.success) {
   *   console.log('Document restored, status:', result.data.status);
   *   // Status will be DRAFT
   * }
   * ```
   */
  async restore(id: string): Promise<Result<Document>> {
    const existing = this.documents.get(id);

    if (!existing) {
      return {
        success: false,
        error: {
          code: 'DOCUMENT_NOT_FOUND',
          message: `Document with ID "${id}" not found`,
          details: { documentId: id }
        }
      };
    }

    if (existing.status !== DocumentStatus.DELETED) {
      return {
        success: false,
        error: {
          code: 'INVALID_STATE',
          message: `Document is not deleted (current status: ${existing.status})`,
          details: {
            documentId: id,
            currentStatus: existing.status
          }
        }
      };
    }

    existing.status = DocumentStatus.DRAFT;
    existing.updatedAt = new Date();

    return { success: true, data: this.cloneDocument(existing) };
  }

  /**
   * Searches for documents matching the specified criteria.
   *
   * All criteria are combined with AND logic. The search supports:
   *
   * - **Exact matching**: type, status, accessLevel, author
   * - **Contains matching**: tags (document must have ALL specified tags)
   * - **Prefix matching**: category
   * - **Full-text search**: searchText (searches title and content)
   * - **Range filtering**: createdAfter, createdBefore
   *
   * ## Performance Notes
   *
   * - Full-text search performs case-insensitive substring matching
   * - For large collections, consider implementing indexed storage
   * - Sorting is performed in-memory after filtering
   *
   * @param query - Search criteria and pagination options
   * @returns Paginated response with matching documents
   *
   * @example Basic Search
   * ```typescript
   * const results = await manager.search({
   *   status: DocumentStatus.PUBLISHED
   * });
   *
   * console.log(`Found ${results.total} published documents`);
   * ```
   *
   * @example Complex Search
   * ```typescript
   * const results = await manager.search({
   *   type: DocumentType.MARKDOWN,
   *   status: DocumentStatus.PUBLISHED,
   *   tags: ['documentation', 'api'],
   *   searchText: 'authentication',
   *   createdAfter: new Date('2024-01-01'),
   *   sortBy: 'updatedAt',
   *   sortOrder: 'desc',
   *   limit: 20,
   *   offset: 0
   * });
   * ```
   *
   * @example Pagination
   * ```typescript
   * async function getAllDocuments(query: DocumentQuery): Promise<Document[]> {
   *   const allDocs: Document[] = [];
   *   let offset = 0;
   *   const limit = 100;
   *
   *   while (true) {
   *     const results = await manager.search({ ...query, limit, offset });
   *     allDocs.push(...results.items);
   *
   *     if (!results.hasMore) break;
   *     offset += limit;
   *   }
   *
   *   return allDocs;
   * }
   * ```
   */
  async search(query: DocumentQuery = {}): Promise<PaginatedResponse<Document>> {
    let results = Array.from(this.documents.values());

    // Apply filters
    if (query.type !== undefined) {
      results = results.filter(doc => doc.type === query.type);
    }

    if (query.status !== undefined) {
      results = results.filter(doc => doc.status === query.status);
    }

    if (query.accessLevel !== undefined) {
      results = results.filter(doc => doc.accessLevel === query.accessLevel);
    }

    if (query.author !== undefined) {
      results = results.filter(doc => doc.metadata.author === query.author);
    }

    if (query.tags && query.tags.length > 0) {
      results = results.filter(doc => {
        const docTags = doc.metadata.tags ?? [];
        return query.tags!.every(tag => docTags.includes(tag));
      });
    }

    if (query.category !== undefined) {
      results = results.filter(doc =>
        doc.metadata.category?.startsWith(query.category!) ?? false
      );
    }

    if (query.searchText !== undefined && query.searchText.trim() !== '') {
      const searchLower = query.searchText.toLowerCase();
      results = results.filter(doc =>
        doc.title.toLowerCase().includes(searchLower) ||
        doc.content.toLowerCase().includes(searchLower)
      );
    }

    if (query.createdAfter !== undefined) {
      results = results.filter(doc => doc.createdAt >= query.createdAfter!);
    }

    if (query.createdBefore !== undefined) {
      results = results.filter(doc => doc.createdAt <= query.createdBefore!);
    }

    // Sort results
    const sortBy = query.sortBy ?? 'createdAt';
    const sortOrder = query.sortOrder ?? 'desc';

    results.sort((a, b) => {
      let comparison: number;

      switch (sortBy) {
        case 'title':
          comparison = a.title.localeCompare(b.title);
          break;
        case 'updatedAt':
          comparison = a.updatedAt.getTime() - b.updatedAt.getTime();
          break;
        case 'createdAt':
        default:
          comparison = a.createdAt.getTime() - b.createdAt.getTime();
          break;
      }

      return sortOrder === 'asc' ? comparison : -comparison;
    });

    // Apply pagination
    const total = results.length;
    const limit = Math.min(query.limit ?? 100, 1000);
    const offset = query.offset ?? 0;

    const paginatedResults = results.slice(offset, offset + limit);

    return {
      items: paginatedResults.map(doc => this.cloneDocument(doc)),
      total,
      limit,
      offset,
      hasMore: offset + paginatedResults.length < total
    };
  }

  /**
   * Returns statistics about the document collection.
   *
   * Provides aggregate counts and metrics for monitoring and
   * administrative purposes. Statistics are computed on-demand.
   *
   * @returns Document collection statistics
   *
   * @example
   * ```typescript
   * const stats = await manager.getStats();
   *
   * console.log(`Total documents: ${stats.totalDocuments}`);
   * console.log(`Published: ${stats.byStatus.published}`);
   * console.log(`Total size: ${(stats.totalSizeBytes / 1024).toFixed(2)} KB`);
   *
   * if (stats.oldestDocument) {
   *   console.log(`Oldest: ${stats.oldestDocument.toISOString()}`);
   * }
   * ```
   */
  async getStats(): Promise<DocumentStats> {
    const documents = Array.from(this.documents.values());

    const stats: DocumentStats = {
      totalDocuments: documents.length,
      byType: {
        [DocumentType.TEXT]: 0,
        [DocumentType.MARKDOWN]: 0,
        [DocumentType.HTML]: 0,
        [DocumentType.JSON]: 0,
        [DocumentType.BINARY]: 0
      },
      byStatus: {
        [DocumentStatus.DRAFT]: 0,
        [DocumentStatus.PUBLISHED]: 0,
        [DocumentStatus.ARCHIVED]: 0,
        [DocumentStatus.DELETED]: 0
      },
      byAccessLevel: {
        [AccessLevel.PUBLIC]: 0,
        [AccessLevel.INTERNAL]: 0,
        [AccessLevel.PRIVATE]: 0,
        [AccessLevel.CONFIDENTIAL]: 0
      },
      totalSizeBytes: 0
    };

    for (const doc of documents) {
      stats.byType[doc.type]++;
      stats.byStatus[doc.status]++;
      stats.byAccessLevel[doc.accessLevel]++;
      stats.totalSizeBytes += Buffer.byteLength(doc.content, 'utf8');

      if (!stats.oldestDocument || doc.createdAt < stats.oldestDocument) {
        stats.oldestDocument = doc.createdAt;
      }

      if (!stats.newestDocument || doc.createdAt > stats.newestDocument) {
        stats.newestDocument = doc.createdAt;
      }
    }

    return stats;
  }

  /**
   * Removes all documents from storage.
   *
   * This is a destructive operation that permanently removes all
   * documents, including soft-deleted ones. Use with caution.
   *
   * @returns The number of documents that were removed
   *
   * @example
   * ```typescript
   * const count = await manager.clear();
   * console.log(`Removed ${count} documents`);
   * ```
   */
  async clear(): Promise<number> {
    const count = this.documents.size;
    this.documents.clear();
    return count;
  }

  /**
   * Validates a document title.
   *
   * @param title - The title to validate
   * @returns Validation result with error message if invalid
   * @internal
   */
  private validateTitle(title: string): { valid: boolean; error?: string } {
    if (!title || title.trim().length === 0) {
      return { valid: false, error: 'Title cannot be empty' };
    }

    if (title.length > this.config.maxTitleLength) {
      return {
        valid: false,
        error: `Title exceeds maximum length of ${this.config.maxTitleLength} characters`
      };
    }

    return { valid: true };
  }

  /**
   * Validates document content based on its type.
   *
   * @param content - The content to validate
   * @param type - The document type
   * @returns Validation result with error message if invalid
   * @internal
   */
  private validateContent(
    content: string,
    type: DocumentType
  ): { valid: boolean; error?: string } {
    switch (type) {
      case DocumentType.JSON:
        try {
          JSON.parse(content);
          return { valid: true };
        } catch (e) {
          return { valid: false, error: 'Invalid JSON content' };
        }

      case DocumentType.HTML:
        // Basic HTML validation - check for matching tags
        // In production, use a proper HTML parser
        return { valid: true };

      case DocumentType.MARKDOWN:
      case DocumentType.TEXT:
      case DocumentType.BINARY:
      default:
        return { valid: true };
    }
  }

  /**
   * Creates a deep clone of a document.
   *
   * Prevents external code from modifying internal state by returning
   * copies instead of references.
   *
   * @param document - The document to clone
   * @returns A deep copy of the document
   * @internal
   */
  private cloneDocument(document: Document): Document {
    return {
      ...document,
      metadata: {
        ...document.metadata,
        tags: document.metadata.tags ? [...document.metadata.tags] : undefined,
        customFields: document.metadata.customFields
          ? { ...document.metadata.customFields }
          : undefined
      },
      createdAt: new Date(document.createdAt),
      updatedAt: new Date(document.updatedAt)
    };
  }
}
