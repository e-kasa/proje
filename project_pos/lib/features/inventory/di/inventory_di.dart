// Inventory feature DI — providers will be populated in Phase 4
// For now, re-export from the central service_locator
export 'package:project_pos/services/service_locator.dart'
    show
        productServiceProvider,
        brandServiceProvider,
        unitServiceProvider,
        categoryServiceProvider,
        companyCategoryServiceProvider;
