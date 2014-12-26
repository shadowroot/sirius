require 'pliny/config_helpers'

# Access all config keys like the following, #
#     Config.database_url
#
# Each accessor corresponds directly to an ENV key, which has the same name
# except upcased, i.e. `DATABASE_URL`.
#
# Note that *all* keys will come out as strings even if the override was a
# different type. Make sure to typecast any values that need to be something
# else (i.e. `.to_i`).
module Config
  extend Pliny::CastingConfigHelpers

  # Mandatory -- exception is raised for these variables when missing.
  mandatory :database_url, string
  mandatory :kosapi_oauth_client_id, string
  mandatory :kosapi_oauth_client_secret, string
  mandatory :domain, string

  # Optional -- value is returned or `nil` if it wasn't present.
  optional :console_banner, string
  optional :placeholder, string
  optional :versioning_default, string
  optional :versioning_app_name, string
  optional :sentry_dsn, string
  optional :sync_schedule, string

  # Override -- value is returned or the set default. Remember to typecast.
  override :db_pool, 5, int
  override :port, 5000, int
  override :rack_env, 'development', string
  override :raise_errors, false, bool
  override :root, File.expand_path('../../', __FILE__), string
  override :timeout, 45, int
  override :force_ssl, true, bool
  override :versioning, false, bool
  override :tz, 'Europe/Prague', string
  override :puma_max_threads, 16, int
  override :puma_min_threads, 1, int
  override :puma_workers, 3
end
