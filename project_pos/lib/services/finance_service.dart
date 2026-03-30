import '../core/api/api_client.dart';

/// Finance Service - Gelir/Gider yönetimi
class FinanceService {
  /// Development mode - uses mock data when API is unavailable
  static const bool useMockData = true;
  final ApiClient _apiClient;

  FinanceService(this._apiClient);

  // Mock data for expenses
  static final List<Map<String, dynamic>> _mockExpenses = [
    {
      'id': 1,
      'type': 'expense',
      'category': 'Kira',
      'categoryIcon': '🏢',
      'amount': 15000,
      'currency': 'TRY',
      'description': 'Mağaza kirası - Ocak 2025',
      'date': '2025-01-01',
      'paymentMethod': 'Banka Transferi',
      'vendor': 'Emlak Yönetimi A.Ş.',
      'invoiceNumber': 'INV-2025-001',
      'status': 'paid', // paid, pending, cancelled
      'createdBy': 'Admin',
      'createdAt': '2025-01-01T10:00:00',
    },
    {
      'id': 2,
      'type': 'expense',
      'category': 'Maaşlar',
      'categoryIcon': '👥',
      'amount': 45000,
      'currency': 'TRY',
      'description': 'Personel maaşları - Ocak 2025',
      'date': '2025-01-05',
      'paymentMethod': 'Banka Transferi',
      'vendor': 'Çalışanlar',
      'status': 'paid',
      'createdBy': 'Admin',
      'createdAt': '2025-01-05T14:30:00',
    },
    {
      'id': 3,
      'type': 'expense',
      'category': 'Elektrik',
      'categoryIcon': '⚡',
      'amount': 3500,
      'currency': 'TRY',
      'description': 'Elektrik faturası - Aralık 2024',
      'date': '2025-01-10',
      'paymentMethod': 'Otomatik Ödeme',
      'vendor': 'AYEDAŞ',
      'invoiceNumber': 'ELK-2024-12',
      'status': 'paid',
      'createdBy': 'System',
      'createdAt': '2025-01-10T09:15:00',
    },
    {
      'id': 4,
      'type': 'expense',
      'category': 'İnternet',
      'categoryIcon': '🌐',
      'amount': 500,
      'currency': 'TRY',
      'description': 'İnternet aboneliği',
      'date': '2025-01-15',
      'paymentMethod': 'Kredi Kartı',
      'vendor': 'Türk Telekom',
      'status': 'pending',
      'createdBy': 'Admin',
      'createdAt': '2025-01-15T16:00:00',
    },
    {
      'id': 5,
      'type': 'expense',
      'category': 'Malzeme',
      'categoryIcon': '📦',
      'amount': 12000,
      'currency': 'TRY',
      'description': 'Ofis malzemeleri ve demirbaş',
      'date': '2025-01-20',
      'paymentMethod': 'Nakit',
      'vendor': 'Kırtasiye Dünyası',
      'invoiceNumber': 'KRT-2025-045',
      'status': 'paid',
      'createdBy': 'Admin',
      'createdAt': '2025-01-20T11:20:00',
    },
  ];

  // Mock data for revenues
  static final List<Map<String, dynamic>> _mockRevenues = [
    {
      'id': 1,
      'type': 'revenue',
      'category': 'Satış Geliri',
      'categoryIcon': '💰',
      'amount': 125000,
      'currency': 'TRY',
      'description': 'Perakende satış geliri - Hafta 1',
      'date': '2025-01-07',
      'paymentMethod': 'Karma',
      'source': 'Mağaza Satışları',
      'status': 'received',
      'createdBy': 'System',
      'createdAt': '2025-01-07T18:00:00',
    },
    {
      'id': 2,
      'type': 'revenue',
      'category': 'Toptan Satış',
      'categoryIcon': '🏪',
      'amount': 85000,
      'currency': 'TRY',
      'description': 'Toptan müşteri siparişi',
      'date': '2025-01-12',
      'paymentMethod': 'Banka Transferi',
      'source': 'ABC Ltd. Şti.',
      'status': 'received',
      'createdBy': 'Admin',
      'createdAt': '2025-01-12T15:30:00',
    },
    {
      'id': 3,
      'type': 'revenue',
      'category': 'Online Satış',
      'categoryIcon': '🌐',
      'amount': 32000,
      'currency': 'TRY',
      'description': 'E-ticaret platformu satışları',
      'date': '2025-01-15',
      'paymentMethod': 'Kredi Kartı',
      'source': 'Website',
      'status': 'received',
      'createdBy': 'System',
      'createdAt': '2025-01-15T20:00:00',
    },
  ];

  // Get all expenses
  Future<List<Map<String, dynamic>>> getExpenses({
    String? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      var expenses = List<Map<String, dynamic>>.from(_mockExpenses);

      if (category != null && category.isNotEmpty) {
        expenses = expenses.where((e) => e['category'] == category).toList();
      }

      if (status != null) {
        expenses = expenses.where((e) => e['status'] == status).toList();
      }

      if (startDate != null) {
        expenses = expenses.where((e) {
          final date = DateTime.parse(e['date']);
          return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
        }).toList();
      }

      if (endDate != null) {
        expenses = expenses.where((e) {
          final date = DateTime.parse(e['date']);
          return date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        }).toList();
      }

      // Sort by date descending
      expenses.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

      return expenses;
    }

    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('api/finance/expenses', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return _mockExpenses;
    }
  }

  // Get all revenues
  Future<List<Map<String, dynamic>>> getRevenues({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      var revenues = List<Map<String, dynamic>>.from(_mockRevenues);

      if (category != null && category.isNotEmpty) {
        revenues = revenues.where((r) => r['category'] == category).toList();
      }

      if (startDate != null) {
        revenues = revenues.where((r) {
          final date = DateTime.parse(r['date']);
          return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
        }).toList();
      }

      if (endDate != null) {
        revenues = revenues.where((r) {
          final date = DateTime.parse(r['date']);
          return date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        }).toList();
      }

      // Sort by date descending
      revenues.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

      return revenues;
    }

    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get('api/finance/revenues', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return _mockRevenues;
    }
  }

  // Get single expense by ID
  Future<Map<String, dynamic>> getExpenseById(int id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockExpenses.firstWhere(
        (e) => e['id'] == id,
        orElse: () => {},
      );
    }

    try {
      final response = await _apiClient.get('api/finance/expenses/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      return _mockExpenses.firstWhere(
        (e) => e['id'] == id,
        orElse: () => {},
      );
    }
  }

  // Create new expense
  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newExpense = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'type': 'expense',
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _mockExpenses.add(newExpense);
      return newExpense;
    }

    try {
      final response = await _apiClient.post('api/finance/expenses', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      final newExpense = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'type': 'expense',
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _mockExpenses.add(newExpense);
      return newExpense;
    }
  }

  // Create new revenue
  Future<Map<String, dynamic>> createRevenue(Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newRevenue = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'type': 'revenue',
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _mockRevenues.add(newRevenue);
      return newRevenue;
    }

    try {
      final response = await _apiClient.post('api/finance/revenues', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      final newRevenue = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'type': 'revenue',
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _mockRevenues.add(newRevenue);
      return newRevenue;
    }
  }

  // Update expense
  Future<Map<String, dynamic>> updateExpense(int id, Map<String, dynamic> data) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      final index = _mockExpenses.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        _mockExpenses[index] = {..._mockExpenses[index], ...data};
        return _mockExpenses[index];
      }
      return {};
    }

    try {
      final response = await _apiClient.put('api/finance/expenses/$id', data: data);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      final index = _mockExpenses.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        _mockExpenses[index] = {..._mockExpenses[index], ...data};
        return _mockExpenses[index];
      }
      return {};
    }
  }

  // Delete expense
  Future<bool> deleteExpense(int id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockExpenses.removeWhere((e) => e['id'] == id);
      return true;
    }

    try {
      await _apiClient.delete('api/finance/expenses/$id');
      return true;
    } catch (e) {
      _mockExpenses.removeWhere((e) => e['id'] == id);
      return true;
    }
  }

  // Delete revenue
  Future<bool> deleteRevenue(int id) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockRevenues.removeWhere((r) => r['id'] == id);
      return true;
    }

    try {
      await _apiClient.delete('api/finance/revenues/$id');
      return true;
    } catch (e) {
      _mockRevenues.removeWhere((r) => r['id'] == id);
      return true;
    }
  }

  // Get financial summary
  Future<Map<String, dynamic>> getSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));

      var expenses = List<Map<String, dynamic>>.from(_mockExpenses);
      var revenues = List<Map<String, dynamic>>.from(_mockRevenues);

      if (startDate != null) {
        expenses = expenses.where((e) {
          final date = DateTime.parse(e['date']);
          return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
        }).toList();
        revenues = revenues.where((r) {
          final date = DateTime.parse(r['date']);
          return date.isAfter(startDate) || date.isAtSameMomentAs(startDate);
        }).toList();
      }

      if (endDate != null) {
        expenses = expenses.where((e) {
          final date = DateTime.parse(e['date']);
          return date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        }).toList();
        revenues = revenues.where((r) {
          final date = DateTime.parse(r['date']);
          return date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        }).toList();
      }

      final totalExpenses = expenses.fold<double>(
        0,
        (sum, e) => sum + (e['amount'] as num).toDouble(),
      );

      final totalRevenues = revenues.fold<double>(
        0,
        (sum, r) => sum + (r['amount'] as num).toDouble(),
      );

      return {
        'totalExpenses': totalExpenses,
        'totalRevenues': totalRevenues,
        'netIncome': totalRevenues - totalExpenses,
        'expenseCount': expenses.length,
        'revenueCount': revenues.length,
        'expensesByCategory': _groupByCategory(expenses),
        'revenuesByCategory': _groupByCategory(revenues),
      };
    }

    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.get('api/finance/summary', queryParameters: queryParams);
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  // Get expense categories
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      return [
        {'id': 1, 'name': 'Kira', 'icon': '🏢'},
        {'id': 2, 'name': 'Maaşlar', 'icon': '👥'},
        {'id': 3, 'name': 'Elektrik', 'icon': '⚡'},
        {'id': 4, 'name': 'Su', 'icon': '💧'},
        {'id': 5, 'name': 'İnternet', 'icon': '🌐'},
        {'id': 6, 'name': 'Telefon', 'icon': '📞'},
        {'id': 7, 'name': 'Malzeme', 'icon': '📦'},
        {'id': 8, 'name': 'Pazarlama', 'icon': '📢'},
        {'id': 9, 'name': 'Bakım Onarım', 'icon': '🔧'},
        {'id': 10, 'name': 'Diğer', 'icon': '📋'},
      ];
    }

    try {
      final response = await _apiClient.get('api/finance/expense-categories');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // Helper: Group by category
  Map<String, double> _groupByCategory(List<Map<String, dynamic>> items) {
    final Map<String, double> grouped = {};

    for (final item in items) {
      final category = item['category'] as String;
      final amount = (item['amount'] as num).toDouble();

      grouped[category] = (grouped[category] ?? 0) + amount;
    }

    return grouped;
  }
}
