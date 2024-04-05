-- 5 up
CREATE TABLE http_transactions (
  http_transaction_id UUID NOT NULL DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL,
  type VARCHAR(50) NOT NULL,
  method VARCHAR(50),
  end_point TEXT,
  start_time DECIMAL(20, 2),
  end_time DECIMAL(20, 2),
  total_time DECIMAL(20, 2),
  response_code INTEGER,
  response_size BIGINT,
  response_headers TEXT,
  request_id TEXT,
  request_size BIGINT,
  request_headers TEXT,
  handler VARCHAR(200),
  error TEXT,
  requestor VARCHAR(100) NOT NULL,
  stack TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 5 down
DROP TABLE http_transactions;