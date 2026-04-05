import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project_pos/core/api/api_client.dart';
import 'package:project_pos/services/product_service.dart';

// ---- Mocks ----

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProductService productService;

  setUp(() {
    mockApiClient = MockApiClient();
    productService = ProductService(mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Wraps raw product data in the paginated envelope the backend returns.
  Map<String, dynamic> _pagedEnvelope(List<Map<String, dynamic>> products) {
    return {
      'data': {
        'content': products,
        'totalElements': products.length,
        'totalPages': 1,
      },
    };
  }

  /// A minimal product payload as the backend would return it.
  Map<String, dynamic> _sampleRawProduct({
    String id = 'prod-1',
    String name = 'Brake Pad',
    double basePrice = 150.0,
    String status = 'ACTIVE',
  }) {
    return {
      'id': id,
      'name': name,
      'slug': 'brake-pad',
      'description': 'High quality brake pad',
      'brand': 'Bosch',
      'categoryId': 'cat-1',
      'basePrice': basePrice,
      'status': status,
      'variants': [
        {
          'id': 'var-1',
          'sku': 'BP-001',
          'barcodes': [
            {'barcodeCode': '1234567890123', 'isPrimary': true},
          ],
          'inventory': {
            'physicalQuantity': 42,
            'minStockLevel': 5,
            'warehouseCode': 'WH-01',
            'warehouseId': 'wh-1',
            'storeId': 'store-1',
          },
        },
      ],
    };
  }

  // ---------------------------------------------------------------------------
  // getProducts
  // ---------------------------------------------------------------------------

  group('getProducts', () {
    test('calls correct API path and returns mapped products', () async {
      final raw = _sampleRawProduct();
      final envelope = _pagedEnvelope([raw]);

      when(() => mockApiClient.get<dynamic>(
            'product/api/v1/products',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: envelope,
            statusCode: 200,
            requestOptions: RequestOptions(path: 'product/api/v1/products'),
          ));

      final products = await productService.getProducts();

      expect(products, hasLength(1));
      expect(products.first['id'], 'prod-1');
      expect(products.first['name'], 'Brake Pad');
      expect(products.first['sellingPrice'], 150.0);
      expect(products.first['stock'], 42);
      expect(products.first['isActive'], true);
      expect(products.first['barcode'], '1234567890123');

      verify(() => mockApiClient.get<dynamic>(
            'product/api/v1/products',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('maps PASSIVE status to isActive=false', () async {
      final raw = _sampleRawProduct(status: 'PASSIVE');
      final envelope = _pagedEnvelope([raw]);

      when(() => mockApiClient.get<dynamic>(
            'product/api/v1/products',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: envelope,
            statusCode: 200,
            requestOptions: RequestOptions(path: 'product/api/v1/products'),
          ));

      final products = await productService.getProducts();
      expect(products.first['isActive'], false);
    });

    test('returns empty list on API error', () async {
      when(() => mockApiClient.get<dynamic>(
            'product/api/v1/products',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(Exception('Network error'));

      final products = await productService.getProducts();
      expect(products, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getProducts with search
  // ---------------------------------------------------------------------------

  group('getProducts with search', () {
    test('uses search endpoint when search query is provided', () async {
      final raw = _sampleRawProduct(name: 'Oil Filter');
      final envelope = _pagedEnvelope([raw]);

      when(() => mockApiClient.get<dynamic>(
            'product/api/v1/products/search',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: envelope,
            statusCode: 200,
            requestOptions:
                RequestOptions(path: 'product/api/v1/products/search'),
          ));

      final products = await productService.getProducts(search: 'oil');

      verify(() => mockApiClient.get<dynamic>(
            'product/api/v1/products/search',
            queryParameters: {
              'keyword': 'oil',
              'page': 0,
              'size': 50,
            },
            options: any(named: 'options'),
          )).called(1);

      expect(products, hasLength(1));
      expect(products.first['name'], 'Oil Filter');
    });
  });

  // ---------------------------------------------------------------------------
  // createProduct
  // ---------------------------------------------------------------------------

  group('createProduct', () {
    test('sends POST with correct payload and returns mapped product',
        () async {
      final payload = {
        'name': 'New Brake Pad',
        'basePrice': 200.0,
      };
      final responseRaw = _sampleRawProduct(
        id: 'prod-new',
        name: 'New Brake Pad',
        basePrice: 200.0,
      );

      when(() => mockApiClient.post<dynamic>(
            'product/api/v1/products',
            data: payload,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {'data': responseRaw},
            statusCode: 201,
            requestOptions: RequestOptions(path: 'product/api/v1/products'),
          ));

      final result = await productService.createProduct(payload);

      expect(result['id'], 'prod-new');
      expect(result['name'], 'New Brake Pad');
      expect(result['sellingPrice'], 200.0);

      verify(() => mockApiClient.post<dynamic>(
            'product/api/v1/products',
            data: payload,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('rethrows on API error', () async {
      when(() => mockApiClient.post<dynamic>(
            'product/api/v1/products',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(Exception('Server error'));

      expect(
        () => productService.createProduct({'name': 'Fail'}),
        throwsException,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // deleteProduct
  // ---------------------------------------------------------------------------

  group('deleteProduct', () {
    test('calls DELETE on correct path', () async {
      when(() => mockApiClient.delete<dynamic>(
            'product/api/v1/products/prod-1',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: null,
            statusCode: 204,
            requestOptions:
                RequestOptions(path: 'product/api/v1/products/prod-1'),
          ));

      await productService.deleteProduct('prod-1');

      verify(() => mockApiClient.delete<dynamic>(
            'product/api/v1/products/prod-1',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('does not rethrow on delete error (logs instead)', () async {
      when(() => mockApiClient.delete<dynamic>(
            'product/api/v1/products/prod-1',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(Exception('Not found'));

      // deleteProduct catches and logs — should not throw
      await productService.deleteProduct('prod-1');
    });
  });

  // ---------------------------------------------------------------------------
  // getProductById
  // ---------------------------------------------------------------------------

  group('getProductById', () {
    test('calls GET with id and returns mapped product', () async {
      final raw = _sampleRawProduct(id: 'prod-42');

      when(() => mockApiClient.get<dynamic>(
            'product/api/v1/products/prod-42',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            data: {'data': raw},
            statusCode: 200,
            requestOptions:
                RequestOptions(path: 'product/api/v1/products/prod-42'),
          ));

      final product = await productService.getProductById('prod-42');

      expect(product['id'], 'prod-42');
      expect(product['name'], 'Brake Pad');

      verify(() => mockApiClient.get<dynamic>(
            'product/api/v1/products/prod-42',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('returns empty map on error', () async {
      when(() => mockApiClient.get<dynamic>(
            'product/api/v1/products/bad-id',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          )).thenThrow(Exception('Not found'));

      final result = await productService.getProductById('bad-id');
      expect(result, isEmpty);
    });
  });
}
