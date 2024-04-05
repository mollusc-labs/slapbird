-- 6 up
CREATE TABLE api_keys (
  api_key_id UUID NOT NULL DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL,
  application_api_key VARCHAR(126) NOT NULL,
  name VARCHAR(100) NOT NULL,
  user_id UUID NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 6 down
DROP TABLE api_keys;