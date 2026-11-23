# CRUD Map: FlexiStock POS

Roles: **Owner** (all access), **Staff** (only what their role's permissions allow), **Visitor** (landing page only).

| Table                | C | R | U | D | Pages                               | Who           |
|----------------------|---|---|---|---|-------------------------------------|----------------------------------------------------------|
| store_profile        | - | ✓ | ✓ | - | settings                            | Owner: R, U. One row only, so never created or deleted  |
| module               | - | ✓ | ✓ | - | settings                            | Owner: toggle is_enabled. Fixed list, never deleted     |
| permission           | - | ✓ | - | - | roles-form                          | Owner: R. Fixed list defined by the system              |
| role                 | ✓ | ✓ | ✓ | ✓ | roles-list, roles-form             | Owner only. Delete blocked if staff use the role        |
| role_permission      | ✓ | ✓ | - | ✓ | roles-form (checkboxes)             | Owner only. Ticking and unticking adds or removes rows  |
| staff                | ✓ | ✓ | ✓ | - | staff-list, staff-form              | Owner only. Deactivated (is_active), not deleted        |
| category             | ✓ | ✓ | ✓ | ✓ | settings (list + form in one page)  | Owner: all. Delete blocked if products use it          |
| unit                 | ✓ | ✓ | ✓ | ✓ | settings                            | Owner: all. Delete blocked if in use                   |
| tax_rate             | ✓ | ✓ | ✓ | - | settings                            | Owner: C, R, U. Deactivated, not deleted                |
| product              | ✓ | ✓ | ✓ | - | products-list, product-form,        | Owner: all. Staff: R, plus C/U if permitted. Deactivated,|
|                      |   |    |   |   |product-view                         | not deleted                                             |
| product_unit         | ✓ | ✓ | ✓ | ✓ | product-form (units section)        | Same as product                                         |
| custom_field         | ✓ | ✓ | ✓ | ✓ | settings                            | Owner only                                              |
| product_custom_value | ✓ | ✓ | ✓ | ✓ | product-form (extra fields section) | Same as product                                         |
| supplier             | ✓ | ✓ | ✓ | - | suppliers-list, supplier-form       | Owner and permitted staff. Deactivated, not deleted     |
| supplier_contact     | ✓ | ✓ | ✓ | ✓ | supplier-form (contacts section)    | Same as supplier                                        |
| customer             | ✓ | ✓ | ✓ | - | customers-list, customer-form       | Owner and permitted staff. Deactivated, not deleted     |
| customer_contact     | ✓ | ✓ | ✓ | ✓ | customer-form (contacts section)    | Same as customer                                        |
| purchase_order       | ✓ | ✓ | ✓ | – | po-list, po-form                    | Owner and permitted staff. Cancelled via status, kept as |
|                      |   |    |   |   |                                     | record                                                  |
| purchase_order_item  | ✓ | ✓ | ✓ | ✓ | po-form (items section)             | Only while the order is DRAFT                           | 
| stock_batch          | ✓ | ✓ | - | - | receive-stock, stock-list            | Created when stock is received. Never edited or deleted, 
|                      |   |    |   |   |                                      | kept as record                                         |
| stock_movement       | ✓ | ✓ | - | - | stock-list, adjust-stock             | Created by system and adjustments. Never edited or     |
|                      |   |    |   |   |                                      | deleted (audit trail)                                  |
| discount             | ✓ | ✓ | ✓ | - | discounts                            | Owner only. Deactivated, not deleted                   |
| payment_method       | ✓ | ✓ | ✓ | - | settings                             | Owner only. Deactivated, not deleted                   |
| sale                 | ✓ | ✓ | ✓ | - | sale-screen, sales-list, sale-view   | Staff: C, R. Owner: R, U (status VOIDED). Never deleted, 
|                      |   |    |   |   |                                      | voided instead                                         |
| sale_item            | ✓ | ✓ | - | - | sale-screen, sale-view               | Created with the sale. Not edited, void the sale       |
|                      |   |    |   |   |                                      | instead                                                |
| payment              | ✓ | ✓ | - | - | sale-screen, sale-view, customers    | Staff: C, R. Never edited or deleted                   |
|                      |   |    |   |   | (credit payments)                    | (financial record)                                     |
| sale_return          | ✓ | ✓ | – | – | return-form, sale-view               | Staff with permission: C, R. Kept as record            |
| sale_return_item     | ✓ | ✓ | – | – | return-form                          | Same as sale_return                                    |

## Form fields (two most important tables)

### product (main form: prototype/form.html)
| Column        | Form control                                             | Required?        |
|---------------|----------------------------------------------------------|------------------|
| product_id    | none (AUTO_INCREMENT; hidden field on Edit)              | n/a              |
| category_id   | `<select>` filled from category                          | Yes *            |
| base_unit_id  | `<select>` filled from unit                              | Yes *            |
| tax_rate_id   | `<select>` filled from tax_rate, first option "No tax"   | No               |
| sku           | `<input type="text" maxlength="40">`                     | Yes *            |
| barcode       | `<input type="text" maxlength="50">`                     | No               |
| product_name  | `<input type="text" maxlength="120">`                    | Yes *            |
| selling_price | `<input type="number" min="0.01" step="0.01">`           | Yes *            |
| reorder_level | `<input type="number" min="0" step="0.001">` (default 0) | No (has default) |
| is_active     | `<input type="checkbox">` (checked by default)           | No (has default) |

### customer
| Column                         | Form control                                            | Required?                    |
|--------------------------------|---------------------------------------------------------|------------------------------|
| customer_id                    | none (AUTO_INCREMENT)                                   | n/a                          |
| full_name                      | `<input type="text" maxlength="100">`                   | Yes *                        |
| address                        | `<input type="text" maxlength="255">`                   | No                           |
| credit_limit                   | `<input type="number" min="0" step="0.01">` (default 0) | No (has default)             |
| is_active                      | `<input type="checkbox">`                               | No (has default)             |
| customer_contact.contact_type  | `<select>` with PHONE, MOBILE, EMAIL, OTHER             | Yes * (if adding a contact)  |
| customer_contact.contact_value | `<input type="text" maxlength="100">`                   | Yes * (if adding a contact)  |
| customer_contact.is_primary    | `<input type="checkbox">`                               | No                           |

## Schema changes
None so far.

Note for the list page: stock on hand is not a column in `product`. It is the sum of `stock_movement.quantity_change` per product, so the Week 15 query will need a JOIN through `stock_batch`.
