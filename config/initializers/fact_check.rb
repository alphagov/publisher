require 'yaml'
require 'mail_fetcher_config'
require 'fact_check_config'

config_file_path = Rails.root.join("config", "fact_check.yml")
config = YAML.load_file(config_file_path)

Publisher::Application.fact_check_config = FactCheckConfig.new(
  config.fetch("address_format")
)

fetcher_config = config.fetch("fetcher", {})
Publisher::Application.mail_fetcher_config = MailFetcherConfig.new(
  fetcher_config.symbolize_keys
)
