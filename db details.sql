-- QUERY TRUNCATED
-- =========================================================
-- Bigger e-commerce schema + LARGE seed in PUBLIC schema
-- Safe to re-run (drops/recreates objects in public)
-- Target: PostgreSQL 13+
-- =========================================================

SET search_path = public;

-- -------------------------
-- Drop existing objects
-- -------------------------
-- MVs first
DROP MATERIALIZED VIEW IF EXISTS mv_daily_kpis;
DROP MATERIALIZED VIEW IF EXISTS mv_order_financials;

-- Views
DROP VIEW IF EXISTS
  v_customer_ltv,
  v_supplier_performance,
  v_abandoned_carts,
  v_coupon_redemptions,
  v_loyalty_balances,
  v_warehouse_utilization,
  v_returns_rate,
  v_review_summary,
  v_category_hierarchy,
  v_top_customers_month,
  v_sales_daily,
  v_suppliers_product_catalog,
  v_customers_default_address,
  v_products_inventory,
  v_orders_with_payment_shipment,
  v_order_items_detailed;

-- Tables (order matters due to FKs)
DROP TABLE IF EXISTS
  audit_events,
  user_sessions,
  ticket_messages,
  support_tickets,
  product_images,
  product_attributes,
  supplier_payments,
  purchase_order_items,
  purchase_orders,
  gift_cards,
  loyalty_ledger,
  loyalty_accounts,
  coupon_redemptions,
  coupons,
  returns,
  reviews,
  cart_items,
  carts,
  shipments,
  payments,
  order_items,
  orders,
  inventory,
  warehouses,
  products,
  categories,
  suppliers,
  addresses,
  customers
CASCADE;

-- Types last
DROP TYPE IF EXISTS ticket_priority CASCADE;
DROP TYPE IF EXISTS ticket_status CASCADE;
DROP TYPE IF EXISTS customer_status CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS shipment_status CASCADE;
DROP TYPE IF EXISTS order_status CASCADE;

-- ---------------------------
-- ENUM types
-- ---------------------------
CREATE TYPE order_status     AS ENUM ('pending','paid','shipped','delivered','cancelled');
CREATE TYPE shipment_status  AS ENUM ('preparing','shipped','in_transit','delivered','delayed');
CREATE TYPE payment_method   AS ENUM ('card','upi','netbanking','cod','wallet');
CREATE TYPE customer_status  AS ENUM ('active','inactive','suspended');
CREATE TYPE ticket_status    AS ENUM ('open','in_progress','resolved','closed');
CREATE TYPE ticket_priority  AS ENUM ('low','medium','high','urgent');

-- ----------------------------------
-- Core entities
-- ----------------------------------
CREATE TABLE customers (
  customer_id   BIGSERIAL PRIMARY KEY,
  full_name     TEXT        NOT NULL,
  email         TEXT        NOT NULL UNIQUE,
  phone         TEXT        CHECK (phone ~ '^\+?[0-9\-]{7,15}$'),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  status        customer_status NOT NULL DEFAULT 'active'
);

CREATE TABLE addresses (
  address_id    BIGSERIAL PRIMARY KEY,
  customer_id   BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  line1         TEXT   NOT NULL,
  city          TEXT   NOT NULL,
  state         TEXT   NOT NULL,
  country       TEXT   NOT NULL,
  postal_code   TEXT   NOT NULL,
  is_default    BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE UNIQUE INDEX uq_addresses_default_per_customer
  ON addresses(customer_id) WHERE is_default;

CREATE TABLE suppliers (
  supplier_id   BIGSERIAL PRIMARY KEY,
  name          TEXT        NOT NULL UNIQUE,
  email         TEXT,
  phone         TEXT,
  rating        INT         NOT NULL DEFAULT 3 CHECK (rating BETWEEN 1 AND 5),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE categories (
  category_id         BIGSERIAL PRIMARY KEY,
  name                TEXT NOT NULL UNIQUE,
  parent_category_id  BIGINT REFERENCES categories(category_id)
);

CREATE TABLE products (
  product_id   BIGSERIAL PRIMARY KEY,
  supplier_id  BIGINT NOT NULL REFERENCES suppliers(supplier_id),
  category_id  BIGINT NOT NULL REFERENCES categories(category_id),
  sku          TEXT   NOT NULL UNIQUE,
  name         TEXT   NOT NULL,
  price        NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  created_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
  discontinued BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX idx_products_supplier ON products(supplier_id);
CREATE INDEX idx_products_category ON products(category_id);

CREATE TABLE warehouses (
  warehouse_id BIGSERIAL PRIMARY KEY,
  name         TEXT NOT NULL UNIQUE,
  city         TEXT NOT NULL,
  state        TEXT NOT NULL
);

CREATE TABLE inventory (
  warehouse_id BIGINT NOT NULL REFERENCES warehouses(warehouse_id) ON DELETE CASCADE,
  product_id   BIGINT NOT NULL REFERENCES products(product_id)   ON DELETE CASCADE,
  quantity     INT    NOT NULL CHECK (quantity >= 0),
  PRIMARY KEY (warehouse_id, product_id)
);
CREATE INDEX idx_inventory_product ON inventory(product_id);

CREATE TABLE orders (
  order_id     BIGSERIAL PRIMARY KEY,
  customer_id  BIGINT NOT NULL REFERENCES customers(customer_id),
  order_date   DATE   NOT NULL DEFAULT CURRENT_DATE,
  status       order_status NOT NULL DEFAULT 'pending'
);
CREATE INDEX idx_orders_customer ON orders(customer_id);

CREATE TABLE order_items (
  order_item_id BIGSERIAL PRIMARY KEY,
  order_id      BIGINT NOT NULL REFERENCES orders(order_id)     ON DELETE CASCADE,
  product_id    BIGINT NOT NULL REFERENCES products(product_id),
  quantity      INT    NOT NULL CHECK (quantity > 0),
  unit_price    NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
  discount      NUMERIC(5,2)  NOT NULL DEFAULT 0 CHECK (discount >= 0 AND discount <= 100)
);
CREATE INDEX idx_order_items_order ON order_items(order_id);

CREATE TABLE payments (
  payment_id   BIGSERIAL PRIMARY KEY,
  order_id     BIGINT NOT NULL UNIQUE REFERENCES orders(order_id) ON DELETE CASCADE,
  method       payment_method NOT NULL,
  amount       NUMERIC(14,2)  NOT NULL CHECK (amount >= 0),
  paid_at      TIMESTAMPTZ
);

CREATE TABLE shipments (
  shipment_id  BIGSERIAL PRIMARY KEY,
  order_id     BIGINT NOT NULL UNIQUE REFERENCES orders(order_id) ON DELETE CASCADE,
  warehouse_id BIGINT NOT NULL REFERENCES warehouses(warehouse_id),
  shipped_at   TIMESTAMPTZ,
  status       shipment_status NOT NULL DEFAULT 'preparing',
  tracking_no  TEXT NOT NULL UNIQUE
);

-- ------------------------------------------------------
-- Extra domain richness
-- ------------------------------------------------------
CREATE TABLE carts (
  cart_id     BIGSERIAL PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES customers(customer_id),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_carts_customer ON carts(customer_id);

CREATE TABLE cart_items (
  cart_item_id BIGSERIAL PRIMARY KEY,
  cart_id      BIGINT NOT NULL REFERENCES carts(cart_id) ON DELETE CASCADE,
  product_id   BIGINT NOT NULL REFERENCES products(product_id),
  quantity     INT NOT NULL CHECK (quantity > 0)
);
CREATE UNIQUE INDEX uq_cart_product ON cart_items(cart_id, product_id);

CREATE TABLE reviews (
  review_id    BIGSERIAL PRIMARY KEY,
  product_id   BIGINT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
  customer_id  BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  rating       INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title        TEXT,
  body         TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_reviews_product ON reviews(product_id);

CREATE TABLE returns (
  return_id     BIGSERIAL PRIMARY KEY,
  order_item_id BIGINT NOT NULL REFERENCES order_items(order_item_id) ON DELETE CASCADE,
  reason        TEXT NOT NULL,
  approved      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE coupons (
  coupon_id   BIGSERIAL PRIMARY KEY,
  code        TEXT NOT NULL UNIQUE,
  description TEXT,
  pct_off     NUMERIC(5,2) CHECK (pct_off >= 0 AND pct_off <= 100),
  amount_off  NUMERIC(12,2) CHECK (amount_off >= 0),
  active      BOOLEAN NOT NULL DEFAULT TRUE,
  valid_from  DATE NOT NULL DEFAULT CURRENT_DATE,
  valid_to    DATE NOT NULL DEFAULT (CURRENT_DATE + 90)
);

CREATE TABLE coupon_redemptions (
  redemption_id BIGSERIAL PRIMARY KEY,
  coupon_id     BIGINT NOT NULL REFERENCES coupons(coupon_id),
  order_id      BIGINT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  redeemed_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uq_redemption_per_order ON coupon_redemptions(order_id);

CREATE TABLE loyalty_accounts (
  account_id  BIGSERIAL PRIMARY KEY,
  customer_id BIGINT NOT NULL UNIQUE REFERENCES customers(customer_id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE loyalty_ledger (
  ledger_id    BIGSERIAL PRIMARY KEY,
  account_id   BIGINT NOT NULL REFERENCES loyalty_accounts(account_id) ON DELETE CASCADE,
  points_delta INT NOT NULL,
  reason       TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE gift_cards (
  gift_card_id BIGSERIAL PRIMARY KEY,
  code         TEXT NOT NULL UNIQUE,
  balance      NUMERIC(12,2) NOT NULL CHECK (balance >= 0),
  active       BOOLEAN NO