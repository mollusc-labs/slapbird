-- 4 up
CREATE TABLE applications (
  application_id UUID NOT NULL DEFAULT gen_random_uuid(),
  user_pricing_plan_id UUID NOT NULL,
  user_id UUID NOT NULL,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  description VARCHAR(400) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT pkey_applications PRIMARY KEY (application_id),
  CONSTRAINT fk_user_user_id
    FOREIGN KEY(user_id) REFERENCES users(user_id),
  CONSTRAINT fk_user_pricing_plan_pricing_plan_id 
    FOREIGN KEY(user_pricing_plan_id) REFERENCES user_pricing_plans(user_pricing_plan_id)
);
-- 4 down
DROP TABLE applications;
