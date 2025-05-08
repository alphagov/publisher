require "yaml"

require "fact_check_config"

config_file_path = Rails.root.join("config/fact_check.yml")

config = YAML.safe_load(
  ERB.new(File.read(config_file_path)).result,
)

Publisher::Application.fact_check_config = FactCheckConfig.new(
  config.fetch("reply_to_address"),
  config.fetch("subject_prefix"),
  config.fetch("reply_to_id"),
)
