-- =============================================================================
-- GOKRISHI E-COMMERCE PLATFORM DATABASE SCHEMA
-- =============================================================================
--
-- Author:      Akash Mittal
-- Create date: 2023-10-27
-- Version:     9.7
-- Description: This script defines the complete database schema for the Gokrishi
--              platform, a comprehensive B2B e-commerce solution for sellers,
--              brands, and their customers. It includes modules for user
--              management, product catalog, inventory, ordering, billing,
--              payments, delivery logistics, accounting, and advanced reporting.
--
--              Version 9.7 adds comprehensive documentation to all tables and
--              columns to improve clarity for developers and AI models.
--
-- =============================================================================

SET NAMES utf8mb4;
SET time_zone = '+05:30';
SET foreign_key_checks = 0;

-- =============================================
-- Section: Platform Configuration
-- Purpose: Stores global settings and configurations for the entire platform.
-- =============================================

--
-- Table: platform_settings
-- Purpose: Holds key-value pairs for platform-wide operational parameters,
--          such as feature toggles, default values, and system limits.
--
CREATE TABLE `platform_settings` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `setting_key` VARCHAR(100) NOT NULL UNIQUE COMMENT 'The unique identifier for the setting (e.g., SESSION_HISTORY_RETENTION_DAYS).',
  `setting_value` VARCHAR(255) NOT NULL COMMENT 'The value of the setting.',
  `description` TEXT NULL COMMENT 'A human-readable description of what the setting controls.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores platform-wide configuration settings.';

-- =============================================
-- Section: Internationalization
-- Purpose: Manages languages and regional data.
-- =============================================

--
-- Table: languages
-- Purpose: Lists the languages supported by the platform for user interfaces and data translation.
--
CREATE TABLE `languages` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(10) NOT NULL UNIQUE COMMENT 'Standard language code (e.g., en-US, hi-IN).',
  `name` VARCHAR(50) NOT NULL UNIQUE COMMENT 'The full name of the language (e.g., English (US)).',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines supported languages for internationalization.';

-- =============================================
-- Section: Reference Geodata
-- Purpose: Defines geographical entities for addresses and service areas.
-- =============================================

--
-- Table: countries
--
CREATE TABLE `countries` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'The common name of the country.',
  `iso_code_2` CHAR(2) NOT NULL UNIQUE COMMENT 'The two-letter ISO 3166-1 alpha-2 country code.',
  `phone_code` VARCHAR(10) NOT NULL COMMENT 'The international direct-dialing phone code.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for countries.';

--
-- Table: states
--
CREATE TABLE `states` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL COMMENT 'The name of the state or province.',
  `country_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the countries table.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for states or provinces within countries.';

--
-- Table: cities
--
CREATE TABLE `cities` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL COMMENT 'The name of the city.',
  `state_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the states table.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`state_id`) REFERENCES `states` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for cities within states.';

--
-- Table: pincodes
--
CREATE TABLE `pincodes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `pincode` VARCHAR(10) NOT NULL UNIQUE COMMENT 'The postal code or ZIP code.',
  `city_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the cities table.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`city_id`) REFERENCES `cities` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for postal codes (pincodes).';


-- =============================================
-- Section: Core User & Authentication
-- Purpose: Manages user accounts, authentication, sessions, and related entities.
-- =============================================

--
-- Table: users
-- Purpose: The central table for all individuals interacting with the platform.
--          A single user can act in multiple roles (e.g., as a customer, a seller staff, a brand staff).
--
CREATE TABLE `users` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `is_admin` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag to identify platform-level administrators with superuser privileges.',
  `country_id` INT UNSIGNED NOT NULL COMMENT 'The user's primary country, influencing phone code and regional settings.',
  `primary_mobile` VARCHAR(15) NOT NULL COMMENT 'The user's primary mobile number, used for login and notifications.',
  `password_hash` VARCHAR(255) NULL COMMENT 'Salted hash of the user's password for local authentication.',
  `primary_email` VARCHAR(255) NULL UNIQUE COMMENT 'The user's primary email address, can be used for login and notifications.',
  `google_id` VARCHAR(255) NULL UNIQUE COMMENT 'The unique identifier from Google for SSO (Single Sign-On).',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'Globally Unique Identifier for synchronizing this user with an external Tally accounting system.',
  `first_name` VARCHAR(100) NULL COMMENT 'The user's given name.',
  `middle_name` VARCHAR(100) NULL COMMENT 'The user's middle name.',
  `last_name` VARCHAR(100) NOT NULL COMMENT 'The user's family name or surname.',
  `legal_name` VARCHAR(300) NOT NULL COMMENT 'The full legal name of the user, used for official documents like invoices.',
  `profile_image_url` VARCHAR(512) NULL COMMENT 'URL for the user's profile picture.',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Toggles whether the user account is enabled or disabled platform-wide.',
  `is_mobile_verified` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if the user has verified their mobile number via OTP.',
  `is_email_verified` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if the user has verified their email address.',
  `preferred_language_id` INT UNSIGNED NULL COMMENT 'The user's preferred language for the UI, linking to the languages table.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of when the user account was created.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update to the user's record.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_mobile` (`country_id`, `primary_mobile`),
  FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`),
  FOREIGN KEY (`preferred_language_id`) REFERENCES `languages` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Central table for all platform users and their core profile data.';

--
-- Table: user_sessions
-- Purpose: Tracks active user login sessions for authentication management.
--
CREATE TABLE `user_sessions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the users table.',
  `token` VARCHAR(255) NOT NULL UNIQUE COMMENT 'The unique authentication token (e.g., JWT) for this session.',
  `active_account_type` ENUM('CUSTOMER', 'SELLER', 'SUPPLIER') NULL COMMENT 'Specifies the user's current operational context (e.g., acting as a seller).',
  `active_account_id` BIGINT UNSIGNED NULL COMMENT 'The ID of the specific seller, customer, or supplier account being used.',
  `ip_address` VARCHAR(45) NULL COMMENT 'The IP address from which the session was initiated.',
  `user_agent` TEXT NULL COMMENT 'The user agent string of the client device.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of session creation.',
  `expires_at` TIMESTAMP NOT NULL COMMENT 'Timestamp when the session token will expire.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores active user login sessions.';

--
-- Table: user_session_history
-- Purpose: Provides an audit trail of user login and logout activities for security and analytics.
--
CREATE TABLE `user_session_history` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the users table.',
  `session_token` VARCHAR(255) NOT NULL COMMENT 'The authentication token used during the session.',
  `ip_address` VARCHAR(45) NULL COMMENT 'The IP address used for the session.',
  `user_agent` TEXT NULL COMMENT 'The user agent of the client.',
  `login_at` TIMESTAMP NOT NULL COMMENT 'Timestamp of when the user logged in.',
  `logout_at` TIMESTAMP NULL COMMENT 'Timestamp of when the user logged out or the session ended.',
  `logout_reason` ENUM('USER_LOGOUT', 'SESSION_EXPIRED', 'ADMIN_TERMINATED') NULL COMMENT 'The reason for the session termination.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  INDEX `idx_user_session_history_login_at` (`login_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs historical user session data for auditing.';

--
-- Table: otps
-- Purpose: Manages one-time passwords for various verification purposes.
--
CREATE TABLE `otps` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `recipient` VARCHAR(255) NOT NULL COMMENT 'The destination of the OTP (mobile number or email address).',
  `otp_hash` VARCHAR(255) NOT NULL COMMENT 'A secure hash of the one-time password (e.g., SHA-256).',
  `purpose` ENUM('LOGIN', 'VERIFY_MOBILE', 'VERIFY_EMAIL', 'RESET_PASSWORD') NOT NULL COMMENT 'The specific action for which the OTP was generated.',
  `is_used` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag to prevent OTP reuse.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of OTP creation.',
  `expires_at` TIMESTAMP NOT NULL COMMENT 'Timestamp when the OTP becomes invalid.',
  PRIMARY KEY (`id`),
  INDEX `idx_otp_recipient` (`recipient`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores and manages one-time passwords for verification.';

--
-- Table: addresses
-- Purpose: Stores physical addresses associated with users, used for billing and delivery.
--
CREATE TABLE `addresses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the users table.',
  `address_line_1` VARCHAR(255) NOT NULL COMMENT 'The primary line of the street address.',
  `address_line_2` VARCHAR(255) NULL COMMENT 'The secondary line of the street address (e.g., apartment, suite).',
  `pincode_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the pincodes table.',
  `latitude` DECIMAL(10, 8) NULL COMMENT 'The geographic latitude for mapping.',
  `longitude` DECIMAL(11, 8) NULL COMMENT 'The geographic longitude for mapping.',
  `address_type` ENUM('BILLING', 'DELIVERY') NOT NULL COMMENT 'Indicates if the address is for billing or delivery purposes.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`pincode_id`) REFERENCES `pincodes` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores physical addresses for users.';


-- =============================================
-- Section: Product Catalog
-- Purpose: Manages the master repository of all products, brands, and categories on the platform.
-- =============================================

--
-- Table: brands
-- Purpose: Represents the manufacturers or brands of the products sold on the platform.
--
CREATE TABLE `brands` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NULL COMMENT 'The primary user account that owns and manages the brand profile.',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration.',
  `logo_url` VARCHAR(512) NULL COMMENT 'URL for the brand's official logo.',
  `logo_last_updated_at` TIMESTAMP NULL COMMENT 'Timestamp of when the logo was last changed.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of brand creation.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines product brands or manufacturers.';

--
-- Table: brand_translations
-- Purpose: Stores multilingual names for brands.
--
CREATE TABLE `brand_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `brand_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the brands table.',
    `language_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the languages table.',
    `name` VARCHAR(150) NOT NULL COMMENT 'The translated name of the brand.',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_brand_translation` (`brand_id`, `language_id`),
    FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores translated names for brands in different languages.';

--
-- Table: categories
-- Purpose: Defines the hierarchical structure for product classification.
--
CREATE TABLE `categories` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_category_id` INT UNSIGNED NULL COMMENT 'Foreign key linking to itself for creating a nested category tree.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of category creation.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`parent_category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines the product category hierarchy.';

--
-- Table: category_translations
-- Purpose: Stores multilingual names for categories.
--
CREATE TABLE `category_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `category_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the categories table.',
    `language_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the languages table.',
    `name` VARCHAR(150) NOT NULL COMMENT 'The translated name of the category.',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_category_translation` (`category_id`, `language_id`),
    FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores translated names for categories in different languages.';

--
-- Table: products
-- Purpose: The master table for all products available on the platform. This is a central, shared resource.
--
CREATE TABLE `products` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the brand of the product.',
  `category_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the primary category of the product.',
  `product_type` ENUM('GOODS', 'SERVICE') NOT NULL DEFAULT 'GOODS' COMMENT 'Specifies if the product is a physical good or a service.',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration (Stock Item).',
  `hsn_code` VARCHAR(20) NOT NULL COMMENT 'Harmonized System of Nomenclature code for GST compliance. Mandatory.',
  `barcode` VARCHAR(100) NULL COMMENT 'The products official barcode (e.g., EAN, UPC).',
  `gst_percentage` DECIMAL(5, 2) NOT NULL DEFAULT 0.00 COMMENT 'The applicable Goods and Services Tax rate.',
  `cess_percentage` DECIMAL(5, 2) NOT NULL DEFAULT 0.00 COMMENT 'The applicable CESS tax rate.',
  `status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT 'The approval and visibility status of the product in the master catalog.',
  `created_by_seller_id` BIGINT UNSIGNED NULL COMMENT 'The seller who initially requested or created this product listing.',
  `managed_by_brand_id` INT UNSIGNED NULL COMMENT 'The brand that has been given editorial control over this product listing.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp of product creation.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`),
  FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`),
  FOREIGN KEY (`created_by_seller_id`) REFERENCES `sellers` (`id`) ON DELETE SET NULL,
  FOREIGN KEY (`managed_by_brand_id`) REFERENCES `brands` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Master table for all products on the platform.';

--
-- Table: product_requests
-- Purpose: A staging area for new products requested by sellers, awaiting approval from platform admins.
--
CREATE TABLE `product_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `requested_by_seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'The seller who submitted the request.',
  `product_name` VARCHAR(255) NOT NULL COMMENT 'The proposed name of the new product.',
  `brand_name` VARCHAR(150) NULL COMMENT 'The proposed brand.',
  `category_name` VARCHAR(150) NULL COMMENT 'The proposed category.',
  `short_description` VARCHAR(500) NULL COMMENT 'A brief description.',
  `detailed_description` TEXT NULL COMMENT 'A full description.',
  `hsn_code` VARCHAR(20) NULL COMMENT 'The proposed HSN code.',
  `barcode` VARCHAR(100) NULL COMMENT 'The proposed barcode.',
  `gst_percentage` DECIMAL(5, 2) NULL COMMENT 'The proposed GST rate.',
  `cess_percentage` DECIMAL(5, 2) NULL COMMENT 'The proposed CESS rate.',
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT 'The approval status of the request.',
  `approved_by_admin_id` BIGINT UNSIGNED NULL COMMENT 'The admin user who approved or rejected the request.',
  `created_product_id` BIGINT UNSIGNED NULL COMMENT 'If approved, links to the new entry in the products table.',
  `rejection_reason` TEXT NULL COMMENT 'Reason for rejection, if applicable.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`requested_by_seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`approved_by_admin_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  FOREIGN KEY (`created_product_id`) REFERENCES `products` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Staging table for new product requests from sellers.';

--
-- Table: product_request_images
-- Purpose: Stores image URLs associated with a new product request.
--
CREATE TABLE `product_request_images` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_request_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the product_requests table.',
  `image_url` VARCHAR(512) NOT NULL COMMENT 'URL of the proposed product image.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_request_id`) REFERENCES `product_requests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores images for new product requests.';

--
-- Table: product_translations
-- Purpose: Stores multilingual names and descriptions for products.
--
CREATE TABLE `product_translations` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `product_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the products table.',
    `language_id` INT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the languages table.',
    `name` VARCHAR(255) NOT NULL COMMENT 'The translated name of the product.',
    `short_description` VARCHAR(500) NULL COMMENT 'The translated short description.',
    `detailed_description` TEXT NULL COMMENT 'The translated detailed description.',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_product_translation` (`product_id`, `language_id`),
    FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`language_id`) REFERENCES `languages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores translated content for products.';

--
-- Table: product_units
-- Purpose: Defines the different packaging units for a product (e.g., piece, box, crate).
--
CREATE TABLE `product_units` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the products table.',
  `name` VARCHAR(50) NOT NULL COMMENT 'The name of the unit (e.g., Packet, Crate, Box, Subscription).',
  `conversion_rate` DECIMAL(10,2) NOT NULL DEFAULT 1.00 COMMENT 'Factor to convert this unit to the base unit (e.g., a crate has 24 packets).',
  `is_returnable_asset` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if this unit is a physical asset that customers should return (e.g., a crate).',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines the saleable and trackable units for each product.';

--
-- Table: product_images
-- Purpose: Stores multiple images for a single product.
--
CREATE TABLE `product_images` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the products table.',
  `image_url` VARCHAR(512) NOT NULL COMMENT 'URL of the product image.',
  `source_url` VARCHAR(512) NULL COMMENT 'Original URL if the image was scraped.',
  `is_scraped` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if the image was obtained via web scraping.',
  `sort_order` INT NOT NULL DEFAULT 0 COMMENT 'The order in which to display the images.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores image gallery for products.';

--
-- Table: product_change_requests
-- Purpose: Manages proposed edits to existing product listings, subject to approval.
--
CREATE TABLE `product_change_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL COMMENT 'The product being edited.',
  `requested_by_user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The user who proposed the changes.',
  `change_type` ENUM('IMAGES', 'UNITS', 'DESCRIPTION', 'DETAILS') NOT NULL COMMENT 'The type of change being requested.',
  `proposed_changes` JSON NOT NULL COMMENT 'JSON object containing the proposed new values.',
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'APPLIED') NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT 'The approval status of the change request.',
  `rejection_reason` TEXT NULL COMMENT 'Reason for rejection, if applicable.',
  `approved_by_user_id` BIGINT UNSIGNED NULL COMMENT 'The user who approved the change.',
  `approved_at` TIMESTAMP NULL COMMENT 'Timestamp of approval.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`requested_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`approved_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tracks proposed changes to master product data.';


-- =============================================
-- Section: Seller & Inventory
-- Purpose: Manages seller profiles, their specific product offerings, pricing, and inventory.
-- =============================================

--
-- Table: sellers
-- Purpose: Represents a business entity that sells products on the platform.
--
CREATE TABLE `sellers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The primary user account that owns and manages the seller profile.',
  `is_platform_admin` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Identifies this seller as the platform itself, used for internal billing to other sellers.',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration (Ledger).',
  `company_name` VARCHAR(255) NOT NULL COMMENT 'The legal name of the seller's company.',
  `company_logo_url` VARCHAR(512) NULL COMMENT 'URL for the seller's company logo.',
  `gst_number` VARCHAR(15) NULL UNIQUE COMMENT 'The sellers Goods and Services Tax Identification Number.',
  `gst_state_id` INT UNSIGNED NULL COMMENT 'The state associated with the GST number.',
  `pan_number` VARCHAR(10) NULL COMMENT 'The sellers Permanent Account Number (for tax purposes).',
  `account_status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'SUSPENDED') NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT 'The operational status of the seller account.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`gst_state_id`) REFERENCES `states` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Core table for seller business profiles.';

--
-- Table: seller_subscription_plans
-- Purpose: Defines the various subscription tiers available to sellers.
--
CREATE TABLE `seller_subscription_plans` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plan_name` VARCHAR(150) NOT NULL COMMENT 'The name of the subscription plan (e.g., Basic, Pro, Enterprise).',
  `monthly_fee` DECIMAL(10, 2) NOT NULL COMMENT 'The recurring monthly cost of the plan.',
  `setup_fee` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'A one-time fee for setting up the plan.',
  `features` JSON NULL COMMENT 'JSON array of features included, e.g. ["WHITELABEL", "GST_REPORTING"].',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Toggles if this plan is available for new subscriptions.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines the subscription plans available to sellers.';

--
-- Table: seller_subscriptions
-- Purpose: Links a seller to their chosen subscription plan.
--
CREATE TABLE `seller_subscriptions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the sellers table.',
  `plan_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the seller_subscription_plans table.',
  `status` ENUM('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELLED') NOT NULL COMMENT 'The current billing status of the subscription.',
  `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when the subscription began.',
  `renews_at` TIMESTAMP NULL COMMENT 'Timestamp for the next renewal date.',
  `cancelled_at` TIMESTAMP NULL COMMENT 'Timestamp if the subscription was cancelled.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_subscription` (`seller_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`plan_id`) REFERENCES `seller_subscription_plans` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages the subscription status of sellers.';

--
-- Table: seller_whitelabel_settings
-- Purpose: Stores customization settings for a seller's whitelabel portal and apps.
--
CREATE TABLE `seller_whitelabel_settings` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the sellers table.',
  `is_enabled` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Master switch to enable/disable whitelabel features for this seller.',
  `portal_custom_domain` VARCHAR(255) NULL UNIQUE COMMENT 'The custom domain for the sellers web portal (e.g., portal.sellercompany.com).',
  `portal_theme_color` VARCHAR(7) NULL COMMENT 'Primary color for the whitelabel portal UI (e.g., #RRGGBB).',
  `app_name` VARCHAR(100) NULL COMMENT 'The custom name for the whitelabel mobile app.',
  `app_bundle_id` VARCHAR(100) NULL UNIQUE COMMENT 'The unique bundle ID for the mobile app (e.g., com.seller.app).',
  `app_icon_url` VARCHAR(512) NULL COMMENT 'URL for the custom mobile app icon.',
  `app_splash_screen_url` VARCHAR(512) NULL COMMENT 'URL for the custom mobile app splash screen.',
  `app_store_id` VARCHAR(100) NULL COMMENT 'ID for the app in the Google Play Store.',
  `apple_app_store_id` VARCHAR(100) NULL COMMENT 'ID for the app in the Apple App Store.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_whitelabel_settings` (`seller_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Settings for seller-specific whitelabel branding.';

--
-- Table: whitelabel_promo_campaigns
-- Purpose: Manages promotional campaigns for a seller's whitelabel portal.
--
CREATE TABLE `whitelabel_promo_campaigns` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'The seller running the campaign.',
    `campaign_name` VARCHAR(255) NOT NULL COMMENT 'The internal name for the campaign.',
    `promo_code` VARCHAR(50) NOT NULL UNIQUE COMMENT 'The promotional code used in the campaign URL.',
    `target_url` VARCHAR(512) NOT NULL COMMENT 'The destination URL for the campaign.',
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Toggles the campaign on or off.',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages promotional campaigns for seller whitelabel portals.';

--
-- Table: whitelabel_traffic_log
-- Purpose: Logs incoming traffic from whitelabel promotional campaigns.
--
CREATE TABLE `whitelabel_traffic_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `campaign_id` BIGINT UNSIGNED NOT NULL COMMENT 'The campaign that generated the traffic.',
    `source` VARCHAR(100) NULL COMMENT 'The source of the traffic (e.g., facebook, twitter, email).',
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `visited_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`campaign_id`) REFERENCES `whitelabel_promo_campaigns` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs traffic from seller whitelabel campaigns.';

--
-- Table: seller_document_branding
-- Purpose: Stores branding settings for documents (e.g., invoices, reports) generated by a seller.
--
CREATE TABLE `seller_document_branding` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'Foreign key linking to the sellers table.',
  `accent_color` VARCHAR(7) NULL COMMENT 'The primary color for document templates (e.g., #RRGGBB).',
  `header` TEXT NULL COMMENT 'Custom text or HTML for the document header.',
  `footer` TEXT NULL COMMENT 'Custom text or HTML for the document footer.',
  `show_platform_logo` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Toggles the visibility of the main platform logo on documents.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_document_branding_seller_id` (`seller_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Custom branding for seller-generated documents.';

--
-- Table: seller_customer_map
-- Purpose: The pivotal table linking a customer (user or brand) to a seller, forming a business relationship.
--
CREATE TABLE `seller_customer_map` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NULL COMMENT 'The user who is the customer. Null if brand_id is set.',
  `brand_id` INT UNSIGNED NULL COMMENT 'The brand that is the customer. Null if user_id is set.',
  `seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'The seller in this relationship.',
  `tally_guid` VARCHAR(255) NULL UNIQUE COMMENT 'GUID for Tally integration (Ledger for this specific relationship).',
  `price_list_id` BIGINT UNSIGNED NULL COMMENT 'The specific price list assigned to this customer by the seller.',
  `credit_limit_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'The maximum credit amount the seller extends to this customer.',
  `running_balance` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'The customers current outstanding balance. (Positive means customer owes seller).',
  `unsettled_payments_balance` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Sum of payments from the customer that are pending clearance (e.g., cheques).',
  `unsettled_returnable_assets_balance` INT NOT NULL DEFAULT 0 COMMENT 'Sum of returnable assets collected from the customer but not yet verified by the warehouse.',
  `alias_name` VARCHAR(100) NULL COMMENT 'An alias or nickname the seller uses for this customer.',
  `status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'INACTIVE', 'UNSERVICEABLE', 'BLACKLISTED') NOT NULL DEFAULT 'PENDING_APPROVAL' COMMENT 'The status of the relationship.',
  `status_reason` TEXT NULL COMMENT 'Reason for the current status (e.g., why a customer is unserviceable).',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Maps customers (users or brands) to sellers.';

--
-- Table: seller_staff
-- Purpose: Links users to a seller account, making them staff members.
--
CREATE TABLE `seller_staff` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL COMMENT 'The seller the user works for.',
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The user who is the staff member.',
  `salary_structure` ENUM('DAILY', 'MONTHLY', 'COMMISSION_BASED') NOT NULL DEFAULT 'MONTHLY' COMMENT 'The basis for salary calculation.',
  `daily_rate` DECIMAL(10, 2) NULL COMMENT 'Pay rate for DAILY salary structure.',
  `monthly_salary` DECIMAL(10, 2) NULL COMMENT 'Salary for MONTHLY structure.',
  `commission_rate` DECIMAL(5, 2) NULL COMMENT 'Commission percentage for COMMISSION_BASED structure.',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Toggles if the staff member is currently active.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_user` (`seller_id`, `user_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Links users as staff members to a seller.';

--
-- Table: seller_staff_roles
-- Purpose: Defines the set of roles a staff member can have within a seller's organization.
--
CREATE TABLE `seller_staff_roles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'The name of the role (e.g., Order Manager, Accountant).',
  `description` TEXT NULL COMMENT 'A description of the permissions and responsibilities of the role.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines available staff roles within a seller organization.';

--
-- Table: seller_staff_role_assignments
-- Purpose: Assigns one or more roles to a specific staff member.
--
CREATE TABLE `seller_staff_role_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `staff_id` BIGINT UNSIGNED NOT NULL COMMENT 'The staff member being assigned the role.',
  `role_id` INT UNSIGNED NOT NULL COMMENT 'The role being assigned.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_staff_role` (`staff_id`, `role_id`),
  FOREIGN KEY (`staff_id`) REFERENCES `seller_staff` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`role_id`) REFERENCES `seller_staff_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Assigns roles to seller staff members.';

--
-- Table: seller_product_units
-- Purpose: This is the seller's specific inventory/pricing record for a master product unit.
--
CREATE TABLE `seller_product_units` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `product_unit_id` BIGINT UNSIGNED NOT NULL COMMENT 'Links to the master product unit from the catalog.',
  `mrp` DECIMAL(10, 2) NULL COMMENT 'Maximum Retail Price, serves as the base for pricing calculations.',
  `purchase_rate` DECIMAL(10, 2) NULL COMMENT 'The rate at which the seller purchased this unit.',
  `selling_rate` DECIMAL(10, 2) NOT NULL COMMENT 'The sellers base selling price for this unit (before customer-specific discounts).',
  `stock_quantity` INT NULL COMMENT 'The current inventory level. Can be null if inventory is not tracked (e.g., for services).',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Toggles whether this seller offers this product unit for sale.',
  `is_out_of_stock` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Indicates if the item is currently out of stock.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_product_unit` (`seller_id`, `product_unit_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_unit_id`) REFERENCES `product_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Seller-specific pricing and stock for each product unit.';

--
-- Table: price_lists
-- Purpose: Defines a collection of special prices or discounts that can be assigned to customers.
--
CREATE TABLE `price_lists` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL COMMENT 'The name of the price list (e.g., Wholesale, VIP Customers).',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Container for customer-specific pricing rules.';

--
-- Table: price_list_items
-- Purpose: Defines a specific product discount within a price list.
--
CREATE TABLE `price_list_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `price_list_id` BIGINT UNSIGNED NOT NULL,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL COMMENT 'The specific seller product unit this discount applies to.',
  `discount_type` ENUM('FIXED', 'PERCENTAGE') NOT NULL COMMENT 'Whether the discount is a fixed amount or a percentage.',
  `discount_value` DECIMAL(10, 2) NOT NULL COMMENT 'The value of the discount.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`price_list_id`) REFERENCES `price_lists` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Specific product discounts within a price list.';


-- =============================================
-- Section: Customer & Order Management
-- Purpose: Manages customer orders, subscriptions, and balances.
-- =============================================

--
-- Table: customer_returnable_assets
-- Purpose: Tracks the balance of returnable assets (e.g., crates, bottles) for each customer.
--
CREATE TABLE `customer_returnable_assets` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL COMMENT 'Links to the seller-customer relationship.',
  `product_unit_id` BIGINT UNSIGNED NOT NULL COMMENT 'The specific returnable asset unit being tracked.',
  `balance` INT NOT NULL DEFAULT 0 COMMENT 'The current balance of this asset. (Positive means customer has the assets).',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_customer_returnable` (`seller_customer_map_id`, `product_unit_id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_unit_id`) REFERENCES `product_units` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tracks balance of returnable assets for each customer.';

--
-- Table: customer_unsettled_items_log
-- Purpose: Provides a customer-facing, line-item view of all payments and assets that are pending settlement.
--
CREATE TABLE `customer_unsettled_items_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL COMMENT 'The customer this log entry belongs to.',
  `item_type` ENUM('PAYMENT', 'RETURNABLE_ASSET') NOT NULL COMMENT 'The type of item that is unsettled.',
  `reference_id` BIGINT UNSIGNED NOT NULL COMMENT 'The ID of the source transaction (e.g., payment_transactions.id, returnable_asset_collections.id).',
  `description` VARCHAR(255) NOT NULL COMMENT 'A human-readable description of the item (e.g., "Cheque #12345", "12 Crates Collected").',
  `amount_or_quantity` DECIMAL(12, 2) NOT NULL COMMENT 'The monetary amount or item quantity.',
  `status` VARCHAR(100) NOT NULL COMMENT 'The current status of the item (e.g., "Pending Deposit", "Pending Verification").',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When the unsettled item was logged.',
  `settled_at` TIMESTAMP NULL COMMENT 'When the item was fully settled or cleared.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`) ON DELETE CASCADE,
  INDEX `idx_unsettled_items_customer` (`seller_customer_map_id`, `settled_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Customer-facing log of items pending settlement.';

--
-- Table: orders
-- Purpose: The main table for capturing customer orders.
--
CREATE TABLE `orders` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `order_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `scheduled_delivery_date` DATE NULL COMMENT 'If not null, the order is scheduled for a future delivery date.',
  `scheduled_delivery_shift_id` BIGINT UNSIGNED NULL COMMENT 'The specific delivery shift for a scheduled order.',
  `total_amount` DECIMAL(10, 2) NOT NULL COMMENT 'The total value of the order, including all taxes.',
  `order_status` ENUM('SCHEDULED', 'PENDING', 'CONFIRMED', 'DISPATCHED', 'DELIVERED', 'CANCELLED', 'DELIVERY_MODIFIED') NOT NULL,
  `delivery_address_id` BIGINT UNSIGNED NULL COMMENT 'Can be null for service products or pickups.',
  `delivery_type` ENUM('PICKUP', 'SELLER_DELIVERY', 'THIRD_PARTY_DELIVERY', 'NOT_APPLICABLE') NOT NULL,
  `cancellation_reason` TEXT NULL,
  `is_mapped_to_load` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag indicating if this order has been assigned to a delivery load.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`),
  FOREIGN KEY (`delivery_address_id`) REFERENCES `addresses` (`id`),
  FOREIGN KEY (`scheduled_delivery_shift_id`) REFERENCES `delivery_shifts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Captures customer sales orders.';

--
-- Table: order_items
-- Purpose: Stores the individual line items for each order.
--
CREATE TABLE `order_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT UNSIGNED NOT NULL,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL,
  `taxable_value` DECIMAL(10, 2) NOT NULL COMMENT 'The base price per unit before taxes, after discounts.',
  `cgst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Central GST amount for the line item.',
  `sgst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'State GST amount for the line item.',
  `igst_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Integrated GST amount for the line item (for inter-state transactions).',
  `cess_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'CESS amount for the line item.',
  `net_amount` DECIMAL(10, 2) NOT NULL COMMENT 'The final price per unit, inclusive of all taxes.',
  PRIMARY KEY (`id`),
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Individual line items within an order.';

--
-- Table: subscriptions
-- Purpose: Manages recurring orders for products or services.
--
CREATE TABLE `subscriptions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_customer_map_id` BIGINT UNSIGNED NOT NULL,
  `seller_product_unit_id` BIGINT UNSIGNED NOT NULL,
  `quantity` INT NOT NULL COMMENT 'The quantity to be delivered on each cycle.',
  `frequency` VARCHAR(50) NOT NULL COMMENT 'The delivery frequency (e.g., daily, weekly, or a custom cron string).',
  `status` ENUM('TRIAL', 'ACTIVE', 'PAST_DUE', 'CANCELED') NOT NULL DEFAULT 'ACTIVE',
  `start_date` DATE NOT NULL COMMENT 'The date the subscription begins.',
  `trial_ends_at` TIMESTAMP NULL COMMENT 'If in trial, the timestamp the trial ends.',
  `end_date` DATE NULL COMMENT 'The date the subscription ends (if not indefinite).',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_customer_map_id`) REFERENCES `seller_customer_map` (`id`),
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages recurring customer subscriptions for products.';

--
-- Table: seller_customer_route_assignments
-- Purpose: Assigns a customer to a specific delivery route and shift.
--
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
-- Purpose: Manages seller financial accounts, transactions, expenses, and payments.
-- =============================================

--
-- Table: seller_accounts
-- Purpose: Represents the financial accounts (cash, bank) held by a seller.
--
CREATE TABLE `seller_accounts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `account_name` VARCHAR(150) NOT NULL COMMENT 'The name of the account (e.g., "Cash in Hand", "HDFC Bank").',
  `account_type` ENUM('CASH', 'BANK', 'E_WALLET') NOT NULL,
  `account_number` VARCHAR(50) NULL COMMENT 'Account number for BANK accounts.',
  `bank_name` VARCHAR(150) NULL COMMENT 'Bank name for BANK accounts.',
  `ifsc_code` VARCHAR(20) NULL COMMENT 'IFSC code for BANK accounts.',
  `current_balance` DECIMAL(14, 2) NOT NULL DEFAULT 0.00 COMMENT 'The real-time balance of the account.',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines a sellers financial accounts (cash, bank, etc.).';

--
-- Table: account_entries
-- Purpose: Records every debit and credit transaction for each seller account, creating a ledger.
--
CREATE TABLE `account_entries` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `account_id` BIGINT UNSIGNED NOT NULL,
  `transaction_type` ENUM('CUSTOMER_PAYMENT', 'REFUND', 'PAYROLL_PAYMENT', 'SUPPLIER_PAYMENT', 'EXPENSE', 'CASH_DEPOSIT', 'INTERNAL_TRANSFER') NOT NULL,
  `reference_id` BIGINT UNSIGNED NOT NULL COMMENT 'ID of the source transaction (e.g., payment_transactions.id).',
  `entry_type` ENUM('DEBIT', 'CREDIT') NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `balance_after_transaction` DECIMAL(14, 2) NOT NULL COMMENT 'The account balance immediately after this entry.',
  `narration` TEXT NULL COMMENT 'A description of the transaction.',
  `entry_date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`account_id`) REFERENCES `seller_accounts` (`id`) ON DELETE CASCADE,
  INDEX `idx_reference` (`transaction_type`, `reference_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Ledger of all debit/credit entries for seller accounts.';

--
-- Table: account_transfers
-- Purpose: Logs internal fund transfers between a seller's own accounts (e.g., cash to bank).
--
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

--
-- Table: expense_categories
-- Purpose: Defines categories for organizing seller expenses.
--
CREATE TABLE `expense_categories` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `name` VARCHAR(150) NOT NULL COMMENT 'Name of the category (e.g., "Fuel", "Office Supplies").',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines categories for seller expenses.';

--
-- Table: expenses
-- Purpose: Logs business expenses incurred by a seller.
--
CREATE TABLE `expenses` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `expense_category_id` BIGINT UNSIGNED NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `expense_date` DATE NOT NULL,
  `paid_from_account_id` BIGINT UNSIGNED NOT NULL COMMENT 'The seller account used to pay for the expense.',
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `incurred_by_staff_id` BIGINT UNSIGNED NULL COMMENT 'The staff member who incurred the expense.',
  `approved_by_staff_id` BIGINT UNSIGNED NULL COMMENT 'The staff member who approved the expense claim.',
  `approved_at` TIMESTAMP NULL,
  `rejection_reason` TEXT NULL,
  `notes` TEXT NULL,
  `receipt_url` VARCHAR(512) NULL COMMENT 'URL of the scanned receipt or invoice.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`expense_category_id`) REFERENCES `expense_categories` (`id`),
  FOREIGN KEY (`paid_from_account_id`) REFERENCES `seller_accounts` (`id`),
  FOREIGN KEY (`incurred_by_staff_id`) REFERENCES `seller_staff` (`id`),
  FOREIGN KEY (`approved_by_staff_id`) REFERENCES `seller_staff` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Tracks seller business expenses.';


-- =============================================
-- Section: Billing & Payments
-- Purpose: Manages invoices, payment gateways, and payment transactions.
-- =============================================

--
-- Table: invoices
-- Purpose: Represents a bill issued to a customer for an order.
--
CREATE TABLE `invoices` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT UNSIGNED NOT NULL,
  `invoice_number` VARCHAR(50) NOT NULL UNIQUE,
  `invoice_date` DATE NOT NULL,
  `due_date` DATE NOT NULL,
  `total_amount` DECIMAL(12, 2) NOT NULL,
  `transaction_fee_amount` DECIMAL(12, 2) NULL COMMENT 'Fee added if the customer bears the payment gateway cost.',
  `status` ENUM('DRAFT', 'SENT', 'PAID', 'PARTIALLY_PAID', 'VOID') NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Represents customer invoices.';

--
-- Table: payment_gateway_providers
-- Purpose: A reference table of payment gateway companies integrated with the platform.
--
CREATE TABLE `payment_gateway_providers` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Name of the gateway provider (e.g., Razorpay, PayU, Stripe).',
  `transaction_fee_percentage` DECIMAL(5, 2) NULL COMMENT 'Default percentage-based fee.',
  `transaction_fee_fixed` DECIMAL(10, 2) NULL COMMENT 'Default fixed fee.',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Platform-wide switch for this provider.',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for supported payment gateway providers.';

--
-- Table: seller_payment_gateways
-- Purpose: Stores a seller's specific credentials and settings for a payment gateway.
--
CREATE TABLE `seller_payment_gateways` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `provider_id` INT UNSIGNED NOT NULL,
  `display_name` VARCHAR(150) NOT NULL COMMENT 'The name shown to customers at checkout.',
  `api_key_secret_ref` VARCHAR(255) NOT NULL COMMENT 'Reference to a secret manager key for the seller's API key.',
  `api_secret_secret_ref` VARCHAR(255) NOT NULL COMMENT 'Reference to a secret manager key for the seller's API secret.',
  `transaction_fee_bearer` ENUM('SELLER', 'CUSTOMER') NOT NULL DEFAULT 'SELLER' COMMENT 'Determines who absorbs the transaction fee.',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Seller-specific switch for this gateway.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_seller_provider` (`seller_id`, `provider_id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`provider_id`) REFERENCES `payment_gateway_providers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores seller-specific settings for payment gateways.';

--
-- Table: payment_transactions
-- Purpose: The central log for all monetary transactions on the platform.
--
CREATE TABLE `payment_transactions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_id` BIGINT UNSIGNED NULL COMMENT 'The invoice this payment is for.',
  `account_id` BIGINT UNSIGNED NOT NULL COMMENT 'The seller account receiving or sending the money.',
  `seller_customer_map_id` BIGINT UNSIGNED NULL COMMENT 'The customer involved in the transaction. Null for internal transactions like payroll.',
  `staff_id` BIGINT UNSIGNED NULL COMMENT 'Reference to staff for payroll payments.',
  `supplier_id` BIGINT UNSIGNED NULL COMMENT 'Reference to supplier for supplier payments.',
  `transaction_type` ENUM('CUSTOMER_PAYMENT', 'REFUND', 'PAYROLL_PAYMENT', 'SUPPLIER_PAYMENT') NOT NULL,
  `seller_payment_gateway_id` BIGINT UNSIGNED NULL COMMENT 'The gateway used for online payments.',
  `amount` DECIMAL(12, 2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `method` ENUM('CASH', 'BANK_TRANSFER', 'UPI', 'WEB_GATEWAY', 'CHEQUE', 'OTHER') NOT NULL COMMENT 'CHEQUE method is for seller-side data entry only, not for customer checkout.',
  `status` ENUM('PENDING', 'PENDING_DEPOSIT', 'PENDING_CLEARANCE', 'SUCCESSFUL', 'FAILED', 'BOUNCED', 'VOID') NOT NULL DEFAULT 'PENDING',
  `gateway_order_id` VARCHAR(255) NULL COMMENT 'The order ID from the payment gateway.',
  `gateway_payment_id` VARCHAR(255) NULL COMMENT 'The payment ID from the payment gateway.',
  `gateway_fee_amount` DECIMAL(12, 2) NULL COMMENT 'The actual fee charged by the payment gateway.',
  `transaction_fee_paid_by_customer` DECIMAL(12, 2) NULL COMMENT 'The portion of the gateway fee passed on to the customer.',
  `cheque_number` VARCHAR(50) NULL,
  `cheque_date` DATE NULL,
  `cheque_bank_name` VARCHAR(150) NULL,
  `cheque_front_image_url` VARCHAR(512) NULL COMMENT 'URL of compressed front image of the cheque.',
  `cheque_back_image_url` VARCHAR(512) NULL COMMENT 'URL of compressed back image of the cheque.',
  `voucher_entry_id` BIGINT UNSIGNED NULL COMMENT 'Link to the corresponding entry in the accounting voucher system.',
  `confirmed_by_user_id` BIGINT UNSIGNED NULL COMMENT 'The user (staff) who manually confirmed an offline payment.',
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

--
-- Table: cheque_deposits
-- Purpose: Manages the physical process of depositing multiple cheques into a bank account.
--
CREATE TABLE `cheque_deposits` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `deposited_into_account_id` BIGINT UNSIGNED NOT NULL COMMENT 'The bank account where the cheques were deposited.',
  `deposit_date` DATE NOT NULL,
  `total_amount` DECIMAL(12, 2) NOT NULL COMMENT 'The total value of all cheques in this deposit.',
  `deposit_slip_image_url` VARCHAR(512) NULL COMMENT 'URL of the compressed bank deposit slip image.',
  `status` ENUM('PENDING_CLEARANCE', 'COMPLETED', 'PARTIALLY_CLEARED', 'BOUNCED') NOT NULL,
  `deposited_by_user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The staff member who made the deposit.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`deposited_into_account_id`) REFERENCES `seller_accounts` (`id`),
  FOREIGN KEY (`deposited_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages batches of cheques for bank deposit.';

--
-- Table: cheque_deposit_items
-- Purpose: Links individual cheque transactions to a bulk cheque deposit.
--
CREATE TABLE `cheque_deposit_items` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `cheque_deposit_id` BIGINT UNSIGNED NOT NULL,
  `payment_transaction_id` BIGINT UNSIGNED NOT NULL COMMENT 'The specific cheque transaction included in this deposit.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cheque_deposit_item` (`cheque_deposit_id`, `payment_transaction_id`),
  FOREIGN KEY (`cheque_deposit_id`) REFERENCES `cheque_deposits` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`payment_transaction_id`) REFERENCES `payment_transactions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Links individual cheques to a deposit batch.';

--
-- Table: payment_refunds
-- Purpose: Logs refund transactions.
--
CREATE TABLE `payment_refunds` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `payment_transaction_id` BIGINT UNSIGNED NOT NULL COMMENT 'The original payment transaction being refunded.',
  `amount` DECIMAL(12, 2) NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'INR',
  `reason` TEXT NULL,
  `status` ENUM('PENDING', 'PROCESSED', 'FAILED') NOT NULL DEFAULT 'PENDING',
  `gateway_refund_id` VARCHAR(255) NULL COMMENT 'The refund ID from the payment gateway.',
  `voucher_entry_id` BIGINT UNSIGNED NULL COMMENT 'Link to the credit note voucher.',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`payment_transaction_id`) REFERENCES `payment_transactions` (`id`),
  FOREIGN KEY (`voucher_entry_id`) REFERENCES `voucher_entries` (`id`),
  INDEX `idx_refund_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs payment refund transactions.';

--
-- Table: payment_events
-- Purpose: Detailed log of all events in a payment's lifecycle, for auditing and debugging.
--
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
  `event_data` JSON NULL COMMENT 'Raw data associated with the event, e.g., webhook payload.',
  `is_processed` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'For async events, tracks if business logic has been executed.',
  `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  FOREIGN KEY (`payment_transaction_id`) REFERENCES `payment_transactions` (`id`),
  FOREIGN KEY (`payment_refund_id`) REFERENCES `payment_refunds` (`id`),
  INDEX `idx_event_processing` (`is_processed`, `event_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Detailed audit trail of payment lifecycle events.';


-- =============================================
-- Section: Communication & Support
-- Purpose: Manages notifications, messaging, and support tickets.
-- =============================================

--
-- Table: notifications
--
CREATE TABLE `notifications` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The user who receives the notification.',
  `notification_type` VARCHAR(100) NOT NULL COMMENT 'e.g., ORDER_STATUS_UPDATE, NEW_MESSAGE, SUBSCRIPTION_REMINDER.',
  `content` TEXT NOT NULL,
  `reference_type` VARCHAR(100) NULL COMMENT 'The type of entity this notification refers to (e.g., ORDER, MESSAGE).',
  `reference_id` BIGINT UNSIGNED NULL COMMENT 'The ID of the entity this notification refers to.',
  `is_read` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  INDEX `idx_notification_user_read` (`user_id`, `is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores user notifications.';

--
-- Table: messages
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages direct messages between users.';

--
-- Table: support_tickets
--
CREATE TABLE `support_tickets` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `created_by_user_id` BIGINT UNSIGNED NOT NULL,
  `recipient_user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The user this ticket is directed to (e.g., a seller or platform admin).',
  `assigned_to_staff_id` BIGINT UNSIGNED NULL COMMENT 'The specific staff member handling the ticket.',
  `context_type` VARCHAR(100) NULL COMMENT 'The type of entity the ticket is about (e.g., ORDER, PAYMENT).',
  `context_id` BIGINT UNSIGNED NULL,
  `subject` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL COMMENT 'The initial message from the ticket creator.',
  `status` ENUM('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED') NOT NULL DEFAULT 'OPEN',
  `priority` ENUM('LOW', 'MEDIUM', 'HIGH') NOT NULL DEFAULT 'MEDIUM',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`created_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`recipient_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`assigned_to_staff_id`) REFERENCES `seller_staff` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages customer support tickets.';

--
-- Table: support_ticket_replies
--
CREATE TABLE `support_ticket_replies` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `ticket_id` BIGINT UNSIGNED NOT NULL,
  `user_id` BIGINT UNSIGNED NOT NULL COMMENT 'The user who wrote the reply.',
  `reply_body` TEXT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`ticket_id`) REFERENCES `support_tickets` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores replies to support tickets.';


-- =============================================
-- Section: Brand Engagement & Monetization
-- Purpose: Manages brand-specific features like whitelabeling and advertising.
-- =============================================

--
-- Table: brand_staff
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Links users as staff members to a brand.';

--
-- Table: brand_staff_roles
--
CREATE TABLE `brand_staff_roles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `role_name` VARCHAR(100) NOT NULL UNIQUE,
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines available roles within a brand organization.';

--
-- Table: brand_staff_role_assignments
--
CREATE TABLE `brand_staff_role_assignments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `staff_id` BIGINT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_staff_role` (`staff_id`, `role_id`),
  FOREIGN KEY (`staff_id`) REFERENCES `brand_staff` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`role_id`) REFERENCES `brand_staff_roles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Assigns roles to brand staff members.';

--
-- Table: brand_whitelabel_subscription_plans
--
CREATE TABLE `brand_whitelabel_subscription_plans` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plan_name` VARCHAR(150) NOT NULL,
  `monthly_fee` DECIMAL(10, 2) NOT NULL,
  `setup_fee` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `features` JSON NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines whitelabel subscription plans for brands.';

--
-- Table: brand_whitelabel_subscriptions
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages the whitelabel subscription status of brands.';

--
-- Table: brand_whitelabel_settings
--
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
  `auto_add_new_products` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Automatically make new products from this brand visible.',
  `auto_add_new_sellers` BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Automatically make new sellers of this brands products visible.',
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_whitelabel_settings` (`brand_id`),
  FOREIGN KEY (`brand_id`) REFERENCES `brands` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Settings for brand-specific whitelabel portals.';

--
-- Table: brand_whitelabel_visible_products
--
CREATE TABLE `brand_whitelabel_visible_products` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_whitelabel_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `is_visible` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_whitelabel_product` (`brand_whitelabel_id`, `product_id`),
  FOREIGN KEY (`brand_whitelabel_id`) REFERENCES `brand_whitelabel_settings` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Controls product visibility on a brands whitelabel portal.';

--
-- Table: brand_whitelabel_visible_sellers
--
CREATE TABLE `brand_whitelabel_visible_sellers` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `brand_whitelabel_id` BIGINT UNSIGNED NOT NULL,
  `seller_id` BIGINT UNSIGNED NOT NULL,
  `is_visible` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_brand_whitelabel_seller` (`brand_whitelabel_id`, `seller_id`),
  FOREIGN KEY (`brand_whitelabel_id`) REFERENCES `brand_whitelabel_settings` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Controls seller visibility on a brands whitelabel portal.';

--
-- Table: brand_whitelabel_promo_campaigns
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages promotional campaigns for brand whitelabel portals.';

--
-- Table: brand_whitelabel_traffic_log
--
CREATE TABLE `brand_whitelabel_traffic_log` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `campaign_id` BIGINT UNSIGNED NOT NULL,
    `source` VARCHAR(100) NULL,
    `ip_address` VARCHAR(45) NULL,
    `user_agent` TEXT NULL,
    `visited_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`campaign_id`) REFERENCES `brand_whitelabel_promo_campaigns` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs traffic from brand whitelabel campaigns.';

--
-- Table: brand_data_subscriptions
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages brand subscriptions for data and analytics services.';

--
-- Table: ad_placements
--
CREATE TABLE `ad_placements` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `dimensions` VARCHAR(50) NULL COMMENT 'e.g., 300x250, 728x90',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Defines available advertising slots on the platform.';

--
-- Table: ad_campaigns
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages advertising campaigns run by brands.';

--
-- Table: ad_creatives
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stores the creative assets for an ad campaign.';

--
-- Table: ad_impressions
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs ad impression events.';

--
-- Table: ad_clicks
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs ad click events.';


-- =============================================
-- Section: Scheduled Changes & Auditing
-- Purpose: Manages workflows for price and tax changes that require approval and scheduling.
-- =============================================

--
-- Table: product_price_change_requests
--
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
  `effective_date` DATETIME NOT NULL COMMENT 'The date and time the new prices will take effect.',
  `status` ENUM('PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'SCHEDULED', 'APPLIED', 'CANCELLED') NOT NULL DEFAULT 'PENDING_APPROVAL',
  `update_suggestion_details` JSON NULL COMMENT 'Audit log of how new prices were calculated.',
  `rejection_reason` TEXT NULL,
  `approved_by_user_id` BIGINT UNSIGNED NULL,
  `approved_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`seller_product_unit_id`) REFERENCES `seller_product_units` (`id`) ON DELETE CASCADE,
  FOREIGN KEY (`requested_by_user_id`) REFERENCES `users` (`id`),
  FOREIGN KEY (`approved_by_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Workflow for approving and scheduling product price changes.';

--
-- Table: price_change_notifications
--
CREATE TABLE `price_change_notifications` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `price_change_request_id` BIGINT UNSIGNED NOT NULL,
    `target_type` ENUM('SELLER', 'CUSTOMER_SUBSCRIPTION') NOT NULL,
    `seller_id` BIGINT UNSIGNED NULL,
    `subscription_id` BIGINT UNSIGNED NULL,
    `notification_id` BIGINT UNSIGNED NOT NULL COMMENT 'Link to the master notifications table.',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`price_change_request_id`) REFERENCES `product_price_change_requests` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`subscription_id`) REFERENCES `subscriptions` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`notification_id`) REFERENCES `notifications` (`id`) ON DELETE CASCADE,
    CONSTRAINT `chk_notification_target` CHECK (`seller_id` IS NOT NULL OR `subscription_id` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs notifications sent regarding price changes.';

--
-- Table: product_tax_change_requests
--
CREATE TABLE `product_tax_change_requests` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `requested_by_user_id` BIGINT UNSIGNED NOT NULL,
  `old_gst_percentage` DECIMAL(5, 2) NOT NULL,
  `new_gst_percentage` DECIMAL(5, 2) NOT NULL,
  `old_cess_percentage` DECIMAL(5, 2) NOT NULL,
  `new_cess_percentage` DECIMAL(5, 2) NOT NULL,
  `effective_date` DATETIME NOT NULL COMMENT 'The date and time the new tax rates will take effect.',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Workflow for approving and scheduling product tax changes.';

--
-- Table: tax_change_notifications
--
CREATE TABLE `tax_change_notifications` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `tax_change_request_id` BIGINT UNSIGNED NOT NULL,
    `seller_id` BIGINT UNSIGNED NOT NULL,
    `notification_id` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`tax_change_request_id`) REFERENCES `product_tax_change_requests` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`seller_id`) REFERENCES `sellers` (`id`) ON DELETE CASCADE,
    FOREIGN KEY (`notification_id`) REFERENCES `notifications` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs notifications sent regarding tax changes.';

-- =============================================
-- Section: GST Reporting & Filing
-- Purpose: Manages the generation of GST compliance reports.
-- =============================================

--
-- Table: gst_report_types
--
CREATE TABLE `gst_report_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'e.g., GSTR-1, GSTR-3B',
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for different types of GST reports.';

--
-- Table: gst_report_generations
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs the generation of GST reports.';

-- =============================================
-- Section: Financial Reporting & Analysis
-- Purpose: Manages the generation of financial statements.
-- =============================================

--
-- Table: financial_report_types
--
CREATE TABLE `financial_report_types` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'e.g., Balance Sheet, Profit & Loss Statement',
  `description` TEXT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Reference table for different types of financial reports.';

--
-- Table: financial_report_generations
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs the generation of financial reports.';

-- =============================================
-- Section: Data Onboarding
-- Purpose: Manages the import of data from external systems.
-- =============================================

--
-- Table: customer_import_jobs
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Manages jobs for importing customer data in bulk.';

--
-- Table: customer_import_staging
--
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Staging area for validating imported customer data.';


-- =============================================
-- Section: Initial Data Population
-- Purpose: Inserts essential seed data required for the platform to operate.
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
('Brand Billing Manager', 'Can view and manage the brand's subscription and invoices from the platform.'),
('Brand Product Manager', 'Can manage the brand's product listings and details across the platform.'),
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
