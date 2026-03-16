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

-- ... (and so on for all tables)

SET foreign_key_checks = 1;
