-- =============================================================================
-- GOKRISHI E-COMMERCE PLATFORM DATABASE SCHEMA
-- =============================================================================
--
-- Author:      Akash Mittal, Partner, Ayaan Delivery Solutions LLP
-- Copyright:   Copyright (c) 2023-2024 Ayaan Delivery Solutions LLP. All Rights Reserved.
--
-- License:     This source code is the confidential and proprietary property of
--              Ayaan Delivery Solutions LLP. It is protected by copyright laws and
--              international treaty provisions. This code is licensed to you
--              for internal use only. Unauthorized reproduction, distribution,
--              or modification of this software, or any portion of it, may
--              result in severe civil and criminal penalties, and will be
--              prosecuted to the maximum extent possible under the law.
--
-- Version:     10.3
-- Description: This script defines the complete database schema for the Gokrishi
--              platform. Version 10.3 adds professional legal notices and
--              improves documentation for the multi-entity architecture.
--
-- =============================================================================

SET NAMES utf8mb4;
SET time_zone = '+05:30';
SET foreign_key_checks = 0;

-- =============================================
-- Section: Platform Configuration
-- =============================================

CREATE TABLE `platform_settings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `setting_key` VARCHAR(100) NOT NULL UNIQUE,
  `setting_value` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores platform-wide configuration settings.';

-- =============================================
-- Section: Internationalization
-- =============================================

CREATE TABLE `languages` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(10) NOT NULL UNIQUE,
  `name` VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines supported languages for internationalization.';

-- =============================================
-- Section: Reference Geodata
-- =============================================

CREATE TABLE `countries` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE,
  `iso_code_2` CHAR(2) NOT NULL UNIQUE,
  `phone_code` VARCHAR(10) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for countries.';

CREATE TABLE `states` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `country_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for states or provinces within countries.';

CREATE TABLE `cities` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `state_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`state_id`) REFERENCES `states` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for cities within states.';

CREATE TABLE `pincodes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `pincode` VARCHAR(10) NOT NULL UNIQUE,
  `city_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`city_id`) REFERENCES `cities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for postal codes (pincodes).';


-- =============================================
-- Section: Core User & Authentication
-- =============================================

CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `is_admin` BOOLEAN NOT NULL DEFAULT FALSE,
  `country_id` INT UNSIGNED NOT NULL,
  `primary_mobile` VARCHAR(15) NOT NULL,
  `password_hash` VARCHAR(255) NULL,
  `primary_email` VARCHAR(255) NULL UNIQUE,
  `google_id` VARCHAR(255) NULL UNIQUE,
  `tally_guid` VARCHAR(255) NULL UNIQUE,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Central table for all platform users and their core profile data.';

CREATE TABLE `user_sessions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `token` VARCHAR(255) NOT NULL UNIQUE,
  `active_account_type` ENUM('CUSTOMER', 'SELLER', 'SUPPLIER') NULL,
  `active_account_id` BIGINT UNSIGNED NULL,
  `ip_address` VARCHAR(45) NULL,
  `user_agent` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores active user login sessions.';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs historical user session data for auditing.';

CREATE TABLE `otps` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `recipient` VARCHAR(255) NOT NULL,
  `otp_hash` VARCHAR(255) NOT NULL,
  `purpose` ENUM('LOGIN', 'VERIFY_MOBILE', 'VERIFY_EMAIL', 'RESET_PASSWORD') NOT NULL,
  `is_used` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_otp_recipient` (`recipient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores and manages one-time passwords for verification.';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores physical addresses for users.';


-- =============================================
-- Section: Product Catalog
-- =============================================

CREATE TABLE `brands` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NULL,
  `tally_guid` VARCHAR(255) NULL UNIQUE,
  `logo_url` VARCHAR(512) NULL,
  `logo_last_updated_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines product brands or manufacturers.';

CREATE TABLE `brand_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `brand_id` INT UNSIGNED NOT NULL,
    `language_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_brand_translation` (`brand_id`, `language_id`),
    FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores translated names for brands in different languages.';

CREATE TABLE `categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_category_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`parent_category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines the product category hierarchy.';

CREATE TABLE `category_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category_id` INT UNSIGNED NOT NULL,
    `language_id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(150) NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_category_translation` (`category_id`, `language_id`),
    FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores translated names for categories in different languages.';

CREATE TABLE `products` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_id` INT UNSIGNED NOT NULL,
  `category_id` INT UNSIGNED NOT NULL,
  `product_type` ENUM('GOODS', 'SERVICE') NOT NULL DEFAULT 'GOODS',
  `tally_guid` VARCHAR(255) NULL UNIQUE,
  `hsn_code` VARCHAR(20) NOT NULL,
  `barcode` VARCHAR(100) NULL,
  `gst_percentage` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
  `cess_percentage` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
  `status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `created_by_seller_id` BIGINT UNSIGNED NULL,
  `managed_by_brand_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`),
  FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`),
  FOREIGN KEY (`created_by_seller_id`) REFERENCES `sellers` (`id`) ON DELETE SET NULL,
  FOREIGN KEY (`managed_by_brand_id`) REFERENCES `brands` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Master table for all products on the platform.';

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
  `created_product_id` BIGINT UNSIGNED NULL,
  `rejection_reason` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`requested_by_seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`approved_by_admin_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  FOREIGN KEY (`created_product_id`) REFERENCES `products` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Staging table for new product requests from sellers.';

CREATE TABLE `product_request_images` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_request_id` BIGINT UNSIGNED NOT NULL,
  `image_url` VARCHAR(512) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_request_id`) REFERENCES `product_requests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores images for new product requests.';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores translated content for products.';

CREATE TABLE `product_units` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(50) NOT NULL,
  `conversion_rate` DECIMAL(10,2) NOT NULL DEFAULT 1.00,
  `is_returnable_asset` BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines the saleable and trackable units for each product.';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores image gallery for products.';

CREATE TABLE `product_change_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `requested_by_user_id` BIGINT UNSIGNED NULL,
  `change_type` ENUM('IMAGES', 'UNITS', 'DESCRIPTION', 'DETAILS') NOT NULL,
  `proposed_changes` JSON NOT NULL,
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'APPLIED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `rejection_reason` TEXT NULL,
  `approved_by_user_id` BIGINT UNSIGNED NULL,
  `approved_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`requested_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  FOREIGN KEY (`approved_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tracks proposed changes to master product data.';


-- =============================================
-- Section: Seller & Inventory
-- =============================================

CREATE TABLE `sellers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The primary user account that owns and manages the seller profile.',
  `is_platform_admin` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Identifies this seller as the platform itself, used for internal billing to other sellers.',
  `account_status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT 'The operational status of the seller account.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Represents the core business account of a seller. This is the master record that owns multiple legal entities and centralized inventory. A new seller ID should be created for each new warehouse or physically separate inventory location.';

CREATE TABLE `seller_legal_entities` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the main seller account.',
  `company_name` VARCHAR(255) NOT NULL COMMENT 'The legal name of this specific company entity.',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally/Marg/Busy integration (Ledger for this entity).',
  `gst_number` VARCHAR(15) NULL UNIQUE COMMENT 'The Goods and Services Tax Identification Number for this entity.',
  `gst_state_id` INT UNSIGNED NULL COMMENT 'The state associated with the GST number.',
  `pan_number` VARCHAR(10) NULL COMMENT 'The legal entity\'s Permanent Account Number (for tax purposes).',
  `company_logo_url` VARCHAR(512) NULL COMMENT 'URL for this legal entity\'s company logo.',
  `is_default` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Indicates the default entity for new transactions and payments.',
  `address_line_1` VARCHAR(255) NULL,
  `address_line_2` VARCHAR(255) NULL,
  `city_id` INT UNSIGNED NULL,
  `pincode_id` INT UNSIGNED NULL,
  `state_id` INT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`gst_state_id`) REFERENCES `states`(`id`),
  FOREIGN KEY (`city_id`) REFERENCES `cities`(`id`),
  FOREIGN KEY (`pincode_id`) REFERENCES `pincodes`(`id`),
  FOREIGN KEY (`state_id`) REFERENCES `states`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores the distinct legal company profiles (e.g., for different states or business units) associated with a single seller account. All invoicing, taxation, and financial reporting are segregated at this level.';

CREATE TABLE `seller_subscription_plans` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plan_name` VARCHAR(150) NOT NULL,
  `monthly_fee` DECIMAL(10, 2) NOT NULL,
  `setup_fee` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `features` JSON NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines the subscription plans available to sellers.';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages the subscription status of sellers.';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Settings for seller-specific whitelabel branding.';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages promotional campaigns for seller whitelabel portals.';

CREATE TABLE `whitelabel_traffic_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `campaign_id` BIGINT UNSIGNED NOT NULL,
    `source` VARCHAR(100) NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `visited_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`campaign_id`) REFERENCES `whitelabel_promo_campaigns` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs traffic from seller whitelabel campaigns.';

CREATE TABLE `seller_document_branding` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_legal_entity_id` BIGINT UNSIGNED NOT NULL,
  `accent_color` VARCHAR(7) NULL,
  `header` TEXT NULL,
  `footer` TEXT NULL,
  `show_platform_logo` BOOLEAN NOT NULL DEFAULT TRUE,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_document_branding_entity_id` (`seller_legal_entity_id`),
  FOREIGN KEY (`seller_legal_entity_id`) REFERENCES `seller_legal_entities` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Custom branding for seller-generated documents per legal entity.';

CREATE TABLE `seller_customer_map` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NULL,
  `brand_id` INT UNSIGNED NULL,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `tally_guid` VARCHAR(255) NULL UNIQUE,
  `price_list_id` BIGINT UNSIGNED NULL,
  `credit_limit_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `running_balance` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `unsettled_payments_balance` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `unsettled_returnable_assets_balance` INT NOT NULL DEFAULT 0,
  `alias_name` VARCHAR(100) NULL,
  `status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'INACTIVE', 'UNSERVICEABLE', 'BLACKLISTED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `status_reason` TEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_user_customer` (`seller_id`, `user_id`),
  UNIQUE KEY `uk_seller_brand_customer` (`seller_id`, `brand_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`price_list_id`) REFERENCES `price_lists` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_customer_type` CHECK (`user_id` IS NOT NULL OR `brand_id` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Maps customers (users or brands) to sellers.';

CREATE TABLE `seller_staff` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_legal_entity_id` BIGINT UNSIGNED NOT NULL COMMENT 'The legal entity that employs this staff member.',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The user who is the staff member.',
  `salary_structure` ENUM('DAILY', 'MONTHLY', 'COMMISSION_BASED') NOT NULL DEFAULT 'MONTHLY',
  `daily_rate` DECIMAL(10, 2) NULL,
  `monthly_salary` DECIMAL(10, 2) NULL,
  `commission_rate` DECIMAL(5, 2) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_entity_user` (`seller_legal_entity_id`, `user_id`),
  FOREIGN KEY (`seller_legal_entity_id`) REFERENCES `seller_legal_entities` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Links a user account to a specific legal entity as an employee. All payroll and HR functions are managed at this level, ensuring salary payments and expenses are booked to the correct company.';

CREATE TABLE `seller_staff_roles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_name` VARCHAR(100) NOT NULL UNIQUE,
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines available staff roles within a seller organization.';

CREATE TABLE `seller_staff_role_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `staff_id` BIGINT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_staff_role` (`staff_id`, `role_id`),
  FOREIGN KEY (`staff_id`) REFERENCES `seller_staff` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`role_id`) REFERENCES `seller_staff_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Assigns roles to seller staff members.';

CREATE TABLE `seller_product_units` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `product_unit_id` BIGINT UNSIGNED NOT NULL,
  `mrp` DECIMAL(10, 2) NULL,
  `purchase_rate` DECIMAL(10, 2) NULL,
  `selling_rate` DECIMAL(10, 2) NOT NULL,
  `stock_quantity` INT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `is_out_of_stock` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_product_unit` (`seller_id`, `product_unit_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_unit_id`) REFERENCES `product_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Seller-specific pricing and stock for each product unit.';

CREATE TABLE `seller_product_legal_entity_map` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
    `legal_entity_id` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_product_entity_map` (`seller_product_unit_id`, `legal_entity_id`),
    FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`legal_entity_id`) REFERENCES `seller_legal_entities`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Maps a seller product unit to a specific legal entity for billing.';

CREATE TABLE `price_lists` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Container for customer-specific pricing rules.';

CREATE TABLE `price_list_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `price_list_id` BIGINT UNSIGNED NOT NULL,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
  `discount_type` ENUM('FIXED', 'PERCENTAGE') NOT NULL,
  `discount_value` DECIMAL(10, 2) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`price_list_id`) REFERENCES `price_lists` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Specific product discounts within a price list.';


-- =============================================
-- Section: Customer & Order Management
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tracks balance of returnable assets for each customer.';

CREATE TABLE `customer_unsettled_items_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `item_type` ENUM('PAYMENT', 'RETURNABLE_ASSET') NOT NULL,
  `reference_id` BIGINT UNSIGNED NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `amount_or_quantity` DECIMAL(12, 2) NOT NULL,
  `status` VARCHAR(100) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `settled_at` TIMESTAMP NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`) ON DELETE CASCADE,
  INDEX `idx_unsettled_items_customer` (`seller_customer_map_id`, `settled_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Customer-facing log of items pending settlement.';

CREATE TABLE `orders` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `order_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `scheduled_delivery_date` DATE NULL,
  `scheduled_delivery_shift_id` BIGINT UNSIGNED NULL,
  `total_amount` DECIMAL(10, 2) NOT NULL,
  `order_status` ENUM('SCHEDULED', 'PENDING', 'CONFIRMED', 'DISPATCHED', 'DELIVERED', 'CANCELLED', 'DELIVERY_MODIFIED') NOT NULL,
  `delivery_address_id` BIGINT UNSIGNED NULL,
  `delivery_type` ENUM('PICKUP', 'SELLER_DELIVERY', 'THIRD_PARTY_DELIVERY', 'NOT_APPLICABLE') NOT NULL,
  `cancellation_reason` TEXT NULL,
  `is_mapped_to_load` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`),
  FOREIGN KEY (`delivery_address_id`) REFERENCES `addresses` (`id`),
  FOREIGN KEY (`scheduled_delivery_shift_id`) REFERENCES `delivery_shifts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Captures customer sales orders.';

CREATE TABLE `order_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT UNSIGNED NOT NULL,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL,
  `taxable_value` DECIMAL(10, 2) NOT NULL,
  `cgst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `sgst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `igst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `cess_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `net_amount` DECIMAL(10, 2) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Individual line items within an order.';

CREATE TABLE `subscriptions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL,
  `frequency` VARCHAR(50) NOT NULL,
  `status` ENUM('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELED') NOT NULL DEFAULT 'ACTIVE',
  `start_date` DATE NOT NULL,
  `trial_ends_at` TIMESTAMP NULL,
  `end_date` DATE NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`),
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages recurring customer subscriptions for products.';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Assigns a customer to a delivery route and shift.';


-- =============================================
-- Section: Financials & Accounting
-- =============================================

CREATE TABLE `seller_accounts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `legal_entity_id` BIGINT UNSIGNED NULL COMMENT 'The legal entity this account belongs to. Null if it is a general seller account.',
  `account_name` VARCHAR(150) NOT NULL,
  `account_type` ENUM('CASH', 'BANK', 'E_WALLET') NOT NULL,
  `account_number` VARCHAR(50) NULL,
  `bank_name` VARCHAR(150) NULL,
  `ifsc_code` VARCHAR(20) NULL,
  `current_balance` DECIMAL(14, 2) NOT NULL DEFAULT 0.00,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`legal_entity_id`) REFERENCES `seller_legal_entities` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines a sellers financial accounts (cash, bank, etc.).';

CREATE TABLE `account_entries` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `transaction_type` ENUM('CUSTOMER_PAYMENT', 'REFUND', 'PAYROLL_PAYMENT', 'SUPPLIER_PAYMENT', 'EXPENSE', 'CASH_DEPOSIT', 'INTERNAL_TRANSFER') NOT NULL,
  `reference_id` BIGINT UNSIGNED NOT NULL,
  `entry_type` ENUM('DEBIT', 'CREDIT') NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `balance_after_transaction` DECIMAL(14, 2) NOT NULL,
  `narration` TEXT NULL,
  `entry_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`account_id`) REFERENCES `seller_accounts` (`id`) ON DELETE CASCADE,
  INDEX `idx_reference` (`transaction_type`, `reference_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Ledger of all debit/credit entries for seller accounts.';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tracks internal fund transfers between a sellers accounts.';

CREATE TABLE `expense_categories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_legal_entity_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(150) NOT NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_legal_entity_id`) REFERENCES `seller_legal_entities` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines categories for seller expenses.';

CREATE TABLE `expenses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_legal_entity_id` BIGINT UNSIGNED NOT NULL,
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
  FOREIGN KEY (`seller_legal_entity_id`) REFERENCES `seller_legal_entities` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`expense_category_id`) REFERENCES `expense_categories` (`id`),
  FOREIGN KEY (`paid_from_account_id`) REFERENCES `seller_accounts` (`id`),
  FOREIGN KEY (`incurred_by_staff_id`) REFERENCES `seller_staff` (`id`),
  FOREIGN KEY (`approved_by_staff_id`) REFERENCES `seller_staff` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tracks seller business expenses.';


-- =============================================
-- Section: Billing & Payments
-- =============================================

CREATE TABLE `invoices` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT UNSIGNED NOT NULL,
  `legal_entity_id` BIGINT UNSIGNED NOT NULL COMMENT 'The legal entity that is issuing this invoice.',
  `invoice_number` VARCHAR(50) NOT NULL UNIQUE,
  `invoice_date` DATE NOT NULL,
  `due_date` DATE NOT NULL,
  `total_amount` DECIMAL(12, 2) NOT NULL,
  `transaction_fee_amount` DECIMAL(12, 2) NULL,
  `status` ENUM('DRAFT', 'SENT', 'PAID', 'PARTIALLY_PAID', 'VOID') NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`),
  FOREIGN KEY (`legal_entity_id`) REFERENCES `seller_legal_entities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Represents customer invoices.';

CREATE TABLE `payment_gateway_providers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE,
  `transaction_fee_percentage` DECIMAL(5, 2) NULL,
  `transaction_fee_fixed` DECIMAL(10, 2) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for supported payment gateway providers.';

CREATE TABLE `seller_payment_gateways` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_legal_entity_id` BIGINT UNSIGNED NOT NULL,
  `provider_id` INT UNSIGNED NOT NULL,
  `display_name` VARCHAR(150) NOT NULL,
  `api_key_secret_ref` VARCHAR(255) NOT NULL,
  `api_secret_secret_ref` VARCHAR(255) NOT NULL,
  `transaction_fee_bearer` ENUM('SELLER', 'CUSTOMER') NOT NULL DEFAULT 'SELLER',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_entity_provider` (`seller_legal_entity_id`, `provider_id`),
  FOREIGN KEY (`seller_legal_entity_id`) REFERENCES `seller_legal_entities` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`provider_id`) REFERENCES `payment_gateway_providers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores seller-specific settings for payment gateways for each legal entity.';

CREATE TABLE `payment_transactions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_id` BIGINT UNSIGNED NULL,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `seller_customer_map_id` BIGINT UNSIGNED NULL,
  `staff_id` BIGINT UNSIGNED NULL,
  `supplier_id` BIGINT UNSIGNED NULL,
  `transaction_type` ENUM('CUSTOMER_PAYMENT', 'REFUND', 'PAYROLL_PAYMENT', 'SUPPLIER_PAYMENT') NOT NULL,
  `seller_payment_gateway_id` BIGINT UNSIGNED NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `method` ENUM('CASH', 'BANK_TRANSFER', 'UPI', 'WEB_GATEWAY', 'CHEQUE', 'OTHER') NOT NULL,
  `status` ENUM('PENDING', 'PENDING_DEPOSIT', 'PENDING_CLEARANCE', 'SUCCESSFUL', 'FAILED', 'BOUNCED', 'VOID') NOT NULL DEFAULT 'PENDING',
  `gateway_order_id` VARCHAR(255) NULL,
  `gateway_payment_id` VARCHAR(255) NULL,
  `gateway_fee_amount` DECIMAL(12, 2) NULL,
  `transaction_fee_paid_by_customer` DECIMAL(12, 2) NULL,
  `cheque_number` VARCHAR(50) NULL,
  `cheque_date` DATE NULL,
  `cheque_bank_name` VARCHAR(150) NULL,
  `cheque_front_image_url` VARCHAR(512) NULL,
  `cheque_back_image_url` VARCHAR(512) NULL,
  `voucher_entry_id` BIGINT UNSIGNED NULL,
  `confirmed_by_user_id` BIGINT UNSIGNED NULL,
  `confirmation_notes` TEXT NULL,
  `voided_by_user_id` BIGINT UNSIGNED NULL,
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Central log for all monetary payment transactions.';

CREATE TABLE `cheque_deposits` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `deposited_into_account_id` BIGINT UNSIGNED NOT NULL,
  `deposit_date` DATE NOT NULL,
  `total_amount` DECIMAL(12, 2) NOT NULL,
  `deposit_slip_image_url` VARCHAR(512) NULL,
  `status` ENUM('PENDING_CLEARANCE', 'COMPLETED', 'PARTIALLY_CLEARED', 'BOUNCED') NOT NULL,
  `deposited_by_staff_id` BIGINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`deposited_into_account_id`) REFERENCES `seller_accounts` (`id`),
  FOREIGN KEY (`deposited_by_staff_id`) REFERENCES `seller_staff` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages batches of cheques for bank deposit.';

CREATE TABLE `cheque_deposit_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cheque_deposit_id` BIGINT UNSIGNED NOT NULL,
  `payment_transaction_id` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cheque_deposit_item` (`cheque_deposit_id`, `payment_transaction_id`),
  FOREIGN KEY (`cheque_deposit_id`) REFERENCES `cheque_deposits` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`payment_transaction_id`) REFERENCES `payment_transactions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Links individual cheques to a deposit batch.';

CREATE TABLE `payment_refunds` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `payment_transaction_id` BIGINT UNSIGNED NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `reason` TEXT NULL,
  `status` ENUM('PENDING', 'PROCESSED', 'FAILED') NOT NULL DEFAULT 'PENDING',
  `gateway_refund_id` VARCHAR(255) NULL,
  `voucher_entry_id` BIGINT UNSIGNED NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`payment_transaction_id`) REFERENCES `payment_transactions` (`id`),
  FOREIGN KEY (`voucher_entry_id`) REFERENCES `voucher_entries` (`id`),
  INDEX `idx_refund_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs payment refund transactions.';

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
  `event_data` JSON NULL,
  `is_processed` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  FOREIGN KEY (`payment_transaction_id`) REFERENCES `payment_transactions` (`id`),
  FOREIGN KEY (`payment_refund_id`) REFERENCES `payment_refunds` (`id`),
  INDEX `idx_event_processing` (`is_processed`, `event_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Detailed audit trail of payment lifecycle events.';


-- =============================================
-- Section: GST Reporting & Filing
-- =============================================

CREATE TABLE `gst_report_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE,
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for different types of GST reports.';

CREATE TABLE `gst_report_generations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `report_type_id` INT UNSIGNED NOT NULL,
  `seller_legal_entity_id` BIGINT UNSIGNED NOT NULL,
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
  FOREIGN KEY (`seller_legal_entity_id`) REFERENCES `seller_legal_entities` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`generated_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`generation_job_id`) REFERENCES `scheduled_jobs` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs the generation of GST reports for a specific legal entity.';

-- =============================================
-- Section: Financial Reporting & Analysis
-- =============================================

CREATE TABLE `financial_report_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE,
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for different types of financial reports.';

CREATE TABLE `financial_report_generations` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `report_type_id` INT UNSIGNED NOT NULL,
  `seller_legal_entity_id` BIGINT UNSIGNED NOT NULL,
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
  FOREIGN KEY (`seller_legal_entity_id`) REFERENCES `seller_legal_entities` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`generated_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`generation_job_id`) REFERENCES `scheduled_jobs` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs the generation of financial reports for a specific legal entity.';

-- =============================================
-- Section: Logistics & Delivery
-- =============================================

CREATE TABLE `delivery_vehicles` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seller_id` BIGINT UNSIGNED NOT NULL,
    `vehicle_number` VARCHAR(20) NOT NULL UNIQUE,
    `vehicle_type` VARCHAR(50) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`seller_id`) REFERENCES `sellers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages the fleet of delivery vehicles for a seller.';

CREATE TABLE `delivery_shifts` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seller_id` BIGINT UNSIGNED NOT NULL,
    `shift_name` VARCHAR(100) NOT NULL,
    `start_time` TIME NOT NULL,
    `end_time` TIME NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`seller_id`) REFERENCES `sellers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines the delivery shifts for a seller (e.g., Morning, Evening).';

CREATE TABLE `delivery_routes` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seller_id` BIGINT UNSIGNED NOT NULL,
    `route_name` VARCHAR(150) NOT NULL,
    `assigned_staff_id` BIGINT UNSIGNED NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`seller_id`) REFERENCES `sellers`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`assigned_staff_id`) REFERENCES `seller_staff`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines the delivery routes for a seller.';

CREATE TABLE `delivery_loads` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `delivery_route_id` BIGINT UNSIGNED NOT NULL,
    `delivery_vehicle_id` BIGINT UNSIGNED NOT NULL,
    `delivery_shift_id` BIGINT UNSIGNED NOT NULL,
    `load_date` DATE NOT NULL,
    `status` ENUM('PENDING', 'LOADED', 'IN_TRANSIT', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
    PRIMARY KEY (`id`),
    FOREIGN KEY (`delivery_route_id`) REFERENCES `delivery_routes`(`id`),
    FOREIGN KEY (`delivery_vehicle_id`) REFERENCES `delivery_vehicles`(`id`),
    FOREIGN KEY (`delivery_shift_id`) REFERENCES `delivery_shifts`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Represents a specific delivery load for a route, vehicle, and shift.';

CREATE TABLE `delivery_load_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `delivery_load_id` BIGINT UNSIGNED NOT NULL,
    `order_id` BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_load_order` (`delivery_load_id`, `order_id`),
    FOREIGN KEY (`delivery_load_id`) REFERENCES `delivery_loads`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Links individual orders to a delivery load.';

-- =============================================
-- Section: Supplier & Procurement
-- =============================================

CREATE TABLE `suppliers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seller_id` BIGINT UNSIGNED NOT NULL,
    `supplier_name` VARCHAR(255) NOT NULL,
    `contact_person` VARCHAR(255) NULL,
    `mobile_number` VARCHAR(15) NULL,
    `email_address` VARCHAR(255) NULL,
    `gst_number` VARCHAR(15) NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`seller_id`) REFERENCES `sellers`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages the list of suppliers for a seller.';

CREATE TABLE `purchase_orders` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `supplier_id` BIGINT UNSIGNED NOT NULL,
    `order_date` DATE NOT NULL,
    `expected_delivery_date` DATE NULL,
    `status` ENUM('DRAFT', 'PLACED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED') NOT NULL DEFAULT 'DRAFT',
    `total_amount` DECIMAL(12, 2) NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages purchase orders placed with suppliers.';

CREATE TABLE `purchase_order_items` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `purchase_order_id` BIGINT UNSIGNED NOT NULL,
    `product_unit_id` BIGINT UNSIGNED NOT NULL,
    `quantity` INT NOT NULL,
    `rate` DECIMAL(10, 2) NOT NULL,
    `amount` DECIMAL(12, 2) NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`product_unit_id`) REFERENCES `product_units`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Individual line items within a purchase order.';

-- =============================================
-- Section: System & Background Jobs
-- =============================================

CREATE TABLE `scheduled_jobs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `job_type` VARCHAR(100) NOT NULL,
    `payload` JSON NULL,
    `status` ENUM('PENDING', 'RUNNING', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'PENDING',
    `scheduled_at` TIMESTAMP NOT NULL,
    `started_at` TIMESTAMP NULL,
    `completed_at` TIMESTAMP NULL,
    `failure_reason` TEXT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_job_status` (`status`, `scheduled_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='A queue for managing background jobs within the system.';

-- =============================================
-- Section: Accounting Vouchers (for Tally etc.)
-- =============================================

CREATE TABLE `voucher_types` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(100) NOT NULL UNIQUE,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for accounting voucher types.';

CREATE TABLE `voucher_entries` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_type_id` INT UNSIGNED NOT NULL,
    `seller_legal_entity_id` BIGINT UNSIGNED NOT NULL,
    `entry_date` DATE NOT NULL,
    `narration` TEXT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`voucher_type_id`) REFERENCES `voucher_types`(`id`),
    FOREIGN KEY (`seller_legal_entity_id`) REFERENCES `seller_legal_entities`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Represents a single accounting voucher entry.';

CREATE TABLE `voucher_entry_details` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `voucher_entry_id` BIGINT UNSIGNED NOT NULL,
    `account_id` BIGINT UNSIGNED NOT NULL,
    `entry_type` ENUM('DEBIT', 'CREDIT') NOT NULL,
    `amount` DECIMAL(12, 2) NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`voucher_entry_id`) REFERENCES `voucher_entries`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`account_id`) REFERENCES `seller_accounts`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Details of debit/credit for a voucher entry.';


SET foreign_key_checks = 1;
