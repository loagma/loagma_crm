-- Update merchandise image columns to LONGTEXT to support base64 encoded images
-- Run this migration to fix "column is too long" error

ALTER TABLE transaction_crm 
MODIFY COLUMN merchandise_image_1 LONGTEXT,
MODIFY COLUMN merchandise_image_2 LONGTEXT;
