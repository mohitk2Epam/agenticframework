# LWC Naming Conventions

## Component Names

- Use **camelCase** for component folder and file names: `accountCard`, `orderLineItem`
- Prefix with a functional group when part of a feature: `billingInvoiceList`, `billingPaymentForm`
- Never use generic names: avoid `dataTable`, `modalComponent`, `customList`
- Component name should describe what it renders, not how: `contactSummary` (good) vs `contactThreeColumnLayout` (bad)

## File Names

- All files in the bundle must match the component name:
  - `myComponent.js`, `myComponent.html`, `myComponent.css`, `myComponent.js-meta.xml`
- Test files: `__tests__/myComponent.test.js`
- No extra files with unrelated names in the bundle root

## JavaScript

### Variables
- **camelCase** for all variables: `accountName`, `isLoading`, `selectedItems`
- Boolean variables prefixed with `is`, `has`, `can`, `should`: `isVisible`, `hasError`, `canEdit`
- Avoid single-letter names except in short loops (`i`, `j`)
- Avoid abbreviations unless universally understood: `btn` (no) → `button` (yes), `msg` (no) → `message` (yes), `id` (ok), `url` (ok)

### Methods
- **camelCase**, verb-first: `handleClick`, `fetchAccounts`, `validateInput`
- Event handlers prefixed with `handle`: `handleSubmit`, `handleRowSelect`, `handleInputChange`
- Getters prefixed with `get` or descriptive: `get fullName()`, `get isDisabled()`
- Async methods should indicate async nature: `loadAccounts`, `fetchOrderData`
- Private/internal methods prefixed with underscore: `_calculateTotal`, `_resetState`

### Constants
- **UPPER_SNAKE_CASE** for true constants: `MAX_RECORDS`, `API_VERSION`, `DEFAULT_PAGE_SIZE`
- Define at module level, outside the class
- Group related constants together with a comment

### Properties
- `@api` properties: **camelCase**, descriptive: `recordId`, `accountName`, `showHeader`
- `@track` properties (when used): same as regular variables
- Private reactive properties: no underscore prefix needed (LWC reactivity handles it)

## Custom Events

- Event names in **kebab-case**: `row-select`, `form-submit`, `status-change`
- Always use `CustomEvent`, never `Event`
- Prefix with component context when events could be ambiguous: `invoice-save` vs just `save`
- Event detail should be a plain object, not a primitive: `{ detail: { recordId: '001...' } }`

## CSS

### Custom Properties
- Prefix with component name: `--account-card-header-color`, `--billing-form-spacing`
- Use SLDS design tokens where available instead of custom properties

### Class Names
- **kebab-case**: `container-header`, `action-bar`, `empty-state`
- Prefix with `slds-` only when extending SLDS utilities
- Avoid BEM in LWC (component encapsulation makes it unnecessary)
- Use descriptive names: `filter-panel` (good) vs `fp` (bad)

## Wire and Apex

- Wire property names should describe the data: `wiredAccounts`, `wiredContactResult`
- Apex method imports: name matches the Apex method, import alias only if needed for clarity
- Adapter imports: destructure clearly: `import { getRecord, getFieldValue } from 'lightning/uiRecordApi'`

## General Rules

- No Hungarian notation (`strName`, `arrItems`, `objAccount` — all bad)
- No type suffixes (`nameString`, `itemsArray` — all bad)
- Acronyms treated as words in camelCase: `htmlParser` (not `HTMLParser`), `apiVersion` (not `APIVersion`)
- Max identifier length: keep under 30 characters. If longer, the concept needs simplification.
