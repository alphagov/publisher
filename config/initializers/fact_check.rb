require 'yaml'
require 'mail_fetcher_config'

config_file_path = File.join(Rails.root, "config", "fact_check.yml")
fact_check_config = YAML.load_file(config_file_path)

fetcher_config = fact_check_config.fetch("fetcher", {})
Publisher::Application.mail_fetcher_config = MailFetcherConfig.new(
  fetcher_config.symbolize_keys
)
