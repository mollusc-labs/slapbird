-- 11 up
ALTER TABLE http_transactions ADD COLUMN num_queries INTEGER DEFAULT 0;
ALTER TABLE http_transactions ADD COLUMN queries JSONB;
-- 11 down
ALTER TABLE http_transactions DROP COLUMN num_queries;
ALTER TABLE http_transactions DROP COLUMN queries;
