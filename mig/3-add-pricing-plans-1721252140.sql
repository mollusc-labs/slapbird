-- 3 up

INSERT INTO pricing_plans (name, description, price, price_pretty, is_free, max_users, max_requests, max_applications, max_api_keys)
VALUES (
  'FREE',
  '
  <ul class="subtitle">
    <li>
      5 users, 1 application, 1 api key
    </li>
    <li>
      <strong>100k</strong> monthly transactions
    </li>
    <li>
      Forum access
    </li>
  </ul>
  ',
  0,
  '0.00',
  TRUE,
  5,
  100000,
  1,
  1
);

INSERT INTO pricing_plans (name, description, price, price_pretty, is_free, max_users, max_requests, max_applications, max_api_keys)
VALUES (
  'Small Team',
  '
  <ul class="subtitle">
    <li>
      15 users, unlimited applications, 5 api keys per application
    </li>
    <li>
      <strong>500k</strong> monthly transactions
    </li>
    <li>
      Forum access
    </li>
  </ul>
  ',
  2500000,
  '25.00',
  FALSE,
  15,
  500000,
  -1,
  5
);

INSERT INTO pricing_plans (name, description, price, price_pretty, is_free, max_users, max_requests, max_applications, max_api_keys)
VALUES (
  'Medium Team',
  '
  <ul class="subtitle">
    <li>
      Unlimited users, applications, and api keys
    </li>
    <li>
      <strong>1.5M</strong> monthly transactions
    </li>
    <li>
      Priority support
    </li>
  </ul>
  ',
  5000000,
  '50.00',
  FALSE,
  -1,
  1500000,
  -1,
  -1
);

INSERT INTO pricing_plans (name, description, price, price_pretty, is_free, max_users, max_requests, max_applications, max_api_keys)
VALUES (
  'Large Team',
  '
  <ul class="subtitle">
    <li>
      Unlimited users, api keys, and applications
    </li>
    <li>
      <strong>3M</strong> monthly transactions
    </li>
    <li>
      Priority support
    </li>
  </ul>
  ',
  9900000,
  '99.00',
  FALSE,
  -1,
  3000000,
  -1,
  -1
);

-- 3 down
