CREATE DATABASE IF NOT EXISTS greenify_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE greenify_db;

SOURCE database/schema.sql;
SOURCE database/seed.sql;