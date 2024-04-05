-- 1 up
CREATE TABLE users (
    user_id UUID NOT NULL DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    oauth_id TEXT NOT NULL,
    oauth_provider TEXT NOT NULL,
    stripe_id TEXT,
    role TEXT DEFAULT 'USER',
    first_login TIMESTAMP NULL,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    receives_email BOOLEAN DEFAULT true,
    CONSTRAINT pkey_users PRIMARY KEY ( user_id )
);
-- 1 down
DROP TABLE users;
