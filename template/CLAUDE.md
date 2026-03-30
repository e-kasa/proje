# CLAUDE.md - AI Assistant Guide

This document provides comprehensive guidance for AI assistants working on this React + TypeScript + Vite project. Last updated: 2025-12-06

## Table of Contents
- [Project Overview](#project-overview)
- [Technology Stack](#technology-stack)
- [Codebase Structure](#codebase-structure)
- [Key Conventions](#key-conventions)
- [Development Workflows](#development-workflows)
- [State Management](#state-management)
- [Routing & Navigation](#routing--navigation)
- [API Integration](#api-integration)
- [Styling Approach](#styling-approach)
- [Important Patterns](#important-patterns)
- [Common Tasks](#common-tasks)
- [AI Assistant Guidelines](#ai-assistant-guidelines)

---

## Project Overview

This is a comprehensive React-based admin dashboard/POS system built with modern web technologies. The application features:
- Multi-module architecture (Sales, Inventory, HRM, Finance, Reports, etc.)
- Token-based authentication with refresh token support
- Redux state management with local storage persistence
- Extensive UI component library integration
- Feature-rich data tables, charts, and forms

**Project Type**: Enterprise Admin Dashboard / POS System
**Primary Language**: TypeScript
**Build Tool**: Vite
**Total Code**: ~3,500 lines of TypeScript/TSX

---

## Technology Stack

### Core Technologies
- **React 19.1.1** - UI framework
- **TypeScript 5.8.3** - Type safety
- **Vite 6.3.6** - Build tool and dev server
- **React Router 7.8.2** - Client-side routing

### State Management
- **Redux Toolkit 2.10.1** - Global state
- **Zustand 5.0.9** - Lightweight state (for forms)
- **React Redux 9.2.0** - React bindings

### UI Libraries & Components
- **Ant Design (antd) 5.27.3** - Primary component library
- **PrimeReact 10.9.7** - Additional UI components
- **React Bootstrap 2.10.10** - Bootstrap components
- **Bootstrap 5.3.8** - CSS framework

### Data Visualization
- **ApexCharts 4.7.0** - Modern charts
- **Chart.js 4.5.0** - Canvas-based charts
- **React ApexCharts 1.7.0** - React wrapper

### Form & Input Utilities
- **react-select 5.10.2** - Enhanced select inputs
- **react-input-mask 2.0.4** - Input masking
- **react-otp-input 3.1.1** - OTP inputs
- **react-phone-number-input 3.4.12** - Phone number handling
- **react-simple-wysiwyg 3.4.1** - WYSIWYG editor
- **Quill 2.0.3** - Rich text editor

### Additional Libraries
- **Axios 1.13.2** - HTTP client
- **Day.js 1.11.18** - Date manipulation
- **Moment 2.30.1** - Date/time library
- **React DnD 16.0.1** - Drag and drop
- **@hello-pangea/dnd 18.0.1** - Drag and drop
- **Leaflet 1.9.4** - Maps

### Development Tools
- **ESLint 9.35.0** - Linting
- **TypeScript ESLint 8.43.0** - TS-specific linting
- **Sass 1.92.1** - CSS preprocessing

---

## Codebase Structure

```
/home/user/template/
├── .git/                           # Git repository
├── dist/                          # Production build output (not ignored!)
├── public/                        # Static assets
├── src/                           # Source code
│   ├── app.router.tsx            # Main router configuration
│   ├── main.tsx                  # Application entry point
│   ├── environment.tsx           # Environment configuration
│   ├── customStyle.scss          # Global custom styles
│   ├── vite-env.d.ts            # Vite type definitions
│   │
│   ├── assets/                   # Static assets
│   │   ├── css/                 # Stylesheets
│   │   ├── fonts/               # Font files
│   │   ├── icons/               # Icon libraries (feather, fontawesome, etc.)
│   │   └── img/                 # Images (avatar, authentication, products, etc.)
│   │
│   ├── components/              # Reusable UI components
│   │   ├── Alert.tsx           # Alert component
│   │   ├── AlertContext.tsx    # Alert context provider
│   │   ├── chip/               # Chip components
│   │   ├── counter/            # Counter components
│   │   ├── data-table/         # DataTable with pagination, search, sort
│   │   ├── date-picker/        # Date picker wrapper
│   │   ├── date-range-picker/  # Date range picker
│   │   ├── delete-modal/       # Delete confirmation modal
│   │   ├── footer/             # Footer component
│   │   ├── header/             # Header component
│   │   ├── layouts/            # Layout components (sidebar variants, theme settings)
│   │   ├── lazy-loading/       # Lazy loading wrapper
│   │   ├── loader/             # Loading spinner
│   │   ├── select/             # Select/multi-select wrappers
│   │   ├── sidebar/            # Sidebar navigation
│   │   ├── table-top-head/     # Table header actions
│   │   ├── texteditor/         # Text editor component
│   │   ├── time-picker/        # Time picker component
│   │   └── tooltip-content/    # Tooltip components
│   │
│   ├── core/                    # Core utilities and configuration
│   │   ├── axiosClient/        # HTTP client (index.ts)
│   │   ├── endpointBuilder.ts  # API endpoint builder
│   │   ├── json/               # Mock/static data files
│   │   │   └── (100+ data files for tables, forms, etc.)
│   │   ├── modals/             # Modal components
│   │   │   ├── applications/   # App-specific modals
│   │   │   ├── coupons/        # Coupon modals
│   │   │   ├── hrm/            # HRM modals
│   │   │   ├── inventory/      # Inventory modals
│   │   │   ├── peoples/        # People modals
│   │   │   ├── sales/          # Sales modals
│   │   │   └── settings/       # Settings modals
│   │   └── redux/              # Redux store configuration
│   │       ├── store.tsx       # Main store (combines all reducers)
│   │       ├── action.tsx      # Actions
│   │       ├── reducer.tsx     # Main reducer
│   │       ├── commonSlice.tsx # Common state slice
│   │       ├── sidebarSlice.tsx # Sidebar state
│   │       ├── themeSettingSlice.tsx # Theme settings
│   │       ├── localStorage.tsx # LocalStorage utilities
│   │       └── initial.value.tsx # Initial state values
│   │
│   ├── feature-module/          # Feature modules (pages/routes)
│   │   ├── feature-module.tsx  # Feature module wrapper
│   │   ├── dashboard/          # Dashboard pages
│   │   ├── inventory/          # Inventory management
│   │   ├── sales/              # Sales module
│   │   ├── purchases/          # Purchase module
│   │   ├── people/             # Customer/supplier management
│   │   ├── hrm/                # Human resources
│   │   ├── finance-accounts/   # Finance & accounting
│   │   ├── stock/              # Stock management
│   │   ├── Reports/            # Various reports
│   │   ├── application/        # Apps (email, chat, calendar, etc.)
│   │   ├── pos/                # Point of Sale
│   │   ├── ecommerce/          # E-commerce pages
│   │   ├── coupons/            # Coupon management
│   │   ├── pages/              # Auth & error pages
│   │   ├── content/            # CMS pages
│   │   ├── settings/           # Settings pages
│   │   ├── super-admin/        # Super admin features
│   │   ├── uiinterface/        # UI components showcase
│   │   └── usermanagement/     # User management
│   │
│   ├── routes/                  # Routing configuration
│   │   ├── all_routes.tsx      # Route path constants
│   │   └── path.tsx            # Route definitions (authRoutes, unAuthRoutes, posPages)
│   │
│   ├── services/                # API services
│   │   ├── authService.ts      # Authentication API calls
│   │   └── productApi.ts       # Product API calls
│   │
│   ├── store/                   # Additional Redux slices
│   │   ├── index.ts            # Store export (separate from core/redux)
│   │   ├── authSlice.ts        # Authentication state
│   │   └── productFormStore.ts # Product form state (Zustand)
│   │
│   ├── types/                   # TypeScript type definitions
│   │   └── images.d.ts         # Image import types
│   │
│   └── utils/                   # Utility functions
│       ├── constants/          # Constants
│       ├── debounce/          # Debounce utility
│       ├── endpointBuilder.ts # Endpoint builder
│       └── imagepath/         # Image path helpers
│
├── package.json                 # Dependencies and scripts
├── tsconfig.json               # TypeScript configuration (project references)
├── tsconfig.app.json           # App TypeScript config
├── tsconfig.node.json          # Node TypeScript config
├── vite.config.ts              # Vite configuration
├── eslint.config.js            # ESLint configuration
├── index.html                  # HTML entry point
├── .gitignore                  # Git ignore rules
└── README.md                   # Project readme
```

---

## Key Conventions

### File Naming
- **Components**: PascalCase (e.g., `AlertContext.tsx`)
- **Utilities**: camelCase (e.g., `endpointBuilder.ts`)
- **Pages/Features**: kebab-case for directories, PascalCase for files
- **Styles**: kebab-case (e.g., `customStyle.scss`)

### Code Organization
- **Feature-based**: Code organized by feature modules (inventory, sales, hrm, etc.)
- **Separation of Concerns**:
  - `components/` - Reusable UI components
  - `feature-module/` - Page-level components and features
  - `core/` - Core utilities, modals, data
  - `services/` - API integration layer
  - `store/` - State management

### Component Structure
- Functional components with hooks
- TypeScript interfaces for props
- React.FC type for components (common pattern in this codebase)
- React.memo for performance optimization (see app.router.tsx:14)

### Import Organization
1. React imports
2. Third-party libraries
3. Local components/utilities
4. Types/interfaces
5. Styles
6. Assets

### TypeScript
- Strict mode enabled
- ESModule interop enabled
- Type definitions in separate `.d.ts` files when needed
- Interface naming: Standard names without `I` prefix

---

## Development Workflows

### Starting Development
```bash
npm run dev          # Start Vite dev server
```

### Building
```bash
npm run build        # TypeScript compile + Vite build
```

### Linting
```bash
npm run lint         # ESLint check
```

### Preview Production Build
```bash
npm run preview      # Preview production build
```

### Important Notes
- **Dist folder is committed** (Note: `# dist` is commented in .gitignore:11)
- Development server runs on Vite's default port
- TypeScript compilation happens before build
- ESLint configured for React hooks and TypeScript

---

## State Management

### Redux Store Architecture

The application uses **two Redux store configurations**:

#### 1. Main Store (`src/core/redux/store.tsx`)
**Primary application store** used in main.tsx

```typescript
// Combined reducers
{
  sidebar: sidebarSlice,        // Sidebar state (collapsed, expanded)
  common: commonSlice,          // Common UI state
  rootReducer: MainReducer,     // Main business logic
  themeSetting: themeSettingSlice, // Theme configuration
  auth: authReducer             // Authentication (from src/store/)
}
```

**Features**:
- Local storage persistence (automatic save/load)
- Logout handler clears all state (`login/logout` action)
- Preloaded state from localStorage

#### 2. Auth Store (`src/store/index.ts`)
**Separate minimal store** (appears unused in main.tsx)

```typescript
// Minimal auth-only store
{
  auth: authReducer
}
```

### Redux Slices

#### Authentication Slice (`src/store/authSlice.ts`)
```typescript
interface AuthState {
  token: string | null;
  user: any | null;
}

// Actions
setCredentials({ accessToken, user })  // Login
logout()                               // Logout
```

- **Token storage**: localStorage
- **Auto-initialization**: Token loaded from localStorage on init

#### Sidebar Slice (`src/core/redux/sidebarSlice.tsx`)
- Controls sidebar expansion/collapse
- Layout variants (collapsed, horizontal, two-column)

#### Common Slice (`src/core/redux/commonSlice.tsx`)
- Shared UI state
- Modal visibility
- Loading states

#### Theme Settings Slice (`src/core/redux/themeSettingSlice.tsx`)
- Theme customization
- Layout preferences
- Color schemes

### Zustand Stores

#### Product Form Store (`src/store/productFormStore.ts`)
- Lightweight form state for product management
- Used for complex form state outside Redux

### State Management Guidelines
1. **Use Redux for**: Global app state, authentication, theme, sidebar
2. **Use Zustand for**: Complex form state, temporary UI state
3. **Use Local State for**: Component-specific state
4. **localStorage**: Automatically synced with Redux store

---

## Routing & Navigation

### Route Configuration

Routes are defined in `src/routes/path.tsx` with three categories:

#### 1. Unauthenticated Routes (`unAuthRoutes`)
- Login, signup, password reset
- Public pages
- No token required

#### 2. Authenticated Routes (`authRoutes`)
- Protected by token check
- Redirect to `/signin` if no token
- Main application features

#### 3. POS Routes (`posPages`)
- Point of Sale pages
- Also token-protected

### Router Structure (`src/app.router.tsx`)

```typescript
// Conditional rendering based on token
token ? (
  <PageComponent />
) : (
  <Navigate to="/signin" replace />
)
```

**Key Features**:
- Token-based protection from Redux store
- React.memo optimization for route rendering
- BrowserRouter with configurable basename
- Nested routes under FeatureModule layout

### Route Path Constants

Defined in `src/routes/all_routes.tsx`:
- Centralized route path definitions
- Type-safe route references
- Easy maintenance

### Navigation Patterns
1. **Protected Routes**: Check `token` in Redux state
2. **Redirects**: Use `<Navigate>` component
3. **Nested Routes**: Feature modules wrap child routes
4. **Base Path**: Configured via `environment.tsx` (`base_path = "/"`)

---

## API Integration

### HTTP Client (`src/core/axiosClient/index.ts`)

Custom `HttpClient` class with Axios:

```typescript
class HttpClient {
  baseURL: 'http://localhost:80808/'  // Default API URL
  timeout: 15000                       // 15 second timeout
}
```

#### Request Interceptor
- Automatically adds `Authorization: Bearer <token>` header
- Token retrieved from Redux store

#### Response Interceptor
- **401 Handling**: Automatic token refresh
- **Refresh Flow**:
  1. Detect 401 error
  2. Call `/auth/refresh` endpoint
  3. Update token in Redux
  4. Retry original request
  5. If refresh fails, dispatch logout

#### HTTP Methods
```typescript
api.get<T>(url, params?)
api.post<T>(url, data?)
api.put<T>(url, data?)
api.delete(url)
```

#### Custom Headers
- `X_USER_INFO_HEADER`: URL-encoded user info (hardcoded in POST)
  ```json
  {
    "userInformation": {
      "userId": "testUser",
      "userName": "test",
      "displayName": "Test Kullanıcı",
      "sessionId": "ABC123"
    },
    "roles": ["ADMIN", "USER"]
  }
  ```

### Service Layer Pattern

#### AuthService (`src/services/authService.ts`)
```typescript
AuthService.login({ username, password })
// → POST security/authenticate
```

#### ProductApi (`src/services/productApi.ts`)
- Product CRUD operations

### API Integration Best Practices
1. **Use service layer**: Don't call `api` directly in components
2. **Type responses**: Use TypeScript generics `api.get<ResponseType>`
3. **Handle errors**: Wrap in try-catch or use error boundaries
4. **Token refresh**: Automatic, handled by interceptor
5. **Custom headers**: Add in interceptor, not per-request

### Environment Configuration

**Base URL**: `src/core/axiosClient/index.ts:6` (hardcoded)
**Image Path**: `src/environment.tsx:2` (configured as `'/'`)

---

## Styling Approach

### CSS Architecture

#### 1. Global Styles (`src/customStyle.scss`)
- 36KB of custom SCSS
- Global overrides and utilities
- Main stylesheet imported in `main.tsx:17`

#### 2. Component Libraries
Loaded in order (see `main.tsx`):
1. Tabler Icons CSS
2. PrimeReact theme (`saga-blue`)
3. PrimeReact core CSS
4. Prime Icons
5. Feather Icons
6. Slick Carousel
7. Bootstrap 5
8. Boxicons
9. Font Awesome

#### 3. Icon Libraries
Multiple icon systems available:
- **Feather Icons** (`src/assets/icons/feather/`)
- **Bootstrap Icons** (`src/assets/icons/bootstrap/`)
- **Font Awesome** (`src/assets/icons/fontawesome/`)
- **Boxicons** (`src/assets/icons/boxicons/`)
- **Remix Icons** (`src/assets/icons/remix/`)
- **Tabler Icons** (`src/assets/icons/tabler-icons/`)

### Styling Patterns

#### Component Styling
- **Primary**: Bootstrap classes
- **Enhanced**: Ant Design/PrimeReact component props
- **Custom**: SCSS in `customStyle.scss`
- **No CSS Modules**: Not used in this project

#### Responsive Design
- Bootstrap breakpoints
- Mobile-first approach
- Responsive utilities from Bootstrap

#### Theme System
- Redux-managed theme settings
- Multiple layout variants (collapsed, horizontal, two-column)
- Theme switcher in `components/layouts/themeSettings.tsx`

### Styling Guidelines
1. **Use existing libraries**: Prefer Bootstrap/Ant Design classes
2. **Custom styles**: Add to `customStyle.scss`
3. **Icons**: Use react-feather or Font Awesome React components
4. **Avoid inline styles**: Unless dynamic values required
5. **Responsive**: Test with Bootstrap breakpoints (sm, md, lg, xl)

---

## Important Patterns

### 1. Lazy Loading Pattern

**LazyWrapper Component** (`src/components/lazy-loading/index.tsx`)
- Wraps entire app in main.tsx:35
- Provides loading fallback
- Code splitting support

### 2. Modal Pattern

**Centralized Modals** (`src/core/modals/`)
- Modals organized by feature (inventory, sales, hrm, settings)
- Reusable modal components
- Consistent modal structure

**Common Modals**:
- Add/Edit modals (e.g., `addbrand.tsx`, `editcurrency.tsx`)
- Delete confirmation (`src/components/delete-modal/`)
- Feature-specific modals in `core/modals/[feature]/`

### 3. Data Table Pattern

**CommonDataTable** (`src/components/data-table/index.tsx`)
- Pagination (`custom-paginator.tsx`)
- Search (`search.tsx`)
- Sorting (`sort-icon.tsx`)
- Reusable across all list pages

**Data Sources**:
- Mock data in `src/core/json/` (100+ files)
- API integration ready

### 4. Alert/Notification Pattern

**AlertContext** (`src/components/AlertContext.tsx`)
- Global alert provider
- Wraps app in main.tsx:27
- Centralized notification system

### 5. Date/Time Pattern

**Consistent Date Handling**:
- Day.js for manipulation
- Moment.js for legacy support
- Common date pickers (`components/date-picker/`, `date-range-picker/`)
- Bootstrap daterangepicker integration

### 6. Select/Dropdown Pattern

**Enhanced Selects**:
- `CommonSelect` - Single select wrapper
- `MultiSelect` - Multi-select wrapper
- react-select integration
- Consistent styling and behavior

### 7. Form Pattern

**Form Libraries**:
- React Hook Form (implied by patterns)
- Input masking (react-input-mask)
- Phone number validation (react-phone-number-input)
- OTP inputs (react-otp-input)

**WYSIWYG Editors**:
- react-simple-wysiwyg
- Quill editor
- TextEditor component (`components/texteditor/`)

### 8. Drag & Drop Pattern

**Multiple DnD Libraries**:
- @hello-pangea/dnd (modern)
- react-dnd (HTML5 backend)
- Dragula (legacy)

### 9. Feature Module Pattern

**Feature Organization**:
```typescript
// feature-module/
//   ├── [feature]/
//   │   ├── index.tsx (main page)
//   │   ├── [feature]-list.tsx (list view)
//   │   ├── [feature]-detail.tsx (detail view)
//   │   └── [feature]-form.tsx (add/edit form)
```

---

## Common Tasks

### Adding a New Feature Module

1. **Create feature directory**:
   ```
   src/feature-module/my-feature/
   ```

2. **Create main component**:
   ```typescript
   // my-feature/index.tsx
   import React from 'react';

   const MyFeature: React.FC = () => {
     return <div>My Feature</div>;
   };

   export default MyFeature;
   ```

3. **Add routes**:
   ```typescript
   // src/routes/path.tsx
   {
     id: 'my-feature',
     path: '/my-feature',
     element: <MyFeature />
   }
   ```

4. **Add to sidebar** (`src/core/json/siderbar_data.ts`)

5. **Create modals if needed** (`src/core/modals/my-feature/`)

### Adding an API Endpoint

1. **Create service**:
   ```typescript
   // src/services/myFeatureApi.ts
   import { api } from '../core/axiosClient';

   export const MyFeatureService = {
     getAll: () => api.get('my-feature'),
     getById: (id: string) => api.get(`my-feature/${id}`),
     create: (data: any) => api.post('my-feature', data),
     update: (id: string, data: any) => api.put(`my-feature/${id}`, data),
     delete: (id: string) => api.delete(`my-feature/${id}`)
   };
   ```

2. **Use in component**:
   ```typescript
   import { MyFeatureService } from '@/services/myFeatureApi';

   const data = await MyFeatureService.getAll();
   ```

### Adding a Redux Slice

1. **Create slice**:
   ```typescript
   // src/store/myFeatureSlice.ts
   import { createSlice, PayloadAction } from '@reduxjs/toolkit';

   interface MyFeatureState {
     items: any[];
     loading: boolean;
   }

   const initialState: MyFeatureState = {
     items: [],
     loading: false
   };

   const myFeatureSlice = createSlice({
     name: 'myFeature',
     initialState,
     reducers: {
       setItems: (state, action: PayloadAction<any[]>) => {
         state.items = action.payload;
       }
     }
   });

   export const { setItems } = myFeatureSlice.actions;
   export default myFeatureSlice.reducer;
   ```

2. **Add to store**:
   ```typescript
   // src/core/redux/store.tsx
   import myFeatureReducer from '../../store/myFeatureSlice';

   const combinedReducer = combineReducers({
     // ... existing reducers
     myFeature: myFeatureReducer
   });
   ```

### Adding a Modal

1. **Create modal component**:
   ```typescript
   // src/core/modals/my-feature/addItem.tsx
   import React from 'react';
   import { Modal } from 'react-bootstrap';

   interface AddItemModalProps {
     show: boolean;
     onHide: () => void;
     onSave: (data: any) => void;
   }

   const AddItemModal: React.FC<AddItemModalProps> = ({ show, onHide, onSave }) => {
     return (
       <Modal show={show} onHide={onHide}>
         <Modal.Header closeButton>
           <Modal.Title>Add Item</Modal.Title>
         </Modal.Header>
         <Modal.Body>
           {/* Form fields */}
         </Modal.Body>
         <Modal.Footer>
           <button onClick={onHide}>Cancel</button>
           <button onClick={() => onSave({})}>Save</button>
         </Modal.Footer>
       </Modal>
     );
   };

   export default AddItemModal;
   ```

2. **Use in page**:
   ```typescript
   import AddItemModal from '@/core/modals/my-feature/addItem';

   const [showModal, setShowModal] = useState(false);

   <AddItemModal
     show={showModal}
     onHide={() => setShowModal(false)}
     onSave={handleSave}
   />
   ```

### Adding a Reusable Component

1. **Create in components directory**:
   ```
   src/components/my-component/
   ├── index.tsx
   └── styles.scss (if needed)
   ```

2. **Export from index**:
   ```typescript
   export { default as MyComponent } from './components/my-component';
   ```

### Working with Icons

**React Feather** (Recommended):
```typescript
import { User, Settings, LogOut } from 'react-feather';

<User size={20} />
```

**Font Awesome React**:
```typescript
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUser } from '@fortawesome/free-solid-svg-icons';

<FontAwesomeIcon icon={faUser} />
```

**Icon Classes** (CSS approach):
```typescript
<i className="fe fe-user"></i>  // Feather
<i className="fa fa-user"></i>  // Font Awesome
<i className="bx bx-user"></i>  // Boxicons
```

---

## AI Assistant Guidelines

### Code Analysis Priorities
1. **Check authentication flow** before modifying protected routes
2. **Verify Redux store structure** - note dual store setup
3. **Review existing patterns** in similar feature modules
4. **Check component library** - prefer Ant Design/PrimeReact components
5. **Examine mock data** in `core/json/` for data structure patterns

### When Making Changes

#### DO:
✅ Follow existing file organization patterns
✅ Use TypeScript interfaces for all props and data structures
✅ Add new routes to `src/routes/path.tsx`
✅ Create modals in appropriate `core/modals/[feature]/` directory
✅ Use service layer for API calls, not direct axios
✅ Check if component exists in UI libraries before creating custom
✅ Update Redux state through actions, never mutate directly
✅ Use React.FC type for components (codebase convention)
✅ Import icons from react-feather or Font Awesome React
✅ Test token refresh flow if modifying auth
✅ Preserve existing styling approach (Bootstrap + custom SCSS)

#### DON'T:
❌ Bypass authentication checks
❌ Call API directly from components
❌ Create duplicate components that exist in UI libraries
❌ Modify core Redux store structure without understanding dual-store setup
❌ Add new CSS methodologies (CSS Modules, CSS-in-JS)
❌ Remove dist folder from git (it's intentionally committed)
❌ Hardcode API URLs in components
❌ Use class components (codebase uses functional only)
❌ Create inline styles without good reason
❌ Modify localStorage persistence without understanding impact

### Common Pitfalls to Avoid

1. **Dual Redux Stores**:
   - Main store in `core/redux/store.tsx` (used in app)
   - Separate store in `store/index.ts` (appears unused)
   - Use main store for new features

2. **Token Management**:
   - Token stored in Redux AND localStorage
   - Refresh token logic in axios interceptor
   - Logout clears both Redux and localStorage

3. **Import Paths**:
   - No path aliases configured
   - Use relative imports
   - Watch for deep nesting

4. **Component Libraries**:
   - Multiple UI libraries (Ant Design, PrimeReact, Bootstrap)
   - Check all three before creating custom components
   - Prefer Ant Design for new components

5. **Date Libraries**:
   - Both Day.js and Moment.js available
   - Prefer Day.js for new code (smaller bundle)

6. **Styling Conflicts**:
   - Multiple CSS frameworks loaded
   - Specificity issues possible
   - Test thoroughly across modules

### Testing Checklist

Before submitting changes:
- [ ] TypeScript compilation passes (`npm run build`)
- [ ] ESLint passes (`npm run lint`)
- [ ] Authentication flow works (login/logout)
- [ ] Protected routes redirect when logged out
- [ ] Token refresh works on 401
- [ ] Redux state persists in localStorage
- [ ] Modals open/close properly
- [ ] Data tables paginate, search, sort
- [ ] Responsive design works (mobile, tablet, desktop)
- [ ] Icons display correctly
- [ ] Forms validate properly
- [ ] API calls use service layer

### Debugging Tips

1. **Redux DevTools**: Check state in browser extension
2. **Network Tab**: Monitor API calls and token refresh
3. **localStorage**: Inspect `redux` key for persisted state
4. **React DevTools**: Check component hierarchy and props
5. **Console Errors**: Watch for PropTypes warnings from libraries
6. **Bundle Size**: Large number of dependencies, watch imports

### Performance Considerations

1. **Lazy Loading**: Already implemented via LazyWrapper
2. **Code Splitting**: Available through React.lazy if needed
3. **Memo**: Use React.memo for expensive renders
4. **Virtual Scrolling**: Consider for large data tables
5. **Image Optimization**: Check image sizes in assets/img/
6. **Bundle Analysis**: Run Vite build analysis if needed

### Security Considerations

1. **Token Storage**: Using localStorage (consider security implications)
2. **XSS Prevention**: React's default escaping should be maintained
3. **API Security**: Token in headers (not URL parameters)
4. **User Input**: Validate on both client and server
5. **Sensitive Data**: Don't log tokens or user credentials
6. **CORS**: Backend must configure allowed origins

### Documentation Standards

When adding features, update:
1. This CLAUDE.md file (if architectural changes)
2. Code comments for complex logic
3. TypeScript interfaces (self-documenting)
4. README.md if user-facing changes

### Questions to Ask Before Coding

1. Does this feature already exist in a UI library?
2. Is there a similar pattern in another feature module?
3. Should this be in Redux or component state?
4. Does this need authentication?
5. Is there mock data I should reference in `core/json/`?
6. Which modal pattern should I follow?
7. Does this affect the build/bundle size significantly?

---

## Quick Reference

### Key Files
| File | Purpose |
|------|---------|
| `src/main.tsx` | App entry point |
| `src/app.router.tsx` | Routing configuration |
| `src/core/redux/store.tsx` | Main Redux store |
| `src/core/axiosClient/index.ts` | HTTP client |
| `src/environment.tsx` | Environment config |
| `src/routes/path.tsx` | Route definitions |
| `src/customStyle.scss` | Global styles |

### Key Directories
| Directory | Purpose |
|-----------|---------|
| `src/components/` | Reusable UI components |
| `src/feature-module/` | Page components by feature |
| `src/core/modals/` | Modal components |
| `src/core/json/` | Mock/static data |
| `src/services/` | API service layer |
| `src/store/` | Redux slices |
| `src/utils/` | Utility functions |
| `src/assets/` | Static assets |

### Environment Variables
No `.env` file detected. Configuration in:
- `src/environment.tsx` - base_path, image_path
- `src/core/axiosClient/index.ts:6` - API baseURL

### NPM Scripts
```bash
npm run dev      # Start dev server
npm run build    # Build for production
npm run lint     # Run ESLint
npm run preview  # Preview production build
```

### TypeScript Configuration
- **Project**: References (`tsconfig.json`)
- **App**: `tsconfig.app.json` (strict mode)
- **Node**: `tsconfig.node.json` (for Vite config)

### Port Configuration
Default Vite port (check `vite.config.ts` for overrides)

---

## Change Log

### 2025-12-06 - Initial Creation
- Comprehensive codebase analysis
- Documented all major patterns and conventions
- Created complete reference guide for AI assistants
- Analyzed ~3,500 lines of TypeScript/TSX code
- Documented dual Redux store architecture
- Mapped all feature modules and directory structure

---

## Additional Resources

### Official Documentation
- [React Documentation](https://react.dev/)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)
- [Vite Documentation](https://vitejs.dev/)
- [Redux Toolkit Documentation](https://redux-toolkit.js.org/)
- [Ant Design Documentation](https://ant.design/)
- [PrimeReact Documentation](https://primereact.org/)

### Codebase-Specific
- Review similar feature modules for patterns
- Check `core/json/` for data structure examples
- Examine existing modals for modal patterns
- Study `components/` for reusable component patterns

---

**Last Updated**: 2025-12-06
**Maintainer**: AI Assistant
**Project Status**: Active Development
