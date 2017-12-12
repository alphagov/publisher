require 'yaml'

namespace :service_sign_in do
  desc "publish service_sign_in format"
  task :publish, [:yaml_file] => :environment do |_, args|
    USAGE_MESSAGE = "> usage: rake service_sign_in:publish[example.yaml]\n".freeze +
      "> service_sign_in YAML files live here: lib/service_sign_in"
    VALID_FILE_MESSAGE = "> You have not provided a valid file\n".freeze

    abort USAGE_MESSAGE unless args[:yaml_file]

    begin
      file = YAML.load_file("lib/service_sign_in/#{args[:yaml_file]}")
    rescue SystemCallError
      abort VALID_FILE_MESSAGE + USAGE_MESSAGE
    end

    content = Formats::ServiceSignInPresenter.new(file)
    ServiceSignInPublishService.call(content)

    puts "> #{args[:yaml_file]} has been published"
  end
end
