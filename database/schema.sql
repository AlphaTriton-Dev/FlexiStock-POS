-- =====================================================================
-- FlexiStock POS : Phase 3 physical schema, sample data, analytical queries
-- Target : MySQL 8.0.16 or later (CHECK constraints are enforced from 8.0.16)
-- Run    : phpMyAdmin > Import, or in the MySQL shell:  SOURCE FlexiStock_POS.sql;
-- Note   : the script drops and recreates the database `flexistock_pos`.
-- Units  : stock_movement.quantity_change and stock_batch quantities are
--          always in the product's BASE unit. sale_item.quantity is in the
--          unit sold (piece, box, kg ...) and is converted when stock is deducted.
-- =====================================================================

DROP DATABASE IF EXISTS flexistock_pos;
CREATE DATABASE flexistock_pos CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE flexistock_pos;

-- =====================================================================
-- 1. TABLES
-- =====================================================================

-- ---- Group 1: Configuration and access ------------------------------

CREATE TABLE store_profile (
    profile_id      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    store_name      VARCHAR(100) NOT NULL,
    address         VARCHAR(255) NULL,
    contact_number  VARCHAR(30)  NULL,
    currency_code   CHAR(3)      NOT NULL DEFAULT 'PHP',
    receipt_footer  VARCHAR(255) NULL,
    CONSTRAINT pk_store_profile PRIMARY KEY (profile_id),
    CONSTRAINT ck_store_profile_single CHECK (profile_id = 1)
) ENGINE=InnoDB;

CREATE TABLE module (
    module_id    TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    module_code  VARCHAR(30)  NOT NULL,
    module_name  VARCHAR(60)  NOT NULL,
    description  VARCHAR(255) NULL,
    is_enabled   TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT pk_module PRIMARY KEY (module_id),
    CONSTRAINT uq_module_code UNIQUE (module_code),
    CONSTRAINT ck_module_enabled CHECK (is_enabled IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE permission (
    permission_id    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    module_id        TINYINT UNSIGNED  NULL,
    permission_code  VARCHAR(50)  NOT NULL,
    description      VARCHAR(255) NULL,
    CONSTRAINT pk_permission PRIMARY KEY (permission_id),
    CONSTRAINT uq_permission_code UNIQUE (permission_code),
    CONSTRAINT fk_permission_module FOREIGN KEY (module_id)
        REFERENCES module (module_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE role (
    role_id      SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    role_name    VARCHAR(50)  NOT NULL,
    description  VARCHAR(255) NULL,
    CONSTRAINT pk_role PRIMARY KEY (role_id),
    CONSTRAINT uq_role_name UNIQUE (role_name)
) ENGINE=InnoDB;

CREATE TABLE role_permission (
    role_id        SMALLINT UNSIGNED NOT NULL,
    permission_id  SMALLINT UNSIGNED NOT NULL,
    CONSTRAINT pk_role_permission PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role FOREIGN KEY (role_id)
        REFERENCES role (role_id) ON DELETE CASCADE,
    CONSTRAINT fk_rp_permission FOREIGN KEY (permission_id)
        REFERENCES permission (permission_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE staff (
    staff_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    role_id         SMALLINT UNSIGNED NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    username        VARCHAR(50)  NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    contact_number  VARCHAR(30)  NULL,
    is_active       TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT pk_staff PRIMARY KEY (staff_id),
    CONSTRAINT uq_staff_username UNIQUE (username),
    CONSTRAINT fk_staff_role FOREIGN KEY (role_id)
        REFERENCES role (role_id) ON DELETE RESTRICT,
    CONSTRAINT ck_staff_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

-- ---- Group 2: Catalog -------------------------------------------------

CREATE TABLE category (
    category_id    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_name  VARCHAR(60)  NOT NULL,
    description    VARCHAR(255) NULL,
    CONSTRAINT pk_category PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name)
) ENGINE=InnoDB;

CREATE TABLE unit (
    unit_id       SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    unit_name     VARCHAR(40) NOT NULL,
    abbreviation  VARCHAR(10) NOT NULL,
    CONSTRAINT pk_unit PRIMARY KEY (unit_id),
    CONSTRAINT uq_unit_name UNIQUE (unit_name),
    CONSTRAINT uq_unit_abbreviation UNIQUE (abbreviation)
) ENGINE=InnoDB;

CREATE TABLE tax_rate (
    tax_rate_id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tax_name      VARCHAR(50)  NOT NULL,
    rate_percent  DECIMAL(5,2) NOT NULL,
    is_active     TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT pk_tax_rate PRIMARY KEY (tax_rate_id),
    CONSTRAINT uq_tax_name UNIQUE (tax_name),
    CONSTRAINT ck_tax_rate_range CHECK (rate_percent BETWEEN 0 AND 100),
    CONSTRAINT ck_tax_rate_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE product (
    product_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id    SMALLINT UNSIGNED NOT NULL,
    base_unit_id   SMALLINT UNSIGNED NOT NULL,
    tax_rate_id    TINYINT UNSIGNED  NULL,
    sku            VARCHAR(40)  NOT NULL,
    barcode        VARCHAR(50)  NULL,
    product_name   VARCHAR(120) NOT NULL,
    selling_price  DECIMAL(12,2) NOT NULL,
    reorder_level  DECIMAL(12,3) NOT NULL DEFAULT 0,
    is_active      TINYINT(1)    NOT NULL DEFAULT 1,
    CONSTRAINT pk_product PRIMARY KEY (product_id),
    CONSTRAINT uq_product_sku UNIQUE (sku),
    CONSTRAINT uq_product_barcode UNIQUE (barcode),
    CONSTRAINT fk_product_category FOREIGN KEY (category_id)
        REFERENCES category (category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_product_base_unit FOREIGN KEY (base_unit_id)
        REFERENCES unit (unit_id) ON DELETE RESTRICT,
    CONSTRAINT fk_product_tax FOREIGN KEY (tax_rate_id)
        REFERENCES tax_rate (tax_rate_id) ON DELETE RESTRICT,
    CONSTRAINT ck_product_price CHECK (selling_price > 0),
    CONSTRAINT ck_product_reorder CHECK (reorder_level >= 0),
    CONSTRAINT ck_product_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE product_unit (
    product_id         INT UNSIGNED NOT NULL,
    unit_id            SMALLINT UNSIGNED NOT NULL,
    conversion_factor  DECIMAL(12,4) NOT NULL,
    selling_price      DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_product_unit PRIMARY KEY (product_id, unit_id),
    CONSTRAINT fk_pu_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON DELETE CASCADE,
    CONSTRAINT fk_pu_unit FOREIGN KEY (unit_id)
        REFERENCES unit (unit_id) ON DELETE RESTRICT,
    CONSTRAINT ck_pu_factor CHECK (conversion_factor > 0),
    CONSTRAINT ck_pu_price CHECK (selling_price > 0)
) ENGINE=InnoDB;

CREATE TABLE custom_field (
    field_id    SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    field_name  VARCHAR(60) NOT NULL,
    data_type   VARCHAR(10) NOT NULL DEFAULT 'TEXT',
    CONSTRAINT pk_custom_field PRIMARY KEY (field_id),
    CONSTRAINT uq_custom_field_name UNIQUE (field_name),
    CONSTRAINT ck_custom_field_type CHECK (data_type IN ('TEXT', 'NUMBER', 'DATE', 'BOOLEAN'))
) ENGINE=InnoDB;

CREATE TABLE product_custom_value (
    product_id   INT UNSIGNED NOT NULL,
    field_id     SMALLINT UNSIGNED NOT NULL,
    field_value  VARCHAR(255) NOT NULL,
    CONSTRAINT pk_product_custom_value PRIMARY KEY (product_id, field_id),
    CONSTRAINT fk_pcv_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON DELETE CASCADE,
    CONSTRAINT fk_pcv_field FOREIGN KEY (field_id)
        REFERENCES custom_field (field_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---- Group 3: People --------------------------------------------------

CREATE TABLE supplier (
    supplier_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    supplier_name  VARCHAR(100) NOT NULL,
    address        VARCHAR(255) NULL,
    is_active      TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT pk_supplier PRIMARY KEY (supplier_id),
    CONSTRAINT uq_supplier_name UNIQUE (supplier_name),
    CONSTRAINT ck_supplier_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE supplier_contact (
    contact_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    supplier_id     INT UNSIGNED NOT NULL,
    contact_type    VARCHAR(10)  NOT NULL,
    contact_value   VARCHAR(100) NOT NULL,
    contact_person  VARCHAR(100) NULL,
    is_primary      TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT pk_supplier_contact PRIMARY KEY (contact_id),
    CONSTRAINT uq_supplier_contact UNIQUE (supplier_id, contact_type, contact_value),
    CONSTRAINT fk_sc_supplier FOREIGN KEY (supplier_id)
        REFERENCES supplier (supplier_id) ON DELETE CASCADE,
    CONSTRAINT ck_sc_type CHECK (contact_type IN ('PHONE', 'MOBILE', 'EMAIL', 'OTHER')),
    CONSTRAINT ck_sc_primary CHECK (is_primary IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE customer (
    customer_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    full_name     VARCHAR(100) NOT NULL,
    address       VARCHAR(255) NULL,
    credit_limit  DECIMAL(12,2) NOT NULL DEFAULT 0,
    is_active     TINYINT(1)    NOT NULL DEFAULT 1,
    CONSTRAINT pk_customer PRIMARY KEY (customer_id),
    CONSTRAINT ck_customer_credit CHECK (credit_limit >= 0),
    CONSTRAINT ck_customer_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE customer_contact (
    contact_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    customer_id    INT UNSIGNED NOT NULL,
    contact_type   VARCHAR(10)  NOT NULL,
    contact_value  VARCHAR(100) NOT NULL,
    is_primary     TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT pk_customer_contact PRIMARY KEY (contact_id),
    CONSTRAINT uq_customer_contact UNIQUE (customer_id, contact_type, contact_value),
    CONSTRAINT fk_cc_customer FOREIGN KEY (customer_id)
        REFERENCES customer (customer_id) ON DELETE CASCADE,
    CONSTRAINT ck_cc_type CHECK (contact_type IN ('PHONE', 'MOBILE', 'EMAIL', 'OTHER')),
    CONSTRAINT ck_cc_primary CHECK (is_primary IN (0, 1))
) ENGINE=InnoDB;

-- ---- Group 4: Purchasing and inventory (stock_movement is created last) --

CREATE TABLE purchase_order (
    po_id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    supplier_id    INT UNSIGNED NOT NULL,
    staff_id       INT UNSIGNED NOT NULL,
    po_number      VARCHAR(30)  NOT NULL,
    order_date     DATE         NOT NULL,
    expected_date  DATE         NULL,
    status         VARCHAR(10)  NOT NULL DEFAULT 'DRAFT',
    CONSTRAINT pk_purchase_order PRIMARY KEY (po_id),
    CONSTRAINT uq_po_number UNIQUE (po_number),
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id)
        REFERENCES supplier (supplier_id) ON DELETE RESTRICT,
    CONSTRAINT fk_po_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id) ON DELETE RESTRICT,
    CONSTRAINT ck_po_status CHECK (status IN ('DRAFT', 'ORDERED', 'RECEIVED', 'CANCELLED')),
    CONSTRAINT ck_po_dates CHECK (expected_date IS NULL OR expected_date >= order_date)
) ENGINE=InnoDB;

CREATE TABLE purchase_order_item (
    po_id             INT UNSIGNED NOT NULL,
    product_id        INT UNSIGNED NOT NULL,
    quantity_ordered  DECIMAL(12,3) NOT NULL,
    unit_cost         DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_purchase_order_item PRIMARY KEY (po_id, product_id),
    CONSTRAINT fk_poi_po FOREIGN KEY (po_id)
        REFERENCES purchase_order (po_id) ON DELETE CASCADE,
    CONSTRAINT fk_poi_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON DELETE RESTRICT,
    CONSTRAINT ck_poi_qty CHECK (quantity_ordered > 0),
    CONSTRAINT ck_poi_cost CHECK (unit_cost >= 0)
) ENGINE=InnoDB;

CREATE TABLE stock_batch (
    batch_id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id         INT UNSIGNED NOT NULL,
    po_id              INT UNSIGNED NULL,
    batch_number       VARCHAR(40)  NULL,
    expiry_date        DATE         NULL,
    received_date      DATE         NOT NULL,
    quantity_received  DECIMAL(12,3) NOT NULL,
    unit_cost          DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_stock_batch PRIMARY KEY (batch_id),
    CONSTRAINT uq_batch_number UNIQUE (product_id, batch_number),
    CONSTRAINT fk_batch_product FOREIGN KEY (product_id)
        REFERENCES product (product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_batch_po FOREIGN KEY (po_id)
        REFERENCES purchase_order (po_id) ON DELETE RESTRICT,
    CONSTRAINT ck_batch_qty CHECK (quantity_received > 0),
    CONSTRAINT ck_batch_cost CHECK (unit_cost >= 0),
    CONSTRAINT ck_batch_expiry CHECK (expiry_date IS NULL OR expiry_date >= received_date)
) ENGINE=InnoDB;

-- ---- Group 5: Sales ---------------------------------------------------

CREATE TABLE discount (
    discount_id     SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    discount_name   VARCHAR(60)  NOT NULL,
    discount_type   VARCHAR(7)   NOT NULL,
    discount_value  DECIMAL(12,2) NOT NULL,
    start_date      DATE NULL,
    end_date        DATE NULL,
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT pk_discount PRIMARY KEY (discount_id),
    CONSTRAINT uq_discount_name UNIQUE (discount_name),
    CONSTRAINT ck_discount_type CHECK (discount_type IN ('PERCENT', 'FIXED')),
    CONSTRAINT ck_discount_value CHECK (discount_value > 0),
    CONSTRAINT ck_discount_percent CHECK (discount_type <> 'PERCENT' OR discount_value <= 100),
    CONSTRAINT ck_discount_dates CHECK (start_date IS NULL OR end_date IS NULL OR end_date >= start_date),
    CONSTRAINT ck_discount_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE payment_method (
    method_id    TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    method_name  VARCHAR(40) NOT NULL,
    is_active    TINYINT(1)  NOT NULL DEFAULT 1,
    CONSTRAINT pk_payment_method PRIMARY KEY (method_id),
    CONSTRAINT uq_method_name UNIQUE (method_name),
    CONSTRAINT ck_method_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB;

CREATE TABLE sale (
    sale_id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_id        INT UNSIGNED NOT NULL,
    customer_id     INT UNSIGNED NULL,
    discount_id     SMALLINT UNSIGNED NULL,
    receipt_number  VARCHAR(30) NOT NULL,   -- generated by trigger trg_sale_bi
    sale_datetime   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date        DATE        NULL,       -- set only for credit (utang) sales
    status          VARCHAR(9)  NOT NULL DEFAULT 'COMPLETED',
    remarks         VARCHAR(255) NULL,
    CONSTRAINT pk_sale PRIMARY KEY (sale_id),
    CONSTRAINT uq_sale_receipt UNIQUE (receipt_number),
    CONSTRAINT fk_sale_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id)
        REFERENCES customer (customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sale_discount FOREIGN KEY (discount_id)
        REFERENCES discount (discount_id) ON DELETE RESTRICT,
    CONSTRAINT ck_sale_status CHECK (status IN ('COMPLETED', 'VOIDED')),
    CONSTRAINT ck_sale_due CHECK (due_date IS NULL OR due_date >= DATE(sale_datetime)),
    CONSTRAINT ck_sale_credit_customer CHECK (due_date IS NULL OR customer_id IS NOT NULL)
) ENGINE=InnoDB;

CREATE TABLE sale_item (
    sale_item_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    sale_id           BIGINT UNSIGNED NOT NULL,
    product_id        INT UNSIGNED NOT NULL,
    unit_id           SMALLINT UNSIGNED NOT NULL,
    quantity          DECIMAL(12,3) NOT NULL,
    unit_price        DECIMAL(12,2) NOT NULL,
    tax_rate_percent  DECIMAL(5,2)  NOT NULL DEFAULT 0,
    CONSTRAINT pk_sale_item PRIMARY KEY (sale_item_id),
    CONSTRAINT uq_sale_item_line UNIQUE (sale_id, product_id, unit_id),
    CONSTRAINT fk_si_sale FOREIGN KEY (sale_id)
        REFERENCES sale (sale_id) ON DELETE RESTRICT,
    -- one composite key: the product can only be sold in a unit defined for it
    CONSTRAINT fk_si_product_unit FOREIGN KEY (product_id, unit_id)
        REFERENCES product_unit (product_id, unit_id) ON DELETE RESTRICT,
    CONSTRAINT ck_si_qty CHECK (quantity > 0),
    CONSTRAINT ck_si_price CHECK (unit_price > 0),
    CONSTRAINT ck_si_tax CHECK (tax_rate_percent BETWEEN 0 AND 100)
) ENGINE=InnoDB;

CREATE TABLE payment (
    payment_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    sale_id           BIGINT UNSIGNED NOT NULL,
    method_id         TINYINT UNSIGNED NOT NULL,
    amount            DECIMAL(12,2) NOT NULL,
    paid_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reference_number  VARCHAR(50) NULL,
    CONSTRAINT pk_payment PRIMARY KEY (payment_id),
    CONSTRAINT fk_pay_sale FOREIGN KEY (sale_id)
        REFERENCES sale (sale_id) ON DELETE RESTRICT,
    CONSTRAINT fk_pay_method FOREIGN KEY (method_id)
        REFERENCES payment_method (method_id) ON DELETE RESTRICT,
    CONSTRAINT ck_pay_amount CHECK (amount > 0)
) ENGINE=InnoDB;

-- ---- Group 6: Returns -------------------------------------------------

CREATE TABLE sale_return (
    return_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    sale_id          BIGINT UNSIGNED NOT NULL,
    staff_id         INT UNSIGNED NOT NULL,
    return_datetime  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason           VARCHAR(255) NULL,
    CONSTRAINT pk_sale_return PRIMARY KEY (return_id),
    CONSTRAINT fk_ret_sale FOREIGN KEY (sale_id)
        REFERENCES sale (sale_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ret_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE sale_return_item (
    return_item_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    return_id          INT UNSIGNED NOT NULL,
    sale_item_id       BIGINT UNSIGNED NOT NULL,
    quantity_returned  DECIMAL(12,3) NOT NULL,
    restock            TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT pk_sale_return_item PRIMARY KEY (return_item_id),
    CONSTRAINT uq_return_line UNIQUE (return_id, sale_item_id),
    CONSTRAINT fk_ri_return FOREIGN KEY (return_id)
        REFERENCES sale_return (return_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ri_sale_item FOREIGN KEY (sale_item_id)
        REFERENCES sale_item (sale_item_id) ON DELETE RESTRICT,
    CONSTRAINT ck_ri_qty CHECK (quantity_returned > 0),
    CONSTRAINT ck_ri_restock CHECK (restock IN (0, 1))
) ENGINE=InnoDB;

-- ---- Stock movement (audit log of every change in stock) ---------------

CREATE TABLE stock_movement (
    movement_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    batch_id           INT UNSIGNED NOT NULL,
    staff_id           INT UNSIGNED NOT NULL,
    sale_item_id       BIGINT UNSIGNED NULL,
    return_item_id     INT UNSIGNED NULL,
    movement_type      VARCHAR(10)  NOT NULL,
    quantity_change    DECIMAL(12,3) NOT NULL,   -- base units, + in / - out
    movement_datetime  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarks            VARCHAR(255) NULL,
    CONSTRAINT pk_stock_movement PRIMARY KEY (movement_id),
    CONSTRAINT fk_sm_batch FOREIGN KEY (batch_id)
        REFERENCES stock_batch (batch_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sm_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sm_sale_item FOREIGN KEY (sale_item_id)
        REFERENCES sale_item (sale_item_id) ON DELETE RESTRICT,
    CONSTRAINT fk_sm_return_item FOREIGN KEY (return_item_id)
        REFERENCES sale_return_item (return_item_id) ON DELETE RESTRICT,
    CONSTRAINT ck_sm_type CHECK (movement_type IN
        ('RECEIVE', 'SALE', 'VOID', 'RETURN_IN', 'ADJUSTMENT', 'DAMAGE')),
    -- the sign of the change must match the type of movement
    CONSTRAINT ck_sm_sign CHECK (
        (movement_type IN ('RECEIVE', 'VOID', 'RETURN_IN') AND quantity_change > 0) OR
        (movement_type IN ('SALE', 'DAMAGE') AND quantity_change < 0) OR
        (movement_type = 'ADJUSTMENT' AND quantity_change <> 0)
    )
) ENGINE=InnoDB;

-- =====================================================================
-- 2. TRIGGERS AND STORED PROCEDURES
--    (rules that a CHECK or foreign key cannot express)
-- =====================================================================

DELIMITER $$

-- Receipt number is generated automatically when a sale is created.
CREATE TRIGGER trg_sale_bi BEFORE INSERT ON sale
FOR EACH ROW
BEGIN
    IF NEW.receipt_number IS NULL OR NEW.receipt_number = '' THEN
        SET NEW.receipt_number = CONCAT(
            'RCPT-', DATE_FORMAT(COALESCE(NEW.sale_datetime, NOW()), '%Y%m%d'), '-',
            LPAD((SELECT COALESCE(MAX(sale_id), 0) + 1 FROM sale), 6, '0'));
    END IF;
END$$

-- Every product always has its base unit (conversion factor 1) in product_unit.
CREATE TRIGGER trg_product_ai AFTER INSERT ON product
FOR EACH ROW
BEGIN
    INSERT INTO product_unit (product_id, unit_id, conversion_factor, selling_price)
    VALUES (NEW.product_id, NEW.base_unit_id, 1, NEW.selling_price);
END$$

CREATE TRIGGER trg_product_bu BEFORE UPDATE ON product
FOR EACH ROW
BEGIN
    IF NEW.base_unit_id <> OLD.base_unit_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The base unit of a product cannot be changed';
    END IF;
END$$

-- Keep the base-unit price in step with the product price.
CREATE TRIGGER trg_product_au AFTER UPDATE ON product
FOR EACH ROW
BEGIN
    IF NEW.selling_price <> OLD.selling_price THEN
        UPDATE product_unit SET selling_price = NEW.selling_price
        WHERE product_id = NEW.product_id AND unit_id = NEW.base_unit_id;
    END IF;
END$$

CREATE TRIGGER trg_product_unit_bi BEFORE INSERT ON product_unit
FOR EACH ROW
BEGIN
    DECLARE v_base SMALLINT UNSIGNED;
    SELECT base_unit_id INTO v_base FROM product WHERE product_id = NEW.product_id;
    IF v_base = NEW.unit_id AND NEW.conversion_factor <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The base unit must have a conversion factor of 1';
    END IF;
END$$

CREATE TRIGGER trg_product_unit_bu BEFORE UPDATE ON product_unit
FOR EACH ROW
BEGIN
    DECLARE v_base SMALLINT UNSIGNED;
    SELECT base_unit_id INTO v_base FROM product WHERE product_id = NEW.product_id;
    IF v_base = NEW.unit_id AND NEW.conversion_factor <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The base unit must have a conversion factor of 1';
    END IF;
END$$

CREATE TRIGGER trg_product_unit_bd BEFORE DELETE ON product_unit
FOR EACH ROW
BEGIN
    DECLARE v_base SMALLINT UNSIGNED;
    SELECT base_unit_id INTO v_base FROM product WHERE product_id = OLD.product_id;
    IF v_base = OLD.unit_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The base unit row of a product cannot be deleted';
    END IF;
END$$

-- A movement has exactly one valid source, and a batch can never go below zero.
CREATE TRIGGER trg_stock_movement_bi BEFORE INSERT ON stock_movement
FOR EACH ROW
BEGIN
    DECLARE v_on_hand DECIMAL(12,3);
    IF NEW.movement_type IN ('SALE', 'VOID')
       AND (NEW.sale_item_id IS NULL OR NEW.return_item_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SALE and VOID movements need a sale line and no return line';
    ELSEIF NEW.movement_type = 'RETURN_IN'
       AND (NEW.return_item_id IS NULL OR NEW.sale_item_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RETURN_IN movements need a return line and no sale line';
    ELSEIF NEW.movement_type IN ('RECEIVE', 'ADJUSTMENT', 'DAMAGE')
       AND (NEW.sale_item_id IS NOT NULL OR NEW.return_item_id IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RECEIVE, ADJUSTMENT and DAMAGE movements cannot link to a sale or return line';
    END IF;
    SELECT COALESCE(SUM(quantity_change), 0) INTO v_on_hand
    FROM stock_movement WHERE batch_id = NEW.batch_id;
    IF v_on_hand + NEW.quantity_change < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock movement rejected: batch stock cannot go below zero';
    END IF;
END$$

-- Receive goods: creates the batch and its RECEIVE movement together.
CREATE PROCEDURE sp_receive_batch(
    IN p_product_id    INT UNSIGNED,
    IN p_po_id         INT UNSIGNED,
    IN p_batch_number  VARCHAR(40),
    IN p_expiry_date   DATE,
    IN p_received_date DATE,
    IN p_quantity      DECIMAL(12,3),
    IN p_unit_cost     DECIMAL(12,2),
    IN p_staff_id      INT UNSIGNED)
BEGIN
    DECLARE v_batch INT UNSIGNED;
    INSERT INTO stock_batch (product_id, po_id, batch_number, expiry_date,
                             received_date, quantity_received, unit_cost)
    VALUES (p_product_id, p_po_id, p_batch_number, p_expiry_date,
            p_received_date, p_quantity, p_unit_cost);
    SET v_batch = LAST_INSERT_ID();
    INSERT INTO stock_movement (batch_id, staff_id, movement_type, quantity_change,
                                movement_datetime, remarks)
    VALUES (v_batch, p_staff_id, 'RECEIVE', p_quantity,
            TIMESTAMP(p_received_date, '08:00:00'), 'Goods received');
END$$

-- Deduct stock for a sale line: earliest expiry first, expired batches skipped.
CREATE PROCEDURE sp_deduct_stock(
    IN p_sale_item_id  BIGINT UNSIGNED,
    IN p_product_id    INT UNSIGNED,
    IN p_quantity      DECIMAL(12,3),
    IN p_staff_id      INT UNSIGNED,
    IN p_when          DATETIME)
BEGIN
    DECLARE v_remaining DECIMAL(12,3) DEFAULT p_quantity;
    DECLARE v_batch     INT UNSIGNED;
    DECLARE v_avail     DECIMAL(12,3);
    DECLARE v_take      DECIMAL(12,3);
    DECLARE v_done      TINYINT DEFAULT 0;
    DECLARE cur CURSOR FOR
        SELECT sb.batch_id, SUM(COALESCE(sm.quantity_change, 0)) AS qty_avail
        FROM stock_batch sb
        LEFT JOIN stock_movement sm ON sm.batch_id = sb.batch_id
        WHERE sb.product_id = p_product_id
          AND (sb.expiry_date IS NULL OR sb.expiry_date >= CURDATE())
        GROUP BY sb.batch_id, sb.expiry_date, sb.received_date
        HAVING SUM(COALESCE(sm.quantity_change, 0)) > 0
        ORDER BY (sb.expiry_date IS NULL), sb.expiry_date, sb.received_date, sb.batch_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_batch, v_avail;
        IF v_done = 1 OR v_remaining <= 0 THEN
            LEAVE read_loop;
        END IF;
        SET v_take = LEAST(v_avail, v_remaining);
        INSERT INTO stock_movement (batch_id, staff_id, sale_item_id, movement_type,
                                    quantity_change, movement_datetime)
        VALUES (v_batch, p_staff_id, p_sale_item_id, 'SALE', -v_take, p_when);
        SET v_remaining = v_remaining - v_take;
    END LOOP;
    CLOSE cur;

    IF v_remaining > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient sellable stock for this sale line';
    END IF;
END$$

-- Every sale line updates inventory automatically.
CREATE TRIGGER trg_sale_item_ai AFTER INSERT ON sale_item
FOR EACH ROW
BEGIN
    DECLARE v_factor DECIMAL(12,4);
    DECLARE v_staff  INT UNSIGNED;
    DECLARE v_when   DATETIME;
    SELECT conversion_factor INTO v_factor FROM product_unit
    WHERE product_id = NEW.product_id AND unit_id = NEW.unit_id;
    SELECT staff_id, sale_datetime INTO v_staff, v_when FROM sale WHERE sale_id = NEW.sale_id;
    CALL sp_deduct_stock(NEW.sale_item_id, NEW.product_id, NEW.quantity * v_factor, v_staff, v_when);
END$$

-- Void a sale: only a role holding SALE_VOID may do it; stock is restored.
CREATE PROCEDURE sp_void_sale(IN p_sale_id BIGINT UNSIGNED, IN p_staff_id INT UNSIGNED)
BEGIN
    DECLARE v_status    VARCHAR(9);
    DECLARE v_sale_item BIGINT UNSIGNED;
    DECLARE v_batch     INT UNSIGNED;
    DECLARE v_qty       DECIMAL(12,3);
    DECLARE v_done      TINYINT DEFAULT 0;
    DECLARE cur CURSOR FOR
        SELECT sm.sale_item_id, sm.batch_id, -sm.quantity_change
        FROM stock_movement sm
        JOIN sale_item si ON si.sale_item_id = sm.sale_item_id
        WHERE si.sale_id = p_sale_id AND sm.movement_type = 'SALE';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    IF NOT EXISTS (SELECT 1 FROM staff s
                   JOIN role_permission rp ON rp.role_id = s.role_id
                   JOIN permission p ON p.permission_id = rp.permission_id
                   WHERE s.staff_id = p_staff_id AND s.is_active = 1
                     AND p.permission_code = 'SALE_VOID') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This staff role is not allowed to void sales';
    END IF;

    SELECT status INTO v_status FROM sale WHERE sale_id = p_sale_id;
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sale not found';
    END IF;
    IF v_status <> 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sale is already voided';
    END IF;

    UPDATE sale SET status = 'VOIDED' WHERE sale_id = p_sale_id;

    SET v_done = 0;
    OPEN cur;
    void_loop: LOOP
        FETCH cur INTO v_sale_item, v_batch, v_qty;
        IF v_done = 1 THEN
            LEAVE void_loop;
        END IF;
        INSERT INTO stock_movement (batch_id, staff_id, sale_item_id, movement_type,
                                    quantity_change, remarks)
        VALUES (v_batch, p_staff_id, v_sale_item, 'VOID', v_qty, 'Sale voided, stock restored');
    END LOOP;
    CLOSE cur;
END$$

-- A returned line must belong to the return's sale, and cannot exceed what was sold.
CREATE TRIGGER trg_sale_return_item_bi BEFORE INSERT ON sale_return_item
FOR EACH ROW
BEGIN
    DECLARE v_return_sale BIGINT UNSIGNED;
    DECLARE v_item_sale   BIGINT UNSIGNED;
    DECLARE v_sold        DECIMAL(12,3);
    DECLARE v_returned    DECIMAL(12,3);
    SELECT sale_id INTO v_return_sale FROM sale_return WHERE return_id = NEW.return_id;
    SELECT sale_id, quantity INTO v_item_sale, v_sold FROM sale_item WHERE sale_item_id = NEW.sale_item_id;
    IF v_return_sale <> v_item_sale THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Returned line does not belong to the sale of this return';
    END IF;
    SELECT COALESCE(SUM(quantity_returned), 0) INTO v_returned
    FROM sale_return_item WHERE sale_item_id = NEW.sale_item_id;
    IF v_returned + NEW.quantity_returned > v_sold THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity returned exceeds the quantity sold';
    END IF;
END$$

-- Restocked returns go back into stock (into the batch the goods came from).
CREATE TRIGGER trg_sale_return_item_ai AFTER INSERT ON sale_return_item
FOR EACH ROW
BEGIN
    DECLARE v_batch  INT UNSIGNED;
    DECLARE v_factor DECIMAL(12,4);
    DECLARE v_staff  INT UNSIGNED;
    DECLARE v_when   DATETIME;
    IF NEW.restock = 1 THEN
        SELECT sm.batch_id INTO v_batch FROM stock_movement sm
        WHERE sm.sale_item_id = NEW.sale_item_id AND sm.movement_type = 'SALE'
        ORDER BY sm.movement_id LIMIT 1;
        SELECT pu.conversion_factor INTO v_factor
        FROM sale_item si
        JOIN product_unit pu ON pu.product_id = si.product_id AND pu.unit_id = si.unit_id
        WHERE si.sale_item_id = NEW.sale_item_id;
        SELECT staff_id, return_datetime INTO v_staff, v_when
        FROM sale_return WHERE return_id = NEW.return_id;
        INSERT INTO stock_movement (batch_id, staff_id, return_item_id, movement_type,
                                    quantity_change, movement_datetime, remarks)
        VALUES (v_batch, v_staff, NEW.return_item_id, 'RETURN_IN',
                NEW.quantity_returned * v_factor, v_when, 'Returned goods restocked');
    END IF;
END$$

DELIMITER ;

-- =====================================================================
-- 3. VIEWS (derived values are computed here, never stored)
--    Assumptions: unit_price is tax-exclusive; a discount reduces the
--    subtotal and tax is charged on the discounted amount.
-- =====================================================================

CREATE VIEW v_sale_totals AS
SELECT x.sale_id, x.receipt_number, x.sale_datetime, x.staff_id, x.customer_id, x.status,
       ROUND(x.subtotal, 2) AS subtotal,
       x.discount_amount,
       ROUND(x.tax_before_discount * (x.subtotal - x.discount_amount) / x.subtotal, 2) AS tax_amount,
       ROUND((x.subtotal - x.discount_amount)
             + x.tax_before_discount * (x.subtotal - x.discount_amount) / x.subtotal, 2) AS total_amount
FROM (
    SELECT s.sale_id, s.receipt_number, s.sale_datetime, s.staff_id, s.customer_id, s.status,
           SUM(si.quantity * si.unit_price) AS subtotal,
           SUM(si.quantity * si.unit_price * si.tax_rate_percent / 100) AS tax_before_discount,
           ROUND(CASE
                   WHEN d.discount_id IS NULL THEN 0
                   WHEN d.discount_type = 'PERCENT'
                        THEN SUM(si.quantity * si.unit_price) * d.discount_value / 100
                   ELSE LEAST(d.discount_value, SUM(si.quantity * si.unit_price))
                 END, 2) AS discount_amount
    FROM sale s
    JOIN sale_item si ON si.sale_id = s.sale_id
    LEFT JOIN discount d ON d.discount_id = s.discount_id
    GROUP BY s.sale_id, s.receipt_number, s.sale_datetime, s.staff_id, s.customer_id, s.status,
             d.discount_id, d.discount_type, d.discount_value
) x;

CREATE VIEW v_sale_balance AS
SELECT t.sale_id, t.receipt_number, t.sale_datetime, s.due_date, t.customer_id, t.status,
       t.total_amount,
       COALESCE(p.total_paid, 0) AS total_paid,
       ROUND(t.total_amount - COALESCE(p.total_paid, 0), 2) AS balance_due
FROM v_sale_totals t
JOIN sale s ON s.sale_id = t.sale_id
LEFT JOIN (SELECT sale_id, SUM(amount) AS total_paid FROM payment GROUP BY sale_id) p
       ON p.sale_id = t.sale_id;

CREATE VIEW v_customer_credit AS
SELECT c.customer_id, c.full_name, c.credit_limit,
       COALESCE(SUM(b.balance_due), 0) AS credit_used,
       c.credit_limit - COALESCE(SUM(b.balance_due), 0) AS credit_available
FROM customer c
LEFT JOIN v_sale_balance b
       ON b.customer_id = c.customer_id AND b.status = 'COMPLETED' AND b.balance_due > 0
GROUP BY c.customer_id, c.full_name, c.credit_limit;

CREATE VIEW v_batch_stock AS
SELECT b.batch_id, b.product_id, b.batch_number, b.expiry_date, b.received_date,
       COALESCE(SUM(m.quantity_change), 0) AS qty_on_hand
FROM stock_batch b
LEFT JOIN stock_movement m ON m.batch_id = b.batch_id
GROUP BY b.batch_id, b.product_id, b.batch_number, b.expiry_date, b.received_date;

CREATE VIEW v_product_stock AS
SELECT p.product_id, p.sku, p.product_name, p.category_id, p.reorder_level, p.is_active,
       COALESCE(SUM(CASE WHEN bs.expiry_date IS NULL OR bs.expiry_date >= CURDATE()
                         THEN bs.qty_on_hand ELSE 0 END), 0) AS sellable_qty,
       COALESCE(SUM(bs.qty_on_hand), 0) AS total_on_hand
FROM product p
LEFT JOIN v_batch_stock bs ON bs.product_id = p.product_id
GROUP BY p.product_id, p.sku, p.product_name, p.category_id, p.reorder_level, p.is_active;

CREATE VIEW v_low_stock AS
SELECT product_id, sku, product_name, sellable_qty, reorder_level
FROM v_product_stock
WHERE is_active = 1 AND sellable_qty <= reorder_level;

CREATE VIEW v_expiring_batches AS
SELECT bs.batch_id, p.sku, p.product_name, bs.batch_number, bs.expiry_date,
       DATEDIFF(bs.expiry_date, CURDATE()) AS days_left, bs.qty_on_hand
FROM v_batch_stock bs
JOIN product p ON p.product_id = bs.product_id
WHERE bs.expiry_date IS NOT NULL
  AND bs.qty_on_hand > 0
  AND bs.expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY);

