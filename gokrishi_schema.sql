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
-- Version:     10.4
-- Description: This script defines the complete database schema for the Gokrishi
--              platform. Version 10.4 adds comprehensive table-level and
--              field-level comments for enhanced clarity and maintainability.
--
-- =============================================================================

SET NAMES utf8mb4;
SET time_zone = '+05:30';
SET foreign_key_checks = 0;

-- =============================================
-- Section: Platform Configuration & Geodata
-- =============================================

CREATE TABLE `platform_settings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the setting.',
  `setting_key` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Unique key for the setting (e.g., \'MAINTENANCE_MODE\').',
  `setting_value` VARCHAR(255) NOT NULL COMMENT 'Value for the setting (e.g., \'true\').',
  `description` TEXT NULL COMMENT 'A developer-facing description of the setting\'s purpose.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores platform-wide configuration settings and feature flags.';

CREATE TABLE `languages` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the language.',
  `code` VARCHAR(10) NOT NULL UNIQUE COMMENT 'Standard language code (e.g., \'en\', \'hi-IN\').',
  `name` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Full name of the language (e.g., \'English\', \'Hindi\').',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines supported languages for platform internationalization (i18n).';

CREATE TABLE `countries` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the country.',
  `name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Common name of the country (e.g., \'India\').',
  `iso_code_2` CHAR(2) NOT NULL UNIQUE COMMENT 'ISO 3166-1 alpha-2 country code (e.g., \'IN\').',
  `phone_code` VARCHAR(10) NOT NULL COMMENT 'International dialing code (e.g., \'+91\').',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for countries.';

CREATE TABLE `states` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the state.',
  `name` VARCHAR(100) NOT NULL COMMENT 'Name of the state or province (e.g., \'Maharashtra\').',
  `country_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the countries table.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for states or provinces within countries.';

CREATE TABLE `cities` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the city.',
  `name` VARCHAR(100) NOT NULL COMMENT 'Name of the city (e.g., \'Mumbai\').',
  `state_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the states table.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`state_id`) REFERENCES `states` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for cities within states.';

CREATE TABLE `pincodes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the pincode.',
  `pincode` VARCHAR(10) NOT NULL UNIQUE COMMENT 'The postal code or ZIP code (e.g., \'400001\').',
  `city_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the cities table.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`city_id`) REFERENCES `cities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for postal codes (pincodes).';


-- =============================================
-- Section: Core User & Authentication
-- =============================================

CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the user.',
  `is_admin` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if the user has platform-level admin privileges.',
  `country_id` INT UNSIGNED NOT NULL COMMENT 'FK to the country for the user\'s primary mobile number.',
  `primary_mobile` VARCHAR(15) NOT NULL COMMENT 'The user\'s primary mobile number, used for login and communication.',
  `password_hash` VARCHAR(255) NULL COMMENT 'Hashed password for traditional login.',
  `primary_email` VARCHAR(255) NULL UNIQUE COMMENT 'The user\'s primary email address, can be used for login.',
  `google_id` VARCHAR(255) NULL UNIQUE COMMENT 'Unique identifier from Google for social login.',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'Unique identifier for syncing with Tally/Marg/Busy as a Ledger.',
  `first_name` VARCHAR(100) NULL COMMENT 'The user\'s first name.',
  `middle_name` VARCHAR(100) NULL COMMENT 'The user\'s middle name.',
  `last_name` VARCHAR(100) NOT NULL COMMENT 'The user\'s last name.',
  `legal_name` VARCHAR(300) NOT NULL COMMENT 'The user\'s full legal name as it appears on official documents.',
  `profile_image_url` VARCHAR(512) NULL COMMENT 'URL to the user\'s profile picture.',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Flag indicating if the user account is active or disabled.',
  `is_mobile_verified` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if the primary mobile number has been verified.',
  `is_email_verified` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if the primary email address has been verified.',
  `preferred_language_id` INT UNSIGNED NULL COMMENT 'FK to the languages table for user\'s preferred UI language.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the user account was created.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update to the user record.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_mobile` (`country_id`, `primary_mobile`),
  FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`),
  FOREIGN KEY (`preferred_language_id`) REFERENCES `languages` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Central table for all platform users, storing core profile and authentication data.';

CREATE TABLE `user_sessions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the session.',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the user who owns this session.',
  `token` VARCHAR(255) NOT NULL UNIQUE COMMENT 'The unique authentication token for the session.',
  `active_account_type` ENUM('CUSTOMER', 'SELLER', 'SUPPLIER') NULL COMMENT 'The type of account the user is currently interacting as.',
  `active_account_id` BIGINT UNSIGNED NULL COMMENT 'The ID of the specific account type (e.g., seller_id) the user is active in.',
  `ip_address` VARCHAR(45) NULL COMMENT 'The IP address from which the session was initiated.',
  `user_agent` TEXT NULL COMMENT 'The user agent string of the client device.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the session was created.',
  `expires_at` TIMESTAMP NOT NULL COMMENT 'Timestamp of when the session will expire.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores active user login sessions.';

CREATE TABLE `user_session_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the session history record.',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the user.',
  `session_token` VARCHAR(255) NOT NULL COMMENT 'The token of the session that this record is for.',
  `ip_address` VARCHAR(45) NULL COMMENT 'The IP address of the session.',
  `user_agent` TEXT NULL COMMENT 'The user agent of the session.',
  `login_at` TIMESTAMP NOT NULL COMMENT 'The time the session started.',
  `logout_at` TIMESTAMP NULL COMMENT 'The time the session ended.',
  `logout_reason` ENUM('USER_LOGOUT', 'SESSION_EXPIRED', 'ADMIN_TERMINATED') NULL COMMENT 'The reason why the session ended.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  INDEX `idx_user_session_history_login_at` (`login_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs historical user session data for auditing and security purposes.';

CREATE TABLE `otps` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the OTP.',
  `recipient` VARCHAR(255) NOT NULL COMMENT 'The mobile number or email address the OTP was sent to.',
  `otp_hash` VARCHAR(255) NOT NULL COMMENT 'The hashed value of the one-time password.',
  `purpose` ENUM('LOGIN', 'VERIFY_MOBILE', 'VERIFY_EMAIL', 'RESET_PASSWORD') NOT NULL COMMENT 'The action this OTP is intended to authorize.',
  `is_used` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if this OTP has already been used.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the OTP was generated.',
  `expires_at` TIMESTAMP NOT NULL COMMENT 'Timestamp of when the OTP will expire.',
  PRIMARY KEY (`id`),
  INDEX `idx_otp_recipient` (`recipient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores and manages one-time passwords for various verification purposes.';

CREATE TABLE `addresses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the address.',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the user who owns this address.',
  `address_line_1` VARCHAR(255) NOT NULL COMMENT 'The first line of the address.',
  `address_line_2` VARCHAR(255) NULL COMMENT 'The second line of the address.',
  `pincode_id` INT UNSIGNED NOT NULL COMMENT 'FK to the pincodes table.',
  `latitude` DECIMAL(10, 8) NULL COMMENT 'The geographic latitude.',
  `longitude` DECIMAL(11, 8) NULL COMMENT 'The geographic longitude.',
  `address_type` ENUM('BILLING', 'DELIVERY') NOT NULL COMMENT 'The type of address.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`pincode_id`) REFERENCES `pincodes` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores physical addresses associated with users.';


-- =============================================
-- Section: Product Catalog
-- =============================================

CREATE TABLE `brands` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the brand.',
  `user_id` BIGINT UNSIGNED NULL COMMENT 'FK to the user who might own/manage this brand. Can be NULL for platform-managed brands.',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'Unique identifier for syncing with Tally/Marg/Busy as a Ledger.',
  `logo_url` VARCHAR(512) NULL COMMENT 'URL for the brand\'s logo.',
  `logo_last_updated_at` TIMESTAMP NULL COMMENT 'Timestamp of when the logo was last updated.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the brand was created.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines product brands or manufacturers.';

CREATE TABLE `brand_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the translation.',
    `brand_id` INT UNSIGNED NOT NULL COMMENT 'FK to the brand being translated.',
    `language_id` INT UNSIGNED NOT NULL COMMENT 'FK to the language of the translation.',
    `name` VARCHAR(150) NOT NULL COMMENT 'The translated name of the brand.',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_brand_translation` (`brand_id`, `language_id`),
    FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores translated names for brands in different languages.';

CREATE TABLE `categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the category.',
  `parent_category_id` INT UNSIGNED NULL COMMENT 'FK to the same table to create a hierarchical structure. NULL for top-level categories.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the category was created.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`parent_category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines the hierarchical product category tree.';

CREATE TABLE `category_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the translation.',
    `category_id` INT UNSIGNED NOT NULL COMMENT 'FK to the category being translated.',
    `language_id` INT UNSIGNED NOT NULL COMMENT 'FK to the language of the translation.',
    `name` VARCHAR(150) NOT NULL COMMENT 'The translated name of the category.',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_category_translation` (`category_id`, `language_id`),
    FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores translated names for categories in different languages.';

CREATE TABLE `products` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the product.',
  `brand_id` INT UNSIGNED NOT NULL COMMENT 'FK to the brand of the product.',
  `category_id` INT UNSIGNED NOT NULL COMMENT 'FK to the category the product belongs to.',
  `product_type` ENUM('GOODS', 'SERVICE') NOT NULL DEFAULT 'GOODS' COMMENT 'Type of the product (physical good or service).',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'Unique identifier for syncing with Tally/Marg/Busy as a Stock Item.',
  `hsn_code` VARCHAR(20) NOT NULL COMMENT 'Harmonized System of Nomenclature code for tax purposes.',
  `barcode` VARCHAR(100) NULL COMMENT 'The product\'s barcode (e.g., UPC, EAN).',
  `gst_percentage` DECIMAL(5, 2) NOT NULL DEFAULT 0.00 COMMENT 'The applicable Goods and Services Tax rate.',
  `cess_percentage` DECIMAL(5, 2) NOT NULL DEFAULT 0.00 COMMENT 'The applicable CESS tax rate.',
  `status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT 'The approval and visibility status of the product in the master catalog.',
  `created_by_seller_id` BIGINT UNSIGNED NULL COMMENT 'FK to the seller who originally requested this product. NULL for platform-added products.',
  `managed_by_brand_id` INT UNSIGNED NULL COMMENT 'FK to the brand that has taken over management of this product listing.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the product was created.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`),
  FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`),
  FOREIGN KEY (`created_by_seller_id`) REFERENCES `sellers` (`id`) ON DELETE SET NULL,
  FOREIGN KEY (`managed_by_brand_id`) REFERENCES `brands` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Master table for all unique products on the platform (the global catalog).';

CREATE TABLE `product_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the product request.',
  `requested_by_seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the seller who submitted this request.',
  `product_name` VARCHAR(255) NOT NULL COMMENT 'The name of the new product being requested.',
  `brand_name` VARCHAR(150) NULL COMMENT 'The brand name suggested by the seller.',
  `category_name` VARCHAR(150) NULL COMMENT 'The category name suggested by the seller.',
  `short_description` VARCHAR(500) NULL COMMENT 'A short description of the product.',
  `detailed_description` TEXT NULL COMMENT 'A detailed description of the product.',
  `hsn_code` VARCHAR(20) NULL COMMENT 'The HSN code suggested by the seller.',
  `barcode` VARCHAR(100) NULL COMMENT 'The barcode suggested by the seller.',
  `gst_percentage` DECIMAL(5, 2) NULL COMMENT 'The GST rate suggested by the seller.',
  `cess_percentage` DECIMAL(5, 2) NULL COMMENT 'The CESS rate suggested by the seller.',
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT 'The approval status of the request.',
  `approved_by_admin_id` BIGINT UNSIGNED NULL COMMENT 'FK to the admin user who approved/rejected the request.',
  `created_product_id` BIGINT UNSIGNED NULL COMMENT 'If approved, FK to the newly created record in the products table.',
  `rejection_reason` TEXT NULL COMMENT 'Reason for rejection, if applicable.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the request was submitted.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`requested_by_seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`approved_by_admin_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  FOREIGN KEY (`created_product_id`) REFERENCES `products` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Staging table for new product creation requests from sellers.';

CREATE TABLE `product_request_images` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the image.',
  `product_request_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the product request this image belongs to.',
  `image_url` VARCHAR(512) NOT NULL COMMENT 'URL of the submitted product image.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_request_id`) REFERENCES `product_requests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores images submitted as part of a new product request.';

CREATE TABLE `product_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the translation.',
    `product_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the product being translated.',
    `language_id` INT UNSIGNED NOT NULL COMMENT 'FK to the language of the translation.',
    `name` VARCHAR(255) NOT NULL COMMENT 'The translated name of the product.',
    `short_description` VARCHAR(500) NULL COMMENT 'The translated short description.',
    `detailed_description` TEXT NULL COMMENT 'The translated detailed description.',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_product_translation` (`product_id`, `language_id`),
    FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores translated content (name, description) for master products.';

CREATE TABLE `product_units` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the product unit.',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the master product.',
  `name` VARCHAR(50) NOT NULL COMMENT 'Name of the unit (e.g., \'500g Pack\', \'1 Litre Bottle\', \'Single Item\').',
  `conversion_rate` DECIMAL(10,2) NOT NULL DEFAULT 1.00 COMMENT 'How many of the base unit this unit represents (e.g., 1 if base unit is piece).',
  `is_returnable_asset` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if this unit is a returnable asset (e.g., glass bottle, crate).',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines the saleable and trackable units for each product (e.g., variants like size, weight).';

CREATE TABLE `product_images` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the image.',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the master product.',
  `image_url` VARCHAR(512) NOT NULL COMMENT 'URL of the product image.',
  `source_url` VARCHAR(512) NULL COMMENT 'Original source URL if the image was scraped.',
  `is_scraped` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if the image was obtained via scraping.',
  `sort_order` INT NOT NULL DEFAULT 0 COMMENT 'The display order of the image in a gallery.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the image was added.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores the image gallery for master products.';

CREATE TABLE `product_change_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the change request.',
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the product that is being changed.',
  `requested_by_user_id` BIGINT UNSIGNED NULL COMMENT 'FK to the user who requested the change.',
  `change_type` ENUM('IMAGES', 'UNITS', 'DESCRIPTION', 'DETAILS') NOT NULL COMMENT 'The type of change being proposed.',
  `proposed_changes` JSON NOT NULL COMMENT 'A JSON object containing the proposed new values.',
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'APPLIED') NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT 'The approval status of the change request.',
  `rejection_reason` TEXT NULL COMMENT 'Reason for rejection, if applicable.',
  `approved_by_user_id` BIGINT UNSIGNED NULL COMMENT 'FK to the admin user who approved the change.',
  `approved_at` TIMESTAMP NULL COMMENT 'Timestamp of when the change was approved.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the request was made.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`requested_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  FOREIGN KEY (`approved_by_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tracks proposed changes and corrections to master product data.';


-- =============================================
-- Section: Seller & Inventory
-- =============================================

CREATE TABLE `sellers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the seller business.',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The primary user account that owns and manages this seller business.',
  `is_platform_admin` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Identifies this seller account as the platform owner itself, used for internal billing.',
  `account_status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT 'The operational status of the seller account.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the seller account was created.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Represents a core seller business. This is the master record that owns multiple legal entities and centralized inventory. A new seller ID should be created for each new warehouse or physically separate inventory location.';

CREATE TABLE `seller_legal_entities` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the legal entity.',
  `seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK linking this entity to its parent seller business.',
  `company_name` VARCHAR(255) NOT NULL COMMENT 'The legal name of this specific company entity.',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally/Marg/Busy integration (Ledger for this entity).',
  `gst_number` VARCHAR(15) NULL UNIQUE COMMENT 'The Goods and Services Tax Identification Number for this entity.',
  `gst_state_id` INT UNSIGNED NULL COMMENT 'The state associated with the GST number.',
  `pan_number` VARCHAR(10) NULL COMMENT 'The legal entity\'s Permanent Account Number (for tax purposes).',
  `company_logo_url` VARCHAR(512) NULL COMMENT 'URL for this legal entity\'s company logo.',
  `is_default` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Indicates the default entity for new transactions and payments for the seller.',
  `address_line_1` VARCHAR(255) NULL COMMENT 'The first line of the registered address.',
  `address_line_2` VARCHAR(255) NULL COMMENT 'The second line of the registered address.',
  `city_id` INT UNSIGNED NULL COMMENT 'FK to the city of the registered address.',
  `pincode_id` INT UNSIGNED NULL COMMENT 'FK to the pincode of the registered address.',
  `state_id` INT UNSIGNED NULL COMMENT 'FK to the state of the registered address.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the entity was created.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`gst_state_id`) REFERENCES `states`(`id`),
  FOREIGN KEY (`city_id`) REFERENCES `cities`(`id`),
  FOREIGN KEY (`pincode_id`) REFERENCES `pincodes`(`id`),
  FOREIGN KEY (`state_id`) REFERENCES `states`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores distinct legal company profiles (e.g., for different states) associated with a single seller business. All invoicing, taxation, and financial reporting are segregated at this level.';

CREATE TABLE `seller_staff` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the staff member.',
  `seller_legal_entity_id` BIGINT UNSIGNED NOT NULL COMMENT 'The legal entity that employs this staff member.',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The user account of the staff member.',
  `salary_structure` ENUM('DAILY', 'MONTHLY', 'COMMISSION_BASED') NOT NULL DEFAULT 'MONTHLY' COMMENT 'The basis for salary calculation.',
  `daily_rate` DECIMAL(10, 2) NULL COMMENT 'The rate per day, if salary_structure is DAILY.',
  `monthly_salary` DECIMAL(10, 2) NULL COMMENT 'The fixed monthly salary, if salary_structure is MONTHLY.',
  `commission_rate` DECIMAL(5, 2) NULL COMMENT 'The commission percentage, if salary_structure is COMMISSION_BASED.',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Flag indicating if the staff member is currently employed and active.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the staff member was added.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_entity_user` (`seller_legal_entity_id`, `user_id`),
  FOREIGN KEY (`seller_legal_entity_id`) REFERENCES `seller_legal_entities` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Links a user account to a specific legal entity as an employee. All payroll and HR functions are managed at this level, ensuring salary payments and expenses are booked to the correct company.';

CREATE TABLE `seller_staff_roles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the role.',
  `role_name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'The name of the staff role (e.g., \'Delivery Person\', \'Accountant\').',
  `description` TEXT NULL COMMENT 'A description of the role\'s responsibilities.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines available staff roles and permissions within a seller organization.';

CREATE TABLE `seller_staff_role_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the assignment.',
  `staff_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the seller_staff table.',
  `role_id` INT UNSIGNED NOT NULL COMMENT 'FK to the seller_staff_roles table.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_staff_role` (`staff_id`, `role_id`),
  FOREIGN KEY (`staff_id`) REFERENCES `seller_staff` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`role_id`) REFERENCES `seller_staff_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Assigns one or more roles to a seller staff member.';

CREATE TABLE `seller_product_units` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the seller-specific product unit.',
  `seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the seller who is selling this product unit.',
  `product_unit_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the master product_units table.',
  `mrp` DECIMAL(10, 2) NULL COMMENT 'Maximum Retail Price for this unit.',
  `purchase_rate` DECIMAL(10, 2) NULL COMMENT 'The rate at which the seller procured this unit.',
  `selling_rate` DECIMAL(10, 2) NOT NULL COMMENT 'The base selling price set by the seller for this unit.',
  `stock_quantity` INT NULL COMMENT 'The current inventory level for this unit for this seller.',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Flag indicating if the seller is currently selling this unit.',
  `is_out_of_stock` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag to quickly identify if the stock is zero.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the seller added this unit.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_product_unit` (`seller_id`, `product_unit_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_unit_id`) REFERENCES `product_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Seller-specific pricing, stock, and status for each product unit they sell. Inventory is managed here, linked to the parent seller.';

CREATE TABLE `seller_product_legal_entity_map` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Primary key for the mapping.',
    `seller_product_unit_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the seller\'s specific product unit.',
    `legal_entity_id` BIGINT UNSIGNED NOT NULL COMMENT 'FK to the legal entity responsible for billing this product.',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_product_entity_map` (`seller_product_unit_id`, `legal_entity_id`),
    FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`legal_entity_id`) REFERENCES `seller_legal_entities`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Crucial link that maps a product being sold to the specific legal entity that will handle its invoicing and accounting.';

-- ... (Continue with the rest of the tables)

SET foreign_key_checks = 1;