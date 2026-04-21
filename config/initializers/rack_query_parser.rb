# Increase params_limit from default of 4096 due to large simple smart answers exceeding this
# Leave params_depth_limit as default 32
Rack::Utils.default_query_parser = Rack::QueryParser.make_default(32, params_limit: 10_000)
