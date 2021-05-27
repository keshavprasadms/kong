return {
  {
    name = "2015-08-25-841841_init_rbac",
    up = [[
      CREATE TABLE IF NOT EXISTS rbacs(
        id uuid,
        consumer_id uuid,
        group text,
        created_at timestamp,
        PRIMARY KEY (id)
      );

      CREATE INDEX IF NOT EXISTS ON rbacs(group);
      CREATE INDEX IF NOT EXISTS rbacs_consumer_id ON rbacs(consumer_id);
    ]],
    down = [[
      DROP TABLE rbacs;
    ]]
  }
}
