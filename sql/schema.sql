-- SQL Lab Deliverable: Schema Script
-- Run on MySQL 8.0+

DROP DATABASE IF EXISTS greenify_db;
CREATE DATABASE greenify_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE greenify_db;

SOURCE ../backend/src/main/resources/db/migration/V1__init_schema.sql;
