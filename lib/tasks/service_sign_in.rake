require 'yaml'

namespace :service_sign_in do
  desc "publish service_sign_in format"
  task :publish, [:yaml_file] => :environment do |_, args|
    USAGE_MESSAGE = "> usage: rake service_sign_in:publish[example.yaml]\n".freeze
    VALID_FILE_MESSAGE = "> You have not provided a valid file\n".freeze

    abort USAGE_MESSAGE + YAML_LOCATION unless args[:yaml_file]

    validator = ServiceSignInYamlValidator.new("lib/service_sign_in/#{args[:yaml_file]}")

    begin
      file = validator.validate

      if file.is_a?(Hash)
        content = Formats::ServiceSignInPresenter.new(file)
      else
        puts "Validation errors occurred:"
        puts file
        abort
      end
    rescue SystemCallError
      abort VALID_FILE_MESSAGE + USAGE_MESSAGE
    end

    ServiceSignInPublishService.call(content)
    puts "> #{args[:yaml_file]} has been published"
  end

  desc "Validate a service_sign_in YAML file"
  task :validate, [:yaml_file] => :environment do |_, args|
    USAGE_MESSAGE = "> usage: rake service_sign_in:validate[example.yaml]\n".freeze
    abort USAGE_MESSAGE + YAML_LOCATION unless args[:yaml_file]

    validator = ServiceSignInYamlValidator.new("lib/service_sign_in/#{args[:yaml_file]}")
    file = validator.validate

    if file.is_a?(Hash)
      puts "This is a valid YAML file"
    else
      puts "Validation errors occurred:"
      puts file
    end
  end

  desc "Unpublish service_sign_in content with type 'gone'"
  task :unpublish_without_redirect, %i(content_id locale) => :environment do |_, args|
    USAGE_MESSAGE =
      "> usage: rake service_sign_in:unpublish_without_redirect[content-id-example,cy]\n".freeze

    content_id = args[:content_id]
    locale = args[:locale]
    abort USAGE_MESSAGE unless content_id && locale

    ServiceSignInUnpublishService.call(content_id, locale)
    puts "> #{content_id} has been unpublished"
  end

  desc "Unpublish service_sign_in content with type 'redirect'"
  task :unpublish_with_redirect, %i(content_id locale redirect_path) => :environment do |_, args|
    USAGE_MESSAGE =
      "> usage: rake service_sign_in:unpublish_with_redirect[content-id-example,cy,/redirect/path]\n".freeze

    content_id = args[:content_id]
    locale = args[:locale]
    redirect_path = args[:redirect_path]

    abort USAGE_MESSAGE unless content_id && locale && redirect_path

    ServiceSignInUnpublishService.call(
      content_id,
      locale,
      redirect_path: redirect_path
    )

    puts "> #{content_id} has been unpublished"
  end

  YAML_LOCATION = "> service_sign_in YAML files live here: lib/service_sign_in".freeze
end
