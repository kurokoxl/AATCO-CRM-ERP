-- Fix for "base_registry_signaling already exists" error
-- This script drops the conflicting sequence that was imported from the old database
-- Run this after restoring a database to Railway

\c railway

-- Drop the sequence if it exists
DROP SEQUENCE IF EXISTS base_registry_signaling CASCADE;

-- Verify it's gone
SELECT 'base_registry_signaling sequence has been dropped successfully' AS status;
