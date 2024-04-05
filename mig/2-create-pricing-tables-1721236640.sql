-- 2 up
CREATE TYPE pricing_plans_status AS ENUM ('ACTIVE', 'INACTIVE');
CREATE TABLE pricing_plans (
  pricing_plan_id UUID NOT NULL DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  price BIGINT NOT NULL,
  price_pretty TEXT NOT NULL,
  is_free BOOLEAN NOT NULL DEFAULT FALSE,
  pricing_plan_status pricing_plans_status NOT NULL DEFAULT 'ACTIVE',
  max_requests BIGINT NOT NULL,
  max_users INT NOT NULL,
  max_applications INT NOT NULL,
  max_api_keys INT NOT NULL,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT pkey_pricing_plans PRIMARY KEY (pricing_plan_id)
);

CREATE TABLE user_pricing_plans (
  user_pricing_plan_id UUID NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  pricing_plan_id UUID NOT NULL,
  is_active BOOLEAN DEFAULT false,
  joined_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT pkey_user_pricing_plan PRIMARY KEY (user_pricing_plan_id),
  CONSTRAINT fk_user_pricing_plan_user_id 
    FOREIGN KEY(user_id) REFERENCES users(user_id),
  CONSTRAINT fk_user_pricing_plan_pricing_plan_id 
    FOREIGN KEY(pricing_plan_id) REFERENCES pricing_plans(pricing_plan_id)
);

CREATE TABLE associated_user_pricing_plans (
  associated_user_pricing_plan_id UUID NOT NULL DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  user_pricing_plan_id UUID NOT NULL,
  joined_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT pkey_associated_user_pricing_plans PRIMARY KEY (associated_user_pricing_plan_id),
  CONSTRAINT fk_associated_user_pricing_plan_user_id 
    FOREIGN KEY (user_id) REFERENCES users(user_id),
  CONSTRAINT fk_associated_user_pricing_plan_user_pricing_plan_id 
    FOREIGN KEY (user_pricing_plan_id) REFERENCES user_pricing_plans(user_pricing_plan_id)
);

-- 2 down
DROP TABLE pricing_plans;
DROP TABLE user_pricing_plans;
DROP TABLE associated_user_pricing_plans;
