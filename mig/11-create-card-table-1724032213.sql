-- 11 up
CREATE TABLE cards (
       card_id UUID NOT NULL DEFAULT gen_random_uuid(),
       ending_in VARCHAR(4) NOT NULL,
       type VARCHAR(50) NOT NULL,
       user_id UUID NOT NULL,
       user_pricing_plan_id UUID NOT NULL,
       created_at TIMESTAMP DEFAULT NOW(),
       updated_at TIMESTAMP DEFAULT NOW()
);
-- 11 down
DROP TABLE cards;
