-- 12 up
CREATE TABLE addons (
    addon_id UUID NOT NULL DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    module TEXT NOT NULL,
    description TEXT NOT NULL,
    price BIGINT NOT NULL,
    price_pretty TEXT NOT NULL,
    is_free BOOLEAN NOT NULL DEFAULT FALSE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT pkey_addons PRIMARY KEY (addon_id)
);
CREATE TABLE user_pricing_plan_addons (
    user_pricing_plan_addon_id UUID NOT NULL DEFAULT gen_random_uuid(),
    addon_id UUID NOT NULL,
    user_pricing_plan_id UUID NOT NULL,
    joined_at TIMESTAMP DEFAULT NOW(),
    stripe_id TEXT,
    CONSTRAINT pkey_user_pricing_addon PRIMARY KEY (user_pricing_plan_addon_id),
    CONSTRAINT fk_user_pricing_plan_addon_addon_id
      FOREIGN KEY(addon_id) REFERENCES addons(addon_id),
    CONSTRAINT fk_user_pricing_plan_addon_user_pricing_plan_id
      FOREIGN KEY(user_pricing_plan_id) REFERENCES user_pricing_plans(user_pricing_plan_id)
);
-- 12 down
DROP TABLE addons;
DROP TABLE user_pricing_plan_addons;
