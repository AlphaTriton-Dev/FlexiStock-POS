-- =====================================================================
-- FlexiStock POS : sample data (seed). Run database/schema.sql first.
-- =====================================================================
USE flexistock_pos;

-- =====================================================================
-- 4. SAMPLE DATA (dates are relative to the day you run the script)
-- =====================================================================

INSERT INTO store_profile (profile_id, store_name, address, contact_number, currency_code, receipt_footer)
VALUES (1, 'FlexiStock Demo Store', '123 Main Street', '0917-555-0100', 'PHP', 'Thank you! Please come again.');

INSERT INTO module (module_code, module_name, description, is_enabled) VALUES
('EXPIRATION', 'Expiration tracking', 'Track expiry dates of stock', 1),
('BATCH_LOT',  'Batch / lot tracking', 'Track batch or lot numbers', 1),
('DISCOUNTS',  'Discounts', 'Apply discounts to sales', 1),
('SUPPLIERS',  'Supplier management', 'Suppliers, contacts and purchase orders', 1),
('CUSTOMERS',  'Customer details', 'Customer details and contacts', 1),
('CREDIT',     'Customer credit (utang)', 'Sell on credit with a due date', 1),
('RETURNS',    'Returns and refunds', 'Process returned goods', 1),
('TAX',        'Tax / VAT', 'Apply tax rates to products', 1),
('MULTI_UNIT', 'Multiple units', 'Sell in box, pack or piece', 1);

INSERT INTO permission (module_id, permission_code, description) VALUES
(NULL, 'SALE_CREATE',     'Create sales'),
(NULL, 'SALE_VOID',       'Void completed sales'),
(NULL, 'PRODUCT_MANAGE',  'Add and edit products'),
(NULL, 'STOCK_ADJUST',    'Adjust stock'),
(NULL, 'STAFF_MANAGE',    'Manage staff and roles'),
(NULL, 'SETTINGS_MANAGE', 'Change store settings and modules'),
(NULL, 'REPORT_VIEW',     'View reports'),
(4,    'PURCHASE_MANAGE', 'Manage suppliers and purchase orders'),
(3,    'DISCOUNT_APPLY',  'Apply discounts'),
(5,    'CUSTOMER_MANAGE', 'Manage customers'),
(6,    'CREDIT_SALE',     'Make credit sales'),
(7,    'RETURN_PROCESS',  'Process returns');

INSERT INTO role (role_name, description) VALUES
('Owner',   'Full access'),
('Manager', 'Everything except staff and settings'),
('Cashier', 'Sales only');

INSERT INTO role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM role r CROSS JOIN permission p
WHERE r.role_name = 'Owner';

INSERT INTO role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM role r CROSS JOIN permission p
WHERE r.role_name = 'Manager'
  AND p.permission_code NOT IN ('STAFF_MANAGE', 'SETTINGS_MANAGE');

INSERT INTO role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id FROM role r CROSS JOIN permission p
WHERE r.role_name = 'Cashier'
  AND p.permission_code IN ('SALE_CREATE', 'DISCOUNT_APPLY', 'CREDIT_SALE');

-- demo passwords only (SHA2 of owner123 / manager123 / cashier123)
INSERT INTO staff (role_id, full_name, username, password_hash, contact_number) VALUES
(1, 'Ana Reyes',  'owner',   SHA2('owner123', 256),   '0917-555-0001'),
(2, 'Ben Cruz',   'manager', SHA2('manager123', 256), '0917-555-0002'),
(3, 'Carla Diaz', 'cashier', SHA2('cashier123', 256), '0917-555-0003');

INSERT INTO category (category_name, description) VALUES
('Groceries', 'Food and pantry items'),
('Beverages', 'Drinks'),
('Medicines', 'Over-the-counter medicine'),
('Hardware',  'Tools and building supplies'),
('Household', 'Cleaning and home items');

INSERT INTO unit (unit_name, abbreviation) VALUES
('Piece', 'pc'), ('Box', 'box'), ('Pack', 'pack'), ('Kilogram', 'kg');

INSERT INTO tax_rate (tax_name, rate_percent) VALUES
('VAT 12%', 12.00), ('Zero-rated', 0.00);

INSERT INTO custom_field (field_name, data_type) VALUES
('Brand', 'TEXT'), ('Warranty (months)', 'NUMBER'), ('Dosage', 'TEXT');

-- Products: the trigger adds each product's base unit to product_unit.
INSERT INTO product (category_id, base_unit_id, tax_rate_id, sku, barcode, product_name, selling_price, reorder_level) VALUES
(1, 1, 1, 'GRC-001', '4800000000011', 'Instant Noodles Cup',       18.00,  24),
(2, 1, 1, 'BEV-001', '4800000000028', 'Bottled Water 500ml',       15.00,  48),
(3, 1, 2, 'MED-001', NULL,            'Paracetamol 500mg Tablet',   4.00, 100),
(3, 1, 2, 'MED-002', NULL,            'Vitamin C 500mg Tablet',     6.50, 100),
(4, 1, 1, 'HW-001',  NULL,            'Claw Hammer',              250.00,   5),
(4, 4, 1, 'HW-002',  NULL,            'Common Wire Nail 3 inch',   85.00,  10),
(5, 1, 1, 'HH-001',  '4800000000035', 'Laundry Detergent Bar',     22.00,  20),
(1, 4, 2, 'GRC-002', NULL,            'White Sugar',               72.00,  15),
(1, 1, 1, 'GRC-003', '4800000000042', 'Instant Coffee Sachet',      7.00,  60),
(1, 1, 1, 'GRC-004', '4800000000059', 'Canned Sardines 155g',      28.00,  30);

-- Extra selling units (box / pack) with conversion to the base unit.
INSERT INTO product_unit (product_id, unit_id, conversion_factor, selling_price) VALUES
(1, 2, 24,  410.00),   -- noodles: box of 24
(2, 3, 6,    84.00),   -- water: pack of 6
(3, 2, 100, 350.00),   -- paracetamol: box of 100
(9, 3, 10,   65.00);   -- coffee: pack of 10

INSERT INTO product_custom_value (product_id, field_id, field_value) VALUES
(5, 1, 'SteelPro'), (5, 2, '12'), (3, 3, '500 mg'), (4, 3, '500 mg');

INSERT INTO supplier (supplier_name, address) VALUES
('Metro Wholesale Trading',     '45 Market Road'),
('HealthPlus Distributors',     '8 Pharmacy Lane'),
('BuildRight Hardware Supply',  '210 Industrial Avenue');

INSERT INTO supplier_contact (supplier_id, contact_type, contact_value, contact_person, is_primary) VALUES
(1, 'MOBILE', '0917-555-0101', 'Rico Lim',   1),
(1, 'EMAIL',  'sales@metrowholesale.example', 'Rico Lim', 0),
(2, 'PHONE',  '(053) 555-0102', 'Dina Co',   1),
(2, 'EMAIL',  'orders@healthplus.example', 'Dina Co', 0),
(3, 'MOBILE', '0917-555-0103', 'Ed Tan',     1);

INSERT INTO customer (full_name, address, credit_limit) VALUES
('Lita Ramos',  '12 Rizal Street',   2000.00),
('Joel Navarro','34 Mabini Street',  1000.00),
('Mina Flores', '56 Bonifacio Street',  0.00);

INSERT INTO customer_contact (customer_id, contact_type, contact_value, is_primary) VALUES
(1, 'MOBILE', '0917-555-0201', 1),
(2, 'MOBILE', '0917-555-0202', 1),
(2, 'EMAIL',  'joel.navarro@example.com', 0),
(3, 'MOBILE', '0917-555-0203', 1);

INSERT INTO discount (discount_name, discount_type, discount_value) VALUES
('Senior Citizen 20%', 'PERCENT', 20.00),
('Promo 10 Pesos Off', 'FIXED',   10.00);

INSERT INTO payment_method (method_name) VALUES ('Cash'), ('GCash'), ('Bank Card');

INSERT INTO purchase_order (supplier_id, staff_id, po_number, order_date, expected_date, status) VALUES
(1, 2, 'PO-0001', DATE_SUB(CURDATE(), INTERVAL 40 DAY), DATE_SUB(CURDATE(), INTERVAL 35 DAY), 'RECEIVED'),
(2, 2, 'PO-0002', DATE_SUB(CURDATE(), INTERVAL 65 DAY), DATE_SUB(CURDATE(), INTERVAL 60 DAY), 'RECEIVED'),
(3, 2, 'PO-0003', DATE_SUB(CURDATE(), INTERVAL 3 DAY),  DATE_ADD(CURDATE(), INTERVAL 4 DAY),  'ORDERED');

INSERT INTO purchase_order_item (po_id, product_id, quantity_ordered, unit_cost) VALUES
(1, 1,  240, 14.00), (1, 2,  480, 10.00), (1, 9,  600,  5.00),
(2, 3, 2000,  2.50), (2, 4, 1000,  4.00),
(3, 5,   20, 180.00), (3, 6, 100, 60.00);

-- Receiving goods (product, po, batch no., expiry, received, quantity, cost, staff)
CALL sp_receive_batch(1,  1,    'NDL-2610', DATE_ADD(CURDATE(), INTERVAL 180 DAY), DATE_SUB(CURDATE(), INTERVAL 35 DAY),  240, 14.00, 2); -- batch 1
CALL sp_receive_batch(2,  1,    'WTR-2610', DATE_ADD(CURDATE(), INTERVAL 365 DAY), DATE_SUB(CURDATE(), INTERVAL 35 DAY),  480, 10.00, 2); -- batch 2
CALL sp_receive_batch(9,  1,    'CFE-2610', DATE_ADD(CURDATE(), INTERVAL 200 DAY), DATE_SUB(CURDATE(), INTERVAL 35 DAY),  600,  5.00, 2); -- batch 3
CALL sp_receive_batch(3,  2,    'PCM-2509', DATE_ADD(CURDATE(), INTERVAL 20 DAY),  DATE_SUB(CURDATE(), INTERVAL 60 DAY),  500,  2.50, 2); -- batch 4 (near expiry)
CALL sp_receive_batch(3,  2,    'PCM-2610', DATE_ADD(CURDATE(), INTERVAL 400 DAY), DATE_SUB(CURDATE(), INTERVAL 30 DAY), 1500,  2.50, 2); -- batch 5
CALL sp_receive_batch(3,  NULL, 'PCM-2412', DATE_SUB(CURDATE(), INTERVAL 10 DAY),  DATE_SUB(CURDATE(), INTERVAL 400 DAY), 200,  2.50, 2); -- batch 6 (already expired)
CALL sp_receive_batch(4,  2,    'VTC-2610', DATE_ADD(CURDATE(), INTERVAL 300 DAY), DATE_SUB(CURDATE(), INTERVAL 30 DAY), 1000,  4.00, 2); -- batch 7
CALL sp_receive_batch(7,  NULL, NULL,       NULL,                                  DATE_SUB(CURDATE(), INTERVAL 28 DAY),   24, 15.00, 2); -- batch 8 (no batch no./expiry)
CALL sp_receive_batch(8,  NULL, NULL,       NULL,                                  DATE_SUB(CURDATE(), INTERVAL 28 DAY),   50, 55.00, 2); -- batch 9
CALL sp_receive_batch(10, NULL, 'SRD-2610', DATE_ADD(CURDATE(), INTERVAL 400 DAY), DATE_SUB(CURDATE(), INTERVAL 28 DAY),  120, 21.00, 2); -- batch 10

-- Damaged goods removed from stock
INSERT INTO stock_movement (batch_id, staff_id, movement_type, quantity_change, movement_datetime, remarks)
VALUES (10, 2, 'DAMAGE', -3, DATE_SUB(NOW(), INTERVAL 5 DAY), 'Dented cans removed from shelf');

-- Sales (receipt numbers are generated by the trigger)
INSERT INTO sale (staff_id, customer_id, discount_id, sale_datetime, due_date, remarks) VALUES
(3, NULL, NULL, DATE_SUB(NOW(), INTERVAL 25 DAY), NULL, NULL),                                              -- 1
(3, NULL, NULL, DATE_SUB(NOW(), INTERVAL 22 DAY), NULL, NULL),                                              -- 2
(3, 1,    NULL, DATE_SUB(NOW(), INTERVAL 20 DAY), DATE_ADD(CURDATE(), INTERVAL 10 DAY), 'Credit sale (utang)'), -- 3
(3, 3,    1,    DATE_SUB(NOW(), INTERVAL 18 DAY), NULL, 'Senior citizen discount'),                         -- 4
(3, NULL, NULL, DATE_SUB(NOW(), INTERVAL 15 DAY), NULL, NULL),                                              -- 5
(2, NULL, NULL, DATE_SUB(NOW(), INTERVAL 12 DAY), NULL, NULL),                                              -- 6
(3, 2,    NULL, DATE_SUB(NOW(), INTERVAL 9 DAY),  DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'Credit sale (utang)'), -- 7
(3, NULL, NULL, DATE_SUB(NOW(), INTERVAL 7 DAY),  NULL, NULL),                                              -- 8
(3, NULL, 2,    DATE_SUB(NOW(), INTERVAL 4 DAY),  NULL, 'Promo discount'),                                  -- 9
(2, NULL, NULL, DATE_SUB(NOW(), INTERVAL 2 DAY),  NULL, NULL),                                              -- 10
(3, NULL, NULL, DATE_SUB(NOW(), INTERVAL 1 DAY),  NULL, 'Entered by mistake'),                              -- 11
(3, NULL, NULL, NOW(),                            NULL, NULL);                                              -- 12

-- Sale lines (each insert deducts stock automatically through trg_sale_item_ai)
INSERT INTO sale_item (sale_id, product_id, unit_id, quantity, unit_price, tax_rate_percent) VALUES
(1, 1, 1,  3, 18.00, 12), (1, 2, 1,  2, 15.00, 12),
(2, 3, 1, 10,  4.00,  0), (2, 4, 1, 10,  6.50,  0),
(3, 7, 1,  4, 22.00, 12), (3, 8, 4,  2, 72.00,  0),
(4, 3, 1, 20,  4.00,  0),
(5, 1, 2,  1, 410.00, 12), (5, 9, 3,  2, 65.00, 12),
(6, 10, 1, 6, 28.00, 12), (6, 2, 1,  6, 15.00, 12),
(7, 7, 1,  3, 22.00, 12), (7, 9, 1, 10,  7.00, 12),
(8, 1, 1,  5, 18.00, 12), (8, 9, 1,  5,  7.00, 12), (8, 10, 1, 2, 28.00, 12),
(9, 2, 1,  4, 15.00, 12), (9, 1, 1,  2, 18.00, 12),
(10, 4, 1, 20, 6.50,  0), (10, 3, 1, 15,  4.00,  0),
(11, 8, 4,  5, 72.00,  0),
(12, 1, 1,  4, 18.00, 12);

-- Sale 11 was entered by mistake: the owner voids it and stock is restored.
CALL sp_void_sale(11, 1);

-- Returns: line 1 restocked, line 2 damaged (not restocked)
INSERT INTO sale_return (sale_id, staff_id, return_datetime, reason) VALUES
(1, 2, DATE_SUB(NOW(), INTERVAL 24 DAY), 'Customer changed mind'),
(6, 2, DATE_SUB(NOW(), INTERVAL 11 DAY), 'Damaged can');

INSERT INTO sale_return_item (return_id, sale_item_id, quantity_returned, restock) VALUES
(1, (SELECT sale_item_id FROM sale_item WHERE sale_id = 1 AND product_id = 1  AND unit_id = 1), 1, 1),
(2, (SELECT sale_item_id FROM sale_item WHERE sale_id = 6 AND product_id = 10 AND unit_id = 1), 1, 0);

-- Payments (paid in full, taken from the computed sale totals)
INSERT INTO payment (sale_id, method_id, amount, paid_at, reference_number)
SELECT sale_id, 1, total_amount, sale_datetime, NULL
FROM v_sale_totals WHERE sale_id IN (1, 2, 5, 8, 10, 12);

INSERT INTO payment (sale_id, method_id, amount, paid_at, reference_number)
SELECT sale_id, 2, total_amount, sale_datetime, CONCAT('GC-', LPAD(sale_id, 6, '0'))
FROM v_sale_totals WHERE sale_id IN (4, 9);

INSERT INTO payment (sale_id, method_id, amount, paid_at, reference_number)
SELECT sale_id, 3, total_amount, sale_datetime, CONCAT('CARD-', LPAD(sale_id, 6, '0'))
FROM v_sale_totals WHERE sale_id = 6;

-- Credit sale 3: partial payment only. Credit sale 7: unpaid and overdue.
INSERT INTO payment (sale_id, method_id, amount, paid_at) VALUES
(3, 1, 100.00, DATE_SUB(NOW(), INTERVAL 15 DAY));

