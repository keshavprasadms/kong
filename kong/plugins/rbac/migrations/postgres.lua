return {
  {
    name = "2015-08-25-841841_init_rbac",
    up = [[
      CREATE TABLE IF NOT EXISTS rbacs(
        id uuid,
        consumer_id uuid REFERENCES consumers (id) ON DELETE CASCADE,
        "roles" text,
        "checks" text,
        "checkin" text,
        "payloadfields" text,
        created_at timestamp without time zone default (CURRENT_TIMESTAMP(0) at time zone 'utc'),
        PRIMARY KEY (id)
      );

      DO $$
      BEGIN
        IF (SELECT to_regclass('rbacs_roles')) IS NULL THEN
          CREATE INDEX rbacs_roles ON rbacs("roles");
        END IF;
        IF (SELECT to_regclass('rbacs_checks')) IS NULL THEN
          CREATE INDEX rbacs_checks ON rbacs("checks");
        END IF;
        IF (SELECT to_regclass('rbacs_checkin')) IS NULL THEN
          CREATE INDEX rbacs_checkin ON rbacs("checkin");
        END IF;
        IF (SELECT to_regclass('rbacs_payloadfields')) IS NULL THEN
          CREATE INDEX rbacs_payloadfields ON rbacs("payloadfields");
        END IF;
        IF (SELECT to_regclass('rbacs_consumer_id')) IS NULL THEN
          CREATE INDEX rbacs_consumer_id ON rbacs(consumer_id);
        END IF;
      END$$;
    ]],
    down = [[
      DROP TABLE rbacs;
    ]]
  }
}
