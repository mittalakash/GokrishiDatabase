-- Gokrishi E-Commerce Platform Database Schema
-- Version 9.6
-- Made HSN Code Mandatory

-- NOTES:
-- - Version 9.6 makes the `hsn_code` column in the `products` table non-nullable (`NOT NULL`).
-- - This is a critical change to enforce GST compliance at the point of product creation.

SET NAMES utf8mb4;
SET time_zone = '+05:30';
SET foreign_key_checks = 0;

-- =============================================
-- Platform Configuration Table
-- =============================================

CREATE TABLE `platform_settings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `setting_key` VARCHAR(100) NOT NULL UNIQUE,
  `setting_value` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Language & Internationalization Tables
-- =============================================
CREATE TABLE `languages` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(10) NOT NULL UNIQUE COMMENT 'e.g., en-US, hi-IN',
  `name` VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Reference Data Tables
-- =============================================

CREATE TABLE `countries` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE,
  `iso_code_2` CHAR(2) NOT NULL UNIQUE,
  `phone_code` VARCHAR(10) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `states` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `country_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `cities` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `state_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`state_id`) REFERENCES `states` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `pincodes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `pincode` VARCHAR(10) NOT NULL UNIQUE,
  `city_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`city_id`) REFERENCES `cities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =============================================
-- Core User & Authentication Tables (v6.4)
-- =============================================

CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `is_admin` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag to identify platform administrators',
  `country_id` INT UNSIGNED NOT NULL,
  `primary_mobile` VARCHAR(15) NOT NULL,
  `password_hash` VARCHAR(255) NULL,
  `primary_email` VARCHAR(255) NULL UNIQUE,
  `google_id` VARCHAR(255) NULL UNIQUE,
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration to prevent duplicates.',
  `first_name` VARCHAR(100) NULL,
  `middle_name` VARCHAR(100) NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `legal_name` VARCHAR(300) NOT NULL,
  `profile_image_url` VARCHAR(512) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `is_mobile_verified` BOOLEAN NOT NULL DEFAULT FALSE,
  `is_email_verified` BOOLEAN NOT NULL DEFAULT FALSE,
  `preferred_language_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_mobile` (`country_id`, `primary_mobile`),
  FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`),
  FOREIGN KEY (`preferred_language_id`) REFERENCES `languages` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `user_sessions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `token` VARCHAR(255) NOT NULL UNIQUE,
  `active_account_type` ENUM('CUSTOMER', 'SELLER', 'SUPPLIER') NULL COMMENT 'The current operational context of the user',
  `active_account_id` BIGINT UNSIGNED NULL COMMENT 'The ID of the account (customer, seller, or supplier) being used',
  `ip_address` VARCHAR(45) NULL,
  `user_agent` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `user_session_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `session_token` VARCHAR(255) NOT NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_agent` TEXT NULL,
  `login_at` TIMESTAMP NOT NULL,
  `logout_at` TIMESTAMP NULL,
  `logout_reason` ENUM('USER_LOGOUT', 'SESSION_EXPIRED', 'ADMIN_TERMINATED') NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  INDEX `idx_user_session_history_login_at` (`login_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `otps` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `recipient` VARCHAR(255) NOT NULL COMMENT 'Mobile number or email address',
  `otp_hash` VARCHAR(255) NOT NULL COMMENT 'Hash of the one-time password (e.g., SHA-256)',
  `purpose` ENUM('LOGIN', 'VERIFY_MOBILE', 'VERIFY_EMAIL', 'RESET_PASSWORD') NOT NULL,
  `is_used` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_otp_recipient` (`recipient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `addresses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `address_line_1` VARCHAR(255) NOT NULL,
  `address_line_2` VARCHAR(255) NULL,
  `pincode_id` INT UNSIGNED NOT NULL,
  `latitude` DECIMAL(10, 8) NULL,
  `longitude` DECIMAL(11, 8) NULL,
  `address_type` ENUM('BILLING', 'DELIVERY') NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`pincode_id`) REFERENCES `pincodes` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Product Catalog Tables (v9.6)
-- =============================================

CREATE TABLE `brands` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NULL COMMENT 'The primary user account that owns the brand profile',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration.',
  `logo_url` VARCHAR(512) NULL,
  `logo_last_updated_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `brand_id` INT UNSIGNED NOT NULL,
    `language_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_brand_translation` (`brand_id`, `language_id`),
    FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_category_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`parent_category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `category_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category_id` INT UNSIGNED NOT NULL,
    `language_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_category_translation` (`category_id`, `language_id`),
    FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `products` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_id` INT UNSIGNED NOT NULL,
  `category_id` INT UNSIGNED NOT NULL,
  `product_type` ENUM('GOODS', 'SERVICE') NOT NULL DEFAULT 'GOODS',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration (Stock Item).',
  `hsn_code` VARCHAR(20) NOT NULL,
  `barcode` VARCHAR(100) NULL,
  `gst_percentage` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
  `cess_percentage` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
  `status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `created_by_seller_id` BIGINT UNSIGNED NULL,
  `managed_by_brand_id` INT UNSIGNED NULL COMMENT 'Brand with editorial control over this product listing',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`),
  FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`),
  FOREIGN KEY (`created_by_seller_id`) REFERENCES `sellers` (`id`) ON DELETE SET NULL,
  FOREIGN KEY (`managed_by_brand_id`) REFERENCES `brands` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `product_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `requested_by_seller_id` BIGINT UNSIGNED NOT NULL,
  `product_name` VARCHAR(255) NOT NULL,
  `brand_name` VARCHAR(150) NULL,
  `category_name` VARCHAR(150) NULL,
  `short_description` VARCHAR(500) NULL,
  `detailed_description` TEXT NULL,
  `hsn_code` VARCHAR(20) NULL,
  `barcode` VARCHAR(100) NULL,
  `gst_percentage` DECIMAL(5, 2) NULL,
  `cess_percentage` DECIMAL(5, 2) NULL,
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `approved_by_admin_id` BIGINT UNSIGNED NULL,
  `created_product_id` BIGINT UNSIGNED NULL COMMENT 'Link to the product created from this request',
  `rejection_reason` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`requested_by_seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`approved_by_admin_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  FOREIGN KEY (`created_product_id`) REFERENCES `products` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `product_request_images` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_request_id` BIGINT UNSIGNED NOT NULL,
  `image_url` VARCHAR(512) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_request_id`) REFERENCES `product_requests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `product_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL,
    `language_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(255) NOT NULL,
    `short_description` VARCHAR(500) NULL,
    `detailed_description` TEXT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_product_translation` (`product_id`, `language_id`),
    FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `product_units` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(50) NOT NULL COMMENT 'e.g., Packet, Crate, Box, Subscription',
  `conversion_rate` DECIMAL(10,2) NOT NULL DEFAULT 1.00 COMMENT 'Conversion to base unit. e.g. a crate has 24 packets.',
  `is_returnable_asset` BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `product_images` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `image_url` VARCHAR(512) NOT NULL,
  `source_url` VARCHAR(512) NULL,
  `is_scraped` BOOLEAN NOT NULL DEFAULT FALSE,
  `sort_order` INT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `product_change_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `requested_by_user_id` BIGINT UNSIGNED NOT NULL,
  `change_type` ENUM('IMAGES', 'UNITS', 'DESCRIPTION', 'DETAILS') NOT NULL COMMENT 'Categorizes the type of change requested.',
  `proposed_changes` JSON NOT NULL COMMENT 'JSON object containing the proposed new values.',
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'APPLIED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `rejection_reason` TEXT NULL,
  `approved_by_user_id` BIGINT UNSIGNED NULL,
  `approved_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`requested_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`approved_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =============================================
-- Seller & Inventory Tables (v9.4)
-- =============================================

CREATE TABLE `sellers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The primary user account that owns the seller profile',
  `is_platform_admin` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Identifies this seller as the platform itself, for billing other sellers',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration (Ledger).',
  `company_name` VARCHAR(255) NOT NULL,
  `company_logo_url` VARCHAR(512) NULL,
  `gst_number` VARCHAR(15) NULL UNIQUE,
  `gst_state_id` INT UNSIGNED NULL,
  `pan_number` VARCHAR(10) NULL,
  `account_status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`gst_state_id`) REFERENCES `states` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_subscription_plans` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plan_name` VARCHAR(150) NOT NULL,
  `monthly_fee` DECIMAL(10, 2) NOT NULL,
  `setup_fee` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `features` JSON NULL COMMENT 'JSON array of features included, e.g. ["WHITELABEL", "GST_REPORTING", "FINANCIAL_REPORTING", "ACCOUNTING_SYNC"].',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_subscriptions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `plan_id` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELLED') NOT NULL,
  `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `renews_at` TIMESTAMP NULL,
  `cancelled_at` TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_subscription` (`seller_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`plan_id`) REFERENCES `seller_subscription_plans` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_whitelabel_settings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `is_enabled` BOOLEAN NOT NULL DEFAULT TRUE,
  `portal_custom_domain` VARCHAR(255) NULL UNIQUE,
  `portal_theme_color` VARCHAR(7) NULL,
  `app_name` VARCHAR(100) NULL,
  `app_bundle_id` VARCHAR(100) NULL UNIQUE,
  `app_icon_url` VARCHAR(512) NULL,
  `app_splash_screen_url` VARCHAR(512) NULL,
  `app_store_id` VARCHAR(100) NULL,
  `apple_app_store_id` VARCHAR(100) NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_whitelabel_settings` (`seller_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `whitelabel_promo_campaigns` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seller_id` BIGINT UNSIGNED NOT NULL,
    `campaign_name` VARCHAR(255) NOT NULL,
    `promo_code` VARCHAR(50) NOT NULL UNIQUE,
    `target_url` VARCHAR(512) NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `whitelabel_traffic_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `campaign_id` BIGINT UNSIGNED NOT NULL,
    `source` VARCHAR(100) NULL COMMENT 'e.g., facebook, twitter, email',
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `visited_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`campaign_id`) REFERENCES `whitelabel_promo_campaigns` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_document_branding` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `accent_color` VARCHAR(7) NULL,
  `header` TEXT NULL,
  `footer` TEXT NULL,
  `show_platform_logo` BOOLEAN NOT NULL DEFAULT TRUE,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_document_branding_seller_id` (`seller_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- A customer can be a user or a brand. This table maps them to a seller.
-- Application logic should ensure that either user_id or brand_id is set.
CREATE TABLE `seller_customer_map` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NULL COMMENT 'The user who is the customer. Null if brand_id is set.',
  `brand_id` INT UNSIGNED NULL COMMENT 'The brand that is the customer. Null if user_id is set.',
  `seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'The seller in this relationship',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration (Ledger for this specific relationship).',
  `price_list_id` BIGINT UNSIGNED NULL,
  `credit_limit_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `running_balance` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `unsettled_payments_balance` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Sum of payments pending clearance (e.g., cheques).',
  `unsettled_returnable_assets_balance` INT NOT NULL DEFAULT 0 COMMENT 'Sum of assets pending verification.',
  `alias_name` VARCHAR(100) NULL COMMENT 'The alias the seller uses for this customer',
  `status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'INACTIVE', 'UNSERVICEABLE', 'BLACKLISTED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `status_reason` TEXT NULL COMMENT 'Reason for the current status',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_user_customer` (`seller_id`, `user_id`),
  UNIQUE KEY `uk_seller_brand_customer` (`seller_id`, `brand_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`price_list_id`) REFERENCES `price_lists` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_customer_type` CHECK (`user_id` IS NOT NULL OR `brand_id` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_staff` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `salary_structure` ENUM('DAILY', 'MONTHLY', 'COMMISSION_BASED') NOT NULL DEFAULT 'MONTHLY',
  `daily_rate` DECIMAL(10, 2) NULL COMMENT 'Applicable if salary_structure is DAILY',
  `monthly_salary` DECIMAL(10, 2) NULL COMMENT 'Applicable if salary_structure is MONTHLY',
  `commission_rate` DECIMAL(5, 2) NULL COMMENT 'Percentage, applicable if salary_structure is COMMISSION_BASED',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_user` (`seller_id`, `user_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_staff_roles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_name` VARCHAR(100) NOT NULL UNIQUE,
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_staff_role_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `staff_id` BIGINT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_staff_role` (`staff_id`, `role_id`),
  FOREIGN KEY (`staff_id`) REFERENCES `seller_staff` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`role_id`) REFERENCES `seller_staff_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_product_units` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `product_unit_id` BIGINT UNSIGNED NOT NULL,
  `mrp` DECIMAL(10, 2) NULL COMMENT 'Maximum Retail Price, serves as the base for pricing.',
  `purchase_rate` DECIMAL(10, 2) NULL,
  `selling_rate` DECIMAL(10, 2) NOT NULL,
  `stock_quantity` INT NULL COMMENT 'Null if inventory is not tracked for this unit (e.g. for services)',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `is_out_of_stock` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_product_unit` (`seller_id`, `product_unit_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_unit_id`) REFERENCES `product_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `price_lists` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `price_list_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `price_list_id` BIGINT UNSIGNED NOT NULL,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
  `discount_type` ENUM('FIXED', 'PERCENTAGE') NOT NULL,
  `discount_value` DECIMAL(10, 2) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`price_list_id`) REFERENCES `price_lists` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =============================================
-- Customer & Order Tables (v9.5)
-- =============================================

CREATE TABLE `customer_returnable_assets` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `product_unit_id` BIGINT UNSIGNED NOT NULL,
  `balance` INT NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_customer_returnable` (`seller_customer_map_id`, `product_unit_id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_unit_id`) REFERENCES `product_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `customer_unsettled_items_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `item_type` ENUM('PAYMENT', 'RETURNABLE_ASSET') NOT NULL,
  `reference_id` BIGINT UNSIGNED NOT NULL COMMENT 'e.g., payment_transactions.id, returnable_asset_collections.id',
  `description` VARCHAR(255) NOT NULL,
  `amount_or_quantity` DECIMAL(12, 2) NOT NULL,
  `status` VARCHAR(100) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `settled_at` TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`) ON DELETE CASCADE,
  INDEX `idx_unsettled_items_customer` (`seller_customer_map_id`, `settled_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `orders` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `order_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `scheduled_delivery_date` DATE NULL COMMENT 'If not null, the order is scheduled for a future date.',
  `scheduled_delivery_shift_id` BIGINT UNSIGNED NULL COMMENT 'The specific delivery shift for a scheduled order.',
  `total_amount` DECIMAL(10, 2) NOT NULL,
  `order_status` ENUM('SCHEDULED', 'PENDING', 'CONFIRMED', 'DISPATCHED', 'DELIVERED', 'CANCELLED', 'DELIVERY_MODIFIED') NOT NULL,
  `delivery_address_id` BIGINT UNSIGNED NULL COMMENT 'Can be null for service products',
  `delivery_type` ENUM('PICKUP', 'SELLER_DELIVERY', 'THIRD_PARTY_DELIVERY', 'NOT_APPLICABLE') NOT NULL,
  `cancellation_reason` TEXT NULL,
  `is_mapped_to_load` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Whether this order has been assigned to a delivery load',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`),
  FOREIGN KEY (`delivery_address_id`) REFERENCES `addresses` (`id`),
  FOREIGN KEY (`scheduled_delivery_shift_id`) REFERENCES `delivery_shifts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `order_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT UNSIGNED NOT NULL,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL,
  `taxable_value` DECIMAL(10, 2) NOT NULL COMMENT 'The base price per unit before taxes',
  `cgst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `sgst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `igst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `cess_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `net_amount` DECIMAL(10, 2) NOT NULL COMMENT 'The final price per unit, inclusive of all taxes (taxable_value + taxes)',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `subscriptions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL,
  `frequency` VARCHAR(50) NOT NULL COMMENT 'e.g., daily, weekly, custom cron string',
  `status` ENUM('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELED') NOT NULL DEFAULT 'ACTIVE',
  `start_date` DATE NOT NULL,
  `trial_ends_at` TIMESTAMP NULL,
  `end_date` DATE NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`),
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_customer_route_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `delivery_route_id` BIGINT UNSIGNED NOT NULL,
  `delivery_shift_id` BIGINT UNSIGNED NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_customer_route_shift` (`seller_customer_map_id`, `delivery_route_id`, `delivery_shift_id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`delivery_route_id`) REFERENCES `delivery_routes` (`id`),
  FOREIGN KEY (`delivery_shift_id`) REFERENCES `delivery_shifts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Financial Reconciliation & Expense Management Module (v9.2)
-- =============================================

CREATE TABLE `seller_accounts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `account_name` VARCHAR(150) NOT NULL,
  `account_type` ENUM('CASH', 'BANK', 'E_WALLET') NOT NULL,
  `account_number` VARCHAR(50) NULL COMMENT 'For BANK accounts',
  `bank_name` VARCHAR(150) NULL COMMENT 'For BANK accounts',
  `ifsc_code` VARCHAR(20) NULL COMMENT 'For BANK accounts',
  `current_balance` DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `account_entries` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `transaction_type` ENUM('CUSTOMER_PAYMENT', 'REFUND', 'PAYROLL_PAYMENT', 'SUPPLIER_PAYMENT', 'EXPENSE', 'CASH_DEPOSIT', 'INTERNAL_TRANSFER') NOT NULL,
  `reference_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID of the source transaction (e.g., payment_transactions.id, expenses.id, account_transfers.id)',
  `entry_type` ENUM('DEBIT', 'CREDIT') NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `balance_after_transaction` DECIMAL(14, 2) NOT NULL,
  `narration` TEXT NULL,
  `entry_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`account_id`) REFERENCES `seller_accounts` (`id`) ON DELETE CASCADE,
  INDEX `idx_reference` (`transaction_type`, `reference_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `account_transfers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `from_account_id` BIGINT UNSIGNED NOT NULL,
  `to_account_id` BIGINT UNSIGNED NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `transfer_date` DATE NOT NULL,
  `status` ENUM('PENDING', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
  `notes` TEXT NULL,
  `initiated_by_user_id` BIGINT UNSIGNED NOT NULL,
  `completed_by_user_id` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`from_account_id`) REFERENCES `seller_accounts` (`id`),
  FOREIGN KEY (`to_account_id`) REFERENCES `seller_accounts` (`id`),
  FOREIGN KEY (`initiated_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`completed_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `expense_categories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(150) NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `expenses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `expense_category_id` BIGINT UNSIGNED NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `expense_date` DATE NOT NULL,
  `paid_from_account_id` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `incurred_by_staff_id` BIGINT UNSIGNED NULL,
  `approved_by_staff_id` BIGINT UNSIGNED NULL,
  `approved_at` TIMESTAMP NULL,
  `rejection_reason` TEXT NULL,
  `notes` TEXT NULL,
  `receipt_url` VARCHAR(512) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`expense_category_id`) REFERENCES `expense_categories` (`id`),
  FOREIGN KEY (`paid_from_account_id`) REFERENCES `seller_accounts` (`id`),
  FOREIGN KEY (`incurred_by_staff_id`) REFERENCES `seller_staff` (`id`),
  FOREIGN KEY (`approved_by_staff_id`) REFERENCES `seller_staff` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =============================================
-- Billing & Payment Module (v9.3)
-- =============================================

CREATE TABLE `invoices` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT UNSIGNED NOT NULL,
  `invoice_number` VARCHAR(50) NOT NULL UNIQUE,
  `invoice_date` DATE NOT NULL,
  `due_date` DATE NOT NULL,
  `total_amount` DECIMAL(12, 2) NOT NULL,
  `transaction_fee_amount` DECIMAL(12, 2) NULL COMMENT 'Fee added to the invoice if the customer bears the transaction cost',
  `status` ENUM('DRAFT', 'SENT', 'PAID', 'PARTIALLY_PAID', 'VOID') NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `payment_gateway_providers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'e.g., Razorpay, PayU, Stripe',
  `transaction_fee_percentage` DECIMAL(5, 2) NULL COMMENT 'Percentage-based fee charged by the gateway',
  `transaction_fee_fixed` DECIMAL(10, 2) NULL COMMENT 'Fixed fee charged by the gateway',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Platform-wide switch for this provider',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_payment_gateways` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `provider_id` INT UNSIGNED NOT NULL,
  `display_name` VARCHAR(150) NOT NULL,
  `api_key_secret_ref` VARCHAR(255) NOT NULL COMMENT 'Reference to a secret manager key for the seller\'s API key',
  `api_secret_secret_ref` VARCHAR(255) NOT NULL COMMENT 'Reference to a secret manager key for the seller\'s API secret',
  `transaction_fee_bearer` ENUM('SELLER', 'CUSTOMER') NOT NULL DEFAULT 'SELLER' COMMENT 'Determines who bears the transaction fee',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Seller-specific switch for this gateway configuration',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_provider` (`seller_id`, `provider_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`provider_id`) REFERENCES `payment_gateway_providers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `payment_transactions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_id` BIGINT UNSIGNED NULL,
  `account_id` BIGINT UNSIGNED NOT NULL COMMENT 'The seller account affected by this transaction',
  `seller_customer_map_id` BIGINT UNSIGNED NULL COMMENT 'Null for non-customer transactions like payroll',
  `staff_id` BIGINT UNSIGNED NULL COMMENT 'Reference to staff for payroll payments',
  `supplier_id` BIGINT UNSIGNED NULL COMMENT 'Reference to supplier for supplier payments',
  `transaction_type` ENUM('CUSTOMER_PAYMENT', 'REFUND', 'PAYROLL_PAYMENT', 'SUPPLIER_PAYMENT') NOT NULL,
  `seller_payment_gateway_id` BIGINT UNSIGNED NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `method` ENUM('CASH', 'BANK_TRANSFER', 'UPI', 'WEB_GATEWAY', 'CHEQUE', 'OTHER') NOT NULL COMMENT 'CHEQUE method is for seller-side data entry only.',
  `status` ENUM('PENDING', 'PENDING_DEPOSIT', 'PENDING_CLEARANCE', 'SUCCESSFUL', 'FAILED', 'BOUNCED', 'VOID') NOT NULL DEFAULT 'PENDING',
  `gateway_order_id` VARCHAR(255) NULL,
  `gateway_payment_id` VARCHAR(255) NULL,
  `gateway_fee_amount` DECIMAL(12, 2) NULL COMMENT 'The actual fee charged by the payment gateway for this transaction',
  `transaction_fee_paid_by_customer` DECIMAL(12, 2) NULL COMMENT 'The portion of the gateway fee passed on to the customer',
  `cheque_number` VARCHAR(50) NULL,
  `cheque_date` DATE NULL,
  `cheque_bank_name` VARCHAR(150) NULL,
  `cheque_front_image_url` VARCHAR(512) NULL COMMENT 'URL of compressed front image of the cheque',
  `cheque_back_image_url` VARCHAR(512) NULL COMMENT 'URL of compressed back image of the cheque',
  `voucher_entry_id` BIGINT UNSIGNED NULL,
  `confirmed_by_user_id` BIGINT UNSIGNED NULL COMMENT 'The user (staff) who manually confirmed the payment',
  `confirmation_notes` TEXT NULL,
  `voided_by_user_id` BIGINT UNSIGNED NULL COMMENT 'The user (staff) who voided the transaction',
  `void_notes` TEXT NULL,
  `voided_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`),
  FOREIGN KEY (`account_id`) REFERENCES `seller_accounts`(`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`),
  FOREIGN KEY (`staff_id`) REFERENCES `seller_staff` (`id`),
  FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`),
  FOREIGN KEY (`seller_payment_gateway_id`) REFERENCES `seller_payment_gateways` (`id`),
  FOREIGN KEY (`voucher_entry_id`) REFERENCES `voucher_entries` (`id`),
  FOREIGN KEY (`confirmed_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`voided_by_user_id`) REFERENCES `users` (`id`),
  INDEX `idx_transaction_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `cheque_deposits` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `deposited_into_account_id` BIGINT UNSIGNED NOT NULL,
  `deposit_date` DATE NOT NULL,
  `total_amount` DECIMAL(12, 2) NOT NULL,
  `deposit_slip_image_url` VARCHAR(512) NULL COMMENT 'URL of the compressed deposit slip image',
  `status` ENUM('PENDING_CLEARANCE', 'COMPLETED', 'PARTIALLY_CLEARED', 'BOUNCED') NOT NULL,
  `deposited_by_user_id` BIGINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`deposited_into_account_id`) REFERENCES `seller_accounts` (`id`),
  FOREIGN KEY (`deposited_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `cheque_deposit_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cheque_deposit_id` BIGINT UNSIGNED NOT NULL,
  `payment_transaction_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cheque_deposit_item` (`cheque_deposit_id`, `payment_transaction_id`),
  FOREIGN KEY (`cheque_deposit_id`) REFERENCES `cheque_deposits` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`payment_transaction_id`) REFERENCES `payment_transactions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `payment_refunds` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `payment_transaction_id` BIGINT UNSIGNED NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `reason` TEXT NULL,
  `status` ENUM('PENDING', 'PROCESSED', 'FAILED') NOT NULL DEFAULT 'PENDING',
  `gateway_refund_id` VARCHAR(255) NULL,
  `voucher_entry_id` BIGINT UNSIGNED NULL COMMENT 'Link to the credit note voucher',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`payment_transaction_id`) REFERENCES `payment_transactions` (`id`),
  FOREIGN KEY (`voucher_entry_id`) REFERENCES `voucher_entries` (`id`),
  INDEX `idx_refund_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `payment_events` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `payment_transaction_id` BIGINT UNSIGNED NOT NULL,
  `payment_refund_id` BIGINT UNSIGNED NULL,
  `event_type` ENUM(
    'TRANSACTION_CREATED',
    'TRANSACTION_SUCCESSFUL',
    'TRANSACTION_FAILED',
    'TRANSACTION_VOIDED',
    'REFUND_INITIATED',
    'REFUND_PROCESSED',
    'REFUND_FAILED',
    'GATEWAY_WEBHOOK_RECEIVED',
    'GATEWAY_API_POLL',
    'MANUAL_CONFIRMATION'
  ) NOT NULL,
  `event_source` ENUM('INTERNAL', 'GATEWAY') NOT NULL,
  `event_data` JSON NULL COMMENT 'Data associated with the event, e.g., raw webhook payload, API poll response, confirmation/void notes',
  `is_processed` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'For async events, tracks if business logic has been executed.',
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  FOREIGN KEY (`payment_transaction_id`) REFERENCES `payment_transactions` (`id`),
  FOREIGN KEY (`payment_refund_id`) REFERENCES `payment_refunds` (`id`),
  INDEX `idx_event_processing` (`is_processed`, `event_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Communication & Support Tables (v6.4)
-- =============================================

CREATE TABLE `notifications` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The user who receives the notification',
  `notification_type` VARCHAR(100) NOT NULL COMMENT 'e.g., ORDER_STATUS_UPDATE, NEW_MESSAGE, SUBSCRIPTION_REMINDER',
  `content` TEXT NOT NULL,
  `reference_type` VARCHAR(100) NULL COMMENT 'e.g., ORDER, MESSAGE, USER',
  `reference_id` BIGINT UNSIGNED NULL,
  `is_read` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  INDEX `idx_notification_user_read` (`user_id`, `is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `messages` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `sender_user_id` BIGINT UNSIGNED NOT NULL,
  `recipient_user_id` BIGINT UNSIGNED NOT NULL,
  `message_body` TEXT NOT NULL,
  `sent_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `read_at` TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`sender_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`recipient_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `support_tickets` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `created_by_user_id` BIGINT UNSIGNED NOT NULL,
  `recipient_user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The user this ticket is directed to (can be an admin or a seller)',
  `assigned_to_staff_id` BIGINT UNSIGNED NULL COMMENT 'Which specific staff member of the recipient is handling it',
  `context_type` VARCHAR(100) NULL COMMENT 'e.g., ORDER, PAYMENT, PRODUCT_RETURN',
  `context_id` BIGINT UNSIGNED NULL,
  `subject` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL COMMENT 'The initial message from the creator of the ticket.',
  `status` ENUM('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED') NOT NULL DEFAULT 'OPEN',
  `priority` ENUM('LOW', 'MEDIUM', 'HIGH') NOT NULL DEFAULT 'MEDIUM',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`recipient_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`assigned_to_staff_id`) REFERENCES `seller_staff` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `support_ticket_replies` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ticket_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The user who wrote the reply',
  `reply_body` TEXT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`ticket_id`) REFERENCES `support_tickets` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =============================================
-- Brand Engagement & Monetization Module (v7.1)
-- =============================================

CREATE TABLE `brand_staff` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_id` INT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_user` (`brand_id`, `user_id`),
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_staff_roles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_name` VARCHAR(100) NOT NULL UNIQUE,
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_staff_role_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `staff_id` BIGINT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_staff_role` (`staff_id`, `role_id`),
  FOREIGN KEY (`staff_id`) REFERENCES `brand_staff` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`role_id`) REFERENCES `brand_staff_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_whitelabel_subscription_plans` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plan_name` VARCHAR(150) NOT NULL,
  `monthly_fee` DECIMAL(10, 2) NOT NULL,
  `setup_fee` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `features` JSON NULL COMMENT 'JSON array of features included in the plan.',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_whitelabel_subscriptions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_id` INT UNSIGNED NOT NULL,
  `plan_id` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELLED') NOT NULL,
  `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `renews_at` TIMESTAMP NULL,
  `cancelled_at` TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_whitelabel_subscription` (`brand_id`),
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`plan_id`) REFERENCES `brand_whitelabel_subscription_plans` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_whitelabel_settings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_id` INT UNSIGNED NOT NULL,
  `portal_custom_domain` VARCHAR(255) NULL UNIQUE,
  `portal_theme_color` VARCHAR(7) NULL,
  `app_name` VARCHAR(100) NULL,
  `app_bundle_id` VARCHAR(100) NULL UNIQUE,
  `app_icon_url` VARCHAR(512) NULL,
  `app_splash_screen_url` VARCHAR(512) NULL,
  `app_store_id` VARCHAR(100) NULL,
  `apple_app_store_id` VARCHAR(100) NULL,
  `auto_add_new_products` BOOLEAN NOT NULL DEFAULT TRUE,
  `auto_add_new_sellers` BOOLEAN NOT NULL DEFAULT TRUE,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_whitelabel_settings` (`brand_id`),
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_whitelabel_visible_products` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_whitelabel_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `is_visible` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_whitelabel_product` (`brand_whitelabel_id`, `product_id`),
  FOREIGN KEY (`brand_whitelabel_id`) REFERENCES `brand_whitelabel_settings` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_whitelabel_visible_sellers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_whitelabel_id` BIGINT UNSIGNED NOT NULL,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `is_visible` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_whitelabel_seller` (`brand_whitelabel_id`, `seller_id`),
  FOREIGN KEY (`brand_whitelabel_id`) REFERENCES `brand_whitelabel_settings` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_whitelabel_promo_campaigns` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `brand_id` INT UNSIGNED NOT NULL,
    `campaign_name` VARCHAR(255) NOT NULL,
    `promo_code` VARCHAR(50) NOT NULL UNIQUE,
    `target_url` VARCHAR(512) NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_whitelabel_traffic_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `campaign_id` BIGINT UNSIGNED NOT NULL,
    `source` VARCHAR(100) NULL COMMENT 'e.g., facebook, twitter, email',
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `visited_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`campaign_id`) REFERENCES `brand_whitelabel_promo_campaigns` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `brand_data_subscriptions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_id` INT UNSIGNED NOT NULL,
  `plan_id` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELLED') NOT NULL,
  `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `renews_at` TIMESTAMP NULL,
  `cancelled_at` TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_data_subscription` (`brand_id`),
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`plan_id`) REFERENCES `whitelabel_subscription_plans` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ad_placements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `dimensions` VARCHAR(50) NULL COMMENT 'e.g., 300x250, 728x90',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ad_campaigns` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `status` ENUM('DRAFT', 'ACTIVE', 'PAUSED', 'COMPLETED') NOT NULL DEFAULT 'DRAFT',
  `budget` DECIMAL(12, 2) NULL,
  `start_date` DATETIME NOT NULL,
  `end_date` DATETIME NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ad_creatives` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `campaign_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `ad_placement_id` BIGINT UNSIGNED NOT NULL,
  `image_url` VARCHAR(512) NULL,
  `video_url` VARCHAR(512) NULL,
  `ad_text` TEXT NULL,
  `target_url` VARCHAR(512) NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`campaign_id`) REFERENCES `ad_campaigns` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`ad_placement_id`) REFERENCES `ad_placements` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ad_impressions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ad_creative_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_agent` TEXT NULL,
  `impression_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`ad_creative_id`) REFERENCES `ad_creatives` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `ad_clicks` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ad_creative_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_agent` TEXT NULL,
  `click_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`ad_creative_id`) REFERENCES `ad_creatives` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Scheduled & Audited Pricing Module (v8.0)
-- =============================================

CREATE TABLE `product_price_change_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
  `requested_by_user_id` BIGINT UNSIGNED NOT NULL,
  `old_mrp` DECIMAL(10, 2) NOT NULL,
  `new_mrp` DECIMAL(10, 2) NOT NULL,
  `old_selling_rate` DECIMAL(10, 2) NOT NULL,
  `new_selling_rate` DECIMAL(10, 2) NOT NULL,
  `old_purchase_rate` DECIMAL(10, 2) NULL,
  `new_purchase_rate` DECIMAL(10, 2) NULL,
  `effective_date` DATETIME NOT NULL,
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'SCHEDULED', 'APPLIED', 'CANCELLED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `update_suggestion_details` JSON NULL COMMENT 'Audit log of how new prices were calculated (e.g., REFERENCE_AMOUNT, PERCENTAGE, MANUAL).',
  `rejection_reason` TEXT NULL,
  `approved_by_user_id` BIGINT UNSIGNED NULL,
  `approved_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`requested_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`approved_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `price_change_notifications` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `price_change_request_id` BIGINT UNSIGNED NOT NULL,
    `target_type` ENUM('SELLER', 'CUSTOMER_SUBSCRIPTION') NOT NULL,
    `seller_id` BIGINT UNSIGNED NULL,
    `subscription_id` BIGINT UNSIGNED NULL,
    `notification_id` BIGINT UNSIGNED NOT NULL COMMENT 'Link to the master notifications table',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`price_change_request_id`) REFERENCES `product_price_change_requests` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`subscription_id`) REFERENCES `subscriptions` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`notification_id`) REFERENCES `notifications` (`id`) ON DELETE CASCADE,
    CONSTRAINT `chk_notification_target` CHECK (`seller_id` IS NOT NULL OR `subscription_id` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Scheduled & Audited Tax Module (v8.2)
-- =============================================

CREATE TABLE `product_tax_change_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `requested_by_user_id` BIGINT UNSIGNED NOT NULL,
  `old_gst_percentage` DECIMAL(5, 2) NOT NULL,
  `new_gst_percentage` DECIMAL(5, 2) NOT NULL,
  `old_cess_percentage` DECIMAL(5, 2) NOT NULL,
  `new_cess_percentage` DECIMAL(5, 2) NOT NULL,
  `effective_date` DATETIME NOT NULL,
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'SCHEDULED', 'APPLIED', 'CANCELLED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `rejection_reason` TEXT NULL,
  `approved_by_user_id` BIGINT UNSIGNED NULL,
  `approved_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`requested_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`approved_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `tax_change_notifications` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tax_change_request_id` BIGINT UNSIGNED NOT NULL,
    `seller_id` BIGINT UNSIGNED NOT NULL,
    `notification_id` BIGINT UNSIGNED NOT NULL COMMENT 'Link to the master notifications table',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`tax_change_request_id`) REFERENCES `product_tax_change_requests` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`notification_id`) REFERENCES `notifications` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- GST Reporting & Filing Module (v8.3)
-- =============================================

CREATE TABLE `gst_report_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'e.g., GSTR-1, GSTR-3B',
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `gst_report_generations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `report_type_id` INT UNSIGNED NOT NULL,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `generated_by_user_id` BIGINT UNSIGNED NOT NULL,
  `reporting_period_start` DATE NOT NULL,
  `reporting_period_end` DATE NOT NULL,
  `status` ENUM('PENDING', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'PENDING',
  `output_format` ENUM('CSV', 'JSON', 'XLSX') NOT NULL,
  `output_file_url` VARCHAR(512) NULL,
  `generation_job_id` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`report_type_id`) REFERENCES `gst_report_types` (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`generated_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`generation_job_id`) REFERENCES `scheduled_jobs` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Financial Reporting & Analysis Module (v8.4)
-- =============================================

CREATE TABLE `financial_report_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'e.g., Balance Sheet, Profit & Loss Statement',
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `financial_report_generations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `report_type_id` INT UNSIGNED NOT NULL,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `generated_by_user_id` BIGINT UNSIGNED NOT NULL,
  `reporting_period_start` DATE NOT NULL,
  `reporting_period_end` DATE NOT NULL,
  `status` ENUM('PENDING', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'PENDING',
  `output_format` ENUM('PDF', 'XLSX') NOT NULL,
  `output_file_url` VARCHAR(512) NULL,
  `generation_job_id` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`report_type_id`) REFERENCES `financial_report_types` (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`generated_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`generation_job_id`) REFERENCES `scheduled_jobs` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Seller Data Onboarding Module (v8.5)
-- =============================================

CREATE TABLE `customer_import_jobs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `initiated_by_user_id` BIGINT UNSIGNED NOT NULL,
  `source_type` ENUM('TALLY', 'BUSY', 'MARG', 'CSV') NOT NULL,
  `source_file_url` VARCHAR(512) NULL,
  `status` ENUM('UPLOADED', 'PENDING_REVIEW', 'REVIEW_APPROVED', 'PROCESSING', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'UPLOADED',
  `error_details` TEXT NULL,
  `approved_by_user_id` BIGINT UNSIGNED NULL,
  `approved_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`initiated_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`approved_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `customer_import_staging` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `import_job_id` BIGINT UNSIGNED NOT NULL,
  `customer_name` VARCHAR(300) NOT NULL,
  `mobile_number` VARCHAR(15) NOT NULL,
  `email` VARCHAR(255) NULL,
  `address_line_1` VARCHAR(255) NULL,
  `address_line_2` VARCHAR(255) NULL,
  `pincode` VARCHAR(10) NULL,
  `opening_balance` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `returnable_asset_balance` INT NOT NULL DEFAULT 0,
  `returnable_asset_unit_name` VARCHAR(50) NULL COMMENT 'e.g., Crate, Box. For matching with product_units',
  `status` ENUM('PENDING_VALIDATION', 'VALIDATED_NEW', 'VALIDATED_MATCHED', 'INVALID_DATA', 'PROCESSED', 'ERROR') NOT NULL DEFAULT 'PENDING_VALIDATION',
  `matched_user_id` BIGINT UNSIGNED NULL COMMENT 'The existing user_id if a match is found',
  `validation_errors` JSON NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`import_job_id`) REFERENCES `customer_import_jobs` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`matched_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Accounting Synchronization Module (v8.6)
-- =============================================

CREATE TABLE `seller_accounting_sync_settings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `provider` ENUM('TALLY', 'BUSY', 'MARG') NOT NULL,
  `is_enabled` BOOLEAN NOT NULL DEFAULT FALSE,
  `sync_direction` ENUM('IMPORT', 'EXPORT', 'BIDIRECTIONAL') NOT NULL,
  `sync_options` JSON NOT NULL COMMENT 'JSON object specifying what to sync, e.g. { "invoices": true, "payments": true }',
  `last_sync_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_accounting_sync` (`seller_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `accounting_sync_queue` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `entity_type` VARCHAR(100) NOT NULL COMMENT 'e.g., INVOICE, PAYMENT, EXPENSE',
  `entity_id` BIGINT UNSIGNED NOT NULL,
  `action` ENUM('CREATE', 'UPDATE', 'DELETE') NOT NULL,
  `status` ENUM('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'PENDING',
  `attempts` INT NOT NULL DEFAULT 0,
  `last_attempt_at` TIMESTAMP NULL,
  `error_message` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  INDEX `idx_sync_queue_status` (`status`, `seller_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Subscription Lifecycle Management Module (v8.7)
-- =============================================

CREATE TABLE `feature_deactivation_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `feature_name` VARCHAR(100) NOT NULL COMMENT 'e.g., WHITELABEL, ACCOUNTING_SYNC',
  `deactivated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reason` TEXT NULL COMMENT 'e.g., Subscription status changed to PAST_DUE',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Seller Store Operations Module (v8.9)
-- =============================================

CREATE TABLE `seller_store_settings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `is_open` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Master switch controlled by schedules, holidays, and admin overrides.',
  `force_closed_by_admin` BOOLEAN NOT NULL DEFAULT FALSE,
  `force_closure_reason` TEXT NULL,
  `next_opening_time` TIMESTAMP NULL COMMENT 'Timestamp for when the store will automatically reopen after a holiday or scheduled closure.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_store_settings` (`seller_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_operating_slots` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `delivery_shift_id` BIGINT UNSIGNED NOT NULL COMMENT 'The delivery shift for which orders are taken during this slot.',
  `slot_name` VARCHAR(100) NOT NULL COMMENT 'e.g., Morning Orders, Evening Orders',
  `day_of_week` ENUM('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY') NOT NULL,
  `open_time` TIME NOT NULL,
  `close_time` TIME NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`delivery_shift_id`) REFERENCES `delivery_shifts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_holiday_overrides` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `start_date` TIMESTAMP NOT NULL,
  `end_date` TIMESTAMP NOT NULL,
  `reason` VARCHAR(255) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Balance Adjustment Module (v9.2)
-- =============================================

CREATE TABLE `returnable_asset_adjustments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `product_unit_id` BIGINT UNSIGNED NOT NULL,
  `adjusted_quantity` INT NOT NULL COMMENT 'The change in quantity (can be positive or negative).',
  `reason` TEXT NULL,
  `adjusted_by_user_id` BIGINT UNSIGNED NOT NULL,
  `adjusted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_unit_id`) REFERENCES `product_units` (`id`),
  FOREIGN KEY (`adjusted_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =============================================
-- Logging & Miscellaneous Tables
-- =============================================

CREATE TABLE `audit_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NULL,
  `action` VARCHAR(255) NOT NULL,
  `target_type` VARCHAR(100) NULL,
  `target_id` BIGINT UNSIGNED NULL,
  `details` JSON NULL,
  `ip_address` VARCHAR(45) NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Product Returns
-- =============================================

CREATE TABLE `product_returns` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_item_id` BIGINT UNSIGNED NOT NULL COMMENT 'The specific item from an order that is being returned',
  `quantity` INT UNSIGNED NOT NULL COMMENT 'Number of units of the item returned',
  `reason` TEXT NULL COMMENT 'Reason for the return provided by the customer or staff',
  `status` ENUM('REQUESTED', 'APPROVED', 'REJECTED', 'PROCESSED') NOT NULL DEFAULT 'REQUESTED' COMMENT 'Tracks the state of the return process',
  `requested_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `processed_at` TIMESTAMP NULL COMMENT 'Timestamp when the return was finalized (approved/rejected)',
  `voucher_entry_id` BIGINT UNSIGNED NULL COMMENT 'Link to the financial credit note entry in the voucher system',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Supplier & Procurement Tables (v6.5)
-- =============================================

CREATE TABLE `suppliers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration (Ledger).',
  `company_name` VARCHAR(255) NOT NULL,
  `company_logo_url` VARCHAR(512) NULL,
  `gst_number` VARCHAR(15) NULL UNIQUE,
  `pan_number` VARCHAR(10) NULL,
  `account_status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_supplier_map` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `supplier_id` BIGINT UNSIGNED NOT NULL,
  `seller_alias_for_supplier` VARCHAR(100) NULL COMMENT 'The alias the seller uses for this supplier',
  `status` ENUM('PENDING', 'ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'PENDING',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_supplier` (`seller_id`, `supplier_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `purchase_invoices` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `supplier_id` BIGINT UNSIGNED NOT NULL,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `invoice_number` VARCHAR(50) NOT NULL COMMENT 'The invoice number provided by the supplier',
  `invoice_date` DATE NOT NULL,
  `due_date` DATE NULL,
  `total_amount` DECIMAL(10, 2) NOT NULL,
  `status` ENUM('DRAFT', 'RECEIVED', 'PAID', 'CANCELLED') NOT NULL DEFAULT 'RECEIVED',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `purchase_invoice_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `purchase_invoice_id` BIGINT UNSIGNED NOT NULL,
  `product_unit_id` BIGINT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL,
  `taxable_value` DECIMAL(10, 2) NOT NULL COMMENT 'Cost per unit before taxes',
  `cgst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `sgst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `igst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `cess_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `net_amount` DECIMAL(10, 2) NOT NULL COMMENT 'Final cost per unit, inclusive of all taxes',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`purchase_invoice_id`) REFERENCES `purchase_invoices` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_unit_id`) REFERENCES `product_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `purchase_returns` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `purchase_invoice_item_id` BIGINT UNSIGNED NOT NULL COMMENT 'The item from a purchase invoice being returned',
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `quantity` INT UNSIGNED NOT NULL COMMENT 'Number of units returned',
  `reason` TEXT NULL,
  `status` ENUM('REQUESTED', 'APPROVED', 'REJECTED', 'PROCESSED') NOT NULL DEFAULT 'REQUESTED',
  `requested_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `voucher_entry_id` BIGINT UNSIGNED NULL COMMENT 'Link to the financial debit note entry in the voucher system',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`purchase_invoice_item_id`) REFERENCES `purchase_invoice_items` (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- =============================================
-- Accounting Module (v9.2)
-- =============================================

CREATE TABLE `ledger_accounts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `group` VARCHAR(255) NOT NULL COMMENT 'e.g., Sundry Debtors, Sales Accounts, Duties & Taxes',
  `account_type` ENUM('ASSET', 'LIABILITY', 'INCOME', 'EXPENSE') NOT NULL,
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration.',
  `is_default` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Identifies system-managed default accounts.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ledger_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `voucher_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'e.g., Sales, Purchase, Payment, Receipt, Journal, Credit Note, Debit Note, ADJUSTMENT',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `voucher_entries` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `voucher_type_id` INT UNSIGNED NOT NULL,
  `entry_date` DATETIME NOT NULL,
  `narration` TEXT NULL,
  `reference_type` VARCHAR(100) NULL COMMENT 'e.g., Invoice, Payment, PurchaseInvoice',
  `reference_id` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`voucher_type_id`) REFERENCES `voucher_types` (`id`),
  INDEX `idx_reference` (`reference_type`, `reference_id`)
) ENGINE=InnoDB DEFAULT CHARSET=fkey;

CREATE TABLE `voucher_entry_details` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `voucher_entry_id` BIGINT UNSIGNED NOT NULL,
  `ledger_account_id` BIGINT UNSIGNED NOT NULL,
  `debit_amount` DECIMAL(12, 2) NULL,
  `credit_amount` DECIMAL(12, 2) NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`voucher_entry_id`) REFERENCES `voucher_entries` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`ledger_account_id`) REFERENCES `ledger_accounts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Custom Reporting Module (v3.1)
-- =============================================

CREATE TABLE `reports` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `primary_data_source` VARCHAR(100) NOT NULL COMMENT 'e.g., orders, invoices, customers',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `report_columns` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `report_id` BIGINT UNSIGNED NOT NULL,
  `column_name` VARCHAR(255) NOT NULL COMMENT 'e.g., customers.legal_name',
  `display_name` VARCHAR(255) NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `report_filters` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `report_id` BIGINT UNSIGNED NOT NULL,
  `column_name` VARCHAR(255) NOT NULL COMMENT 'e.g., orders.order_date',
  `operator` ENUM('=', '!=', '>', '<', '>=', '<=', 'LIKE', 'IN', 'BETWEEN') NOT NULL,
  `filter_value` TEXT NULL,
  `is_parameter` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'If TRUE, prompt user for value at runtime',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `report_sorting` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `report_id` BIGINT UNSIGNED NOT NULL,
  `column_name` VARCHAR(255) NOT NULL,
  `direction` ENUM('ASC', 'DESC') NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `report_generations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `report_id` BIGINT UNSIGNED NOT NULL,
  `generated_by_user_id` BIGINT UNSIGNED NOT NULL,
  `generated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` ENUM('PENDING', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'PENDING',
  `output_format` ENUM('CSV', 'PDF', 'JSON') NOT NULL,
  `output_file_url` VARCHAR(512) NULL,
  `parameters_used` JSON NULL COMMENT 'Stores the dynamic parameter values used for this run',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`generated_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Delivery Module (v5.7)
-- =============================================

CREATE TABLE `delivery_boys` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('AVAILABLE', 'ON_DELIVERY', 'OFFLINE') NOT NULL DEFAULT 'OFFLINE',
  `current_location_latitude` DECIMAL(10, 8) NULL,
  `current_location_longitude` DECIMAL(11, 8) NULL,
  `last_location_update` TIMESTAMP NULL,
  `payout_rate_per_delivery` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_delivery_vehicles` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `vehicle_number` VARCHAR(50) NOT NULL,
  `vehicle_type` VARCHAR(100) NOT NULL COMMENT 'e.g., Truck, Van, Bike',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `seller_delivery_boys` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `delivery_shifts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL COMMENT 'e.g., Morning Delivery, Evening Delivery',
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `delivery_routes` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `route_area_geojson` TEXT NULL COMMENT 'GeoJSON data representing the route area (e.g., a Polygon)',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `delivery_route_staff_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `delivery_route_id` BIGINT UNSIGNED NOT NULL,
  `seller_delivery_boy_id` BIGINT UNSIGNED NOT NULL,
  `delivery_shift_id` BIGINT UNSIGNED NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_route_shift_staff` (`delivery_route_id`, `delivery_shift_id`),
  FOREIGN KEY (`delivery_route_id`) REFERENCES `delivery_routes` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_delivery_boy_id`) REFERENCES `seller_delivery_boys` (`id`),
  FOREIGN KEY (`delivery_shift_id`) REFERENCES `delivery_shifts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `delivery_loads` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `delivery_shift_id` BIGINT UNSIGNED NOT NULL,
  `delivery_route_id` BIGINT UNSIGNED NOT NULL,
  `seller_delivery_vehicle_id` BIGINT UNSIGNED NOT NULL,
  `seller_delivery_boy_id` BIGINT UNSIGNED NOT NULL,
  `load_date` DATE NOT NULL,
  `status` ENUM('PENDING', 'LOADED', 'IN_TRANSIT', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
  `scheduled_job_id` BIGINT UNSIGNED NULL COMMENT 'The automated job that generated this load',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`delivery_shift_id`) REFERENCES `delivery_shifts` (`id`),
  FOREIGN KEY (`delivery_route_id`) REFERENCES `delivery_routes` (`id`),
  FOREIGN KEY (`seller_delivery_vehicle_id`) REFERENCES `seller_delivery_vehicles` (`id`),
  FOREIGN KEY (`seller_delivery_boy_id`) REFERENCES `seller_delivery_boys` (`id`),
  FOREIGN KEY (`scheduled_job_id`) REFERENCES `scheduled_jobs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `delivery_load_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `delivery_load_id` BIGINT UNSIGNED NOT NULL,
  `order_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`delivery_load_id`) REFERENCES `delivery_loads` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `delivery_adjustments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_item_id` BIGINT UNSIGNED NOT NULL,
  `adjusted_quantity` INT NOT NULL,
  `new_seller_product_unit_id` BIGINT UNSIGNED NULL,
  `new_item_quantity` INT NULL,
  `adjustment_type` ENUM('QUANTITY_CHANGE', 'NEW_ITEM', 'RETURN') NOT NULL,
  `adjusted_by_staff_id` BIGINT UNSIGNED NOT NULL,
  `adjusted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`),
  FOREIGN KEY (`new_seller_product_unit_id`) REFERENCES `seller_product_units` (`id`),
  FOREIGN KEY (`adjusted_by_staff_id`) REFERENCES `seller_staff` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `spot_sales` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `delivery_load_id` BIGINT UNSIGNED NOT NULL,
  `seller_customer_map_id` BIGINT UNSIGNED NULL,
  `sold_by_staff_id` BIGINT UNSIGNED NOT NULL,
  `total_amount` DECIMAL(10, 2) NOT NULL,
  `sale_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`delivery_load_id`) REFERENCES `delivery_loads` (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`),
  FOREIGN KEY (`sold_by_staff_id`) REFERENCES `seller_staff` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `spot_sale_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `spot_sale_id` BIGINT UNSIGNED NOT NULL,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL,
  `taxable_value` DECIMAL(10, 2) NOT NULL,
  `cgst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `sgst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `igst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `cess_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `net_amount` DECIMAL(10, 2) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`spot_sale_id`) REFERENCES `spot_sales` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `cash_collections` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `delivery_load_id` BIGINT UNSIGNED NOT NULL,
  `collected_by_staff_id` BIGINT UNSIGNED NOT NULL,
  `submitted_amount` DECIMAL(12, 2) NOT NULL,
  `verified_amount` DECIMAL(12, 2) NULL,
  `verified_by_user_id` BIGINT UNSIGNED NULL,
  `deposited_into_account_id` BIGINT UNSIGNED NULL COMMENT 'The account where the cash was deposited upon verification',
  `status` ENUM('PENDING_VERIFICATION', 'VERIFIED', 'SHORTFALL') NOT NULL DEFAULT 'PENDING_VERIFICATION',
  `submitted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `verified_at` TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`delivery_load_id`) REFERENCES `delivery_loads` (`id`),
  FOREIGN KEY (`collected_by_staff_id`) REFERENCES `seller_staff` (`id`),
  FOREIGN KEY (`verified_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`deposited_into_account_id`) REFERENCES `seller_accounts`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `cash_shortfalls` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cash_collection_id` BIGINT UNSIGNED NOT NULL,
  `shortfall_amount` DECIMAL(12, 2) NOT NULL,
  `notes` TEXT NULL,
  `is_deducted` BOOLEAN NOT NULL DEFAULT FALSE,
  `deducted_at` TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`cash_collection_id`) REFERENCES `cash_collections` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `returnable_asset_collections` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `delivery_load_id` BIGINT UNSIGNED NOT NULL,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `product_unit_id` BIGINT UNSIGNED NOT NULL,
  `collected_quantity` INT UNSIGNED NOT NULL,
  `collected_by_staff_id` BIGINT UNSIGNED NOT NULL,
  `collected_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`delivery_load_id`) REFERENCES `delivery_loads` (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`),
  FOREIGN KEY (`product_unit_id`) REFERENCES `product_units` (`id`),
  FOREIGN KEY (`collected_by_staff_id`) REFERENCES `seller_staff` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `returnable_asset_verifications` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `delivery_load_id` BIGINT UNSIGNED NOT NULL,
  `product_unit_id` BIGINT UNSIGNED NOT NULL,
  `expected_quantity` INT UNSIGNED NOT NULL,
  `verified_quantity` INT UNSIGNED NOT NULL,
  `verified_by_user_id` BIGINT UNSIGNED NOT NULL,
  `verified_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` ENUM('VERIFIED', 'DISCREPANCY') NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`delivery_load_id`) REFERENCES `delivery_loads` (`id`),
  FOREIGN KEY (`product_unit_id`) REFERENCES `product_units` (`id`),
  FOREIGN KEY (`verified_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `returnable_asset_shortfalls` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `verification_id` BIGINT UNSIGNED NOT NULL,
  `shortfall_quantity` INT NOT NULL,
  `notes` TEXT NULL,
  `resolved` BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`verification_id`) REFERENCES `returnable_asset_verifications` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Automation and Scheduling Module (v9.5)
-- =============================================

CREATE TABLE `job_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `job_name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'e.g., CREATE_SUBSCRIPTION_ORDERS, PLAN_DAILY_ROUTES',
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `scheduled_jobs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `job_type_id` INT UNSIGNED NOT NULL,
  `seller_id` BIGINT UNSIGNED NULL COMMENT 'The seller this job belongs to (if applicable)',
  `cron_expression` VARCHAR(100) NOT NULL COMMENT 'Cron expression for scheduling',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `last_run_at` TIMESTAMP NULL,
  `last_run_status` ENUM('SUCCESS', 'FAILED') NULL,
  `last_run_message` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`job_type_id`) REFERENCES `job_types` (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Payroll & Attendance Module (v5.6)
-- =============================================

CREATE TABLE `staff_attendances` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `staff_id` BIGINT UNSIGNED NOT NULL,
  `attendance_date` DATE NOT NULL,
  `status` ENUM('PRESENT', 'ABSENT', 'ON_LEAVE') NOT NULL,
  `notes` TEXT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_staff_attendance_date` (`staff_id`, `attendance_date`),
  FOREIGN KEY (`staff_id`) REFERENCES `seller_staff` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `payrolls` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `payroll_month` DATE NOT NULL COMMENT 'First day of the month for which payroll is calculated, e.g., 2024-07-01 for July',
  `status` ENUM('PENDING', 'CALCULATED', 'PAID', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
  `scheduled_job_id` BIGINT UNSIGNED NULL COMMENT 'The automated job that calculated this payroll',
  `total_amount_paid` DECIMAL(12, 2) NULL,
  `payment_date` DATE NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`scheduled_job_id`) REFERENCES `scheduled_jobs` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `payroll_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `payroll_id` BIGINT UNSIGNED NOT NULL,
  `staff_id` BIGINT UNSIGNED NOT NULL,
  `gross_salary` DECIMAL(12, 2) NOT NULL COMMENT 'Calculated salary before deductions',
  `deductions` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `net_salary` DECIMAL(12, 2) NOT NULL COMMENT 'Salary to be paid after deductions',
  `payment_transaction_id` BIGINT UNSIGNED NULL COMMENT 'Link to the payment transaction for this salary payout',
  `notes` TEXT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`payroll_id`) REFERENCES `payrolls` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`staff_id`) REFERENCES `seller_staff` (`id`),
  FOREIGN KEY (`payment_transaction_id`) REFERENCES `payment_transactions` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- Initial Data Population (v9.5)
-- =============================================

INSERT INTO `platform_settings` (`setting_key`, `setting_value`, `description`) VALUES
('SESSION_HISTORY_RETENTION_DAYS', '30', 'Number of days to retain user session history.'),
('DEFAULT_DOCUMENT_ACCENT_COLOR', '#000000', 'Default accent color for documents like invoices.'),
('DEFAULT_DOCUMENT_HEADER', 'Invoice', 'Default header text for documents.'),
('DEFAULT_DOCUMENT_FOOTER', 'Thank you for your business!', 'Default footer text for documents.');

INSERT INTO `languages` (`code`, `name`) VALUES
('en-US', 'English (US)'),
('hi-IN', 'Hindi (India)');

INSERT INTO `countries` (`name`, `iso_code_2`, `phone_code`) VALUES
('India', 'IN', '+91'),
('United States', 'US', '+1'),
('United Kingdom', 'GB', '+44');

INSERT INTO `ledger_accounts` (`name`, `group`, `account_type`, `is_default`) VALUES
('Opening Balance Equity', 'Capital Account', 'LIABILITY', TRUE);

INSERT INTO `voucher_types` (`name`) VALUES
('ADJUSTMENT');

INSERT INTO `seller_staff_roles` (`role_name`, `description`) VALUES
('Seller Admin', 'Full access to manage seller account, including staff, settings, and unsettled balances.'),
('Payment Approver', 'Can confirm and verify manual/offline payments.'),
('Order Manager', 'Can manage orders, including confirming, dispatching, and handling future-dated scheduled orders.'),
('Product Manager', 'Can add, edit, and manage products and inventory.'),
('Product Catalog Manager', 'Can manage the master product catalog, including approving new product requests.'),
('Support Staff', 'Can manage and respond to support tickets directed to the seller.'),
('Security Auditor', 'Can view session history and other security-related logs.'),
('Document Customizer', 'Can manage document branding and templates for a seller.'),
('Whitelabel Manager', 'Can manage whitelabel portal and app settings for the seller.'),
('Marketing Manager', 'Can create and manage whitelabel promotional campaigns and view analytics.'),
('Delivery Staff', 'Can manage deliveries and record on-the-spot sales.'),
('Cash Manager', 'Can verify cash collections from delivery staff.'),
('Warehouse Manager', 'Can verify returnable asset collections.'),
('Route Planner', 'Can manage delivery routes and daily load creation.'),
('Payroll Manager', 'Can manage staff attendance and run payroll.'),
('Accountant', 'Manages financial accounts, expenses, reconciliation, generates reports, manages unsettled balances, and handles accounting data synchronization.'),
('Pricing Manager', 'Can request and approve MRP and price changes.'),
('Expense Approver', 'Can approve or reject submitted expenses.'),
('GST Filing Manager', 'Can generate and access GST reports for filing.'),
('Data Importer', 'Can manage the import of customer data from external systems.'),
('Subscription Manager', 'Can view subscription history, manage billing, and see the feature deactivation log.'),
('Store Operations Manager', 'Can manage store operating hours, holiday schedules, and order/delivery shift linkages.'),
('Bank Reconciliation Manager', 'Can initiate and confirm internal transfers between cash and bank accounts.'),
('Data Reset Manager', 'Can create adjustment entries to set opening balances for customers, accounts, and physical assets.'),
('Cheque Manager', 'Manages cheque deposits, tracks clearance, and handles bounced cheques.');

INSERT INTO `brand_staff_roles` (`role_name`, `description`) VALUES
('Brand Admin', 'Full access to manage brand account, including staff and settings.'),
('Brand Whitelabel Manager', 'Can manage whitelabel portal and app settings for the brand.'),
('Brand Billing Manager', 'Can view and manage the brand\'s subscription and invoices from the platform.'),
('Brand Product Manager', 'Can manage the brand\'s product listings and details across the platform.'),
('Brand Advertising Manager', 'Can create and manage advertising campaigns for the brand.');

INSERT INTO `job_types` (`job_name`, `description`) VALUES
('CREATE_SUBSCRIPTION_ORDERS', 'Creates new orders for active subscriptions (for both goods and services).'),
('PLAN_DAILY_ROUTES', 'Generates delivery loads for upcoming shifts based on pending orders and customer route assignments.'),
('CALCULATE_MONTHLY_PAYROLL', 'Calculates monthly payroll for all staff based on attendance and salary structure.'),
('MANAGE_SUBSCRIPTION_STATUS', 'Checks for expired trials and past-due invoices to update subscription statuses and triggers the deactivation/re-activation of associated features.'),
('APPLY_SCHEDULED_PRICE_CHANGES', 'Applies approved product price changes that have reached their effective date.'),
('APPLY_PRODUCT_CHANGES', 'Applies approved changes (e.g., images, units) to product catalog listings.'),
('APPLY_SCHEDULED_TAX_CHANGES', 'Applies approved product tax changes that have reached their effective date.'),
('GENERATE_GST_REPORT', 'Generates GST reports (like GSTR-1, GSTR-3B) for a seller for a given period.'),
('GENERATE_FINANCIAL_REPORT', 'Generates financial statements (e.g., Balance Sheet) for a seller.'),
('PROCESS_CUSTOMER_IMPORT', 'Processes validated and approved customer data from the staging area into the live tables.'),
('PROCESS_ACCOUNTING_SYNC_JOBS', 'Processes the queue of financial events to be synchronized with an external accounting system.'),
('MANAGE_STORE_OPERATIONS', 'Updates the open/closed status of seller stores based on their multiple daily operating slots, holidays, and admin overrides.'),
('ACTIVATE_SCHEDULED_ORDERS', 'Activates scheduled orders by changing their status from SCHEDULED to PENDING on their scheduled delivery date.'),
('UPDATE_CHEQUE_STATUS', 'Periodically polls or receives webhooks to update the status of cheques pending clearance.'),
('RECALCULATE_UNSETTLED_BALANCES', 'Periodically recalculates unsettled balances and populates the customer-facing settlement log.'),
('PURGE_OLD_SESSION_HISTORY', 'Deletes session history records older than the configured retention period.');

INSERT INTO `gst_report_types` (`name`, `description`) VALUES
('GSTR-1', 'Report for details of all outward supplies of goods and services.'),
('GSTR-3B', 'A monthly self-declaration to be filed by a registered dealer providing summarized details of all outward supplies made, input tax credit claimed, tax liability ascertained and taxes paid.'),
('GSTR-2A/2B', 'Report for details of all inward supplies of goods and services.');

INSERT INTO `financial_report_types` (`name`, `description`) VALUES
('Profit & Loss Statement', 'A financial statement that summarizes the revenues, costs, and expenses incurred during a specified period.'),
('Balance Sheet', 'A statement of the assets, liabilities, and capital of a business or other organization at a particular point in time.'),
('Trial Balance', 'A bookkeeping worksheet in which the balance of all ledgers are compiled into debit and credit account column totals that are equal.');


SET foreign_key_checks = 1;