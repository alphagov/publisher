require 'test_helper'

class ServiceSignInYamlValidatorTest < ActiveSupport::TestCase
  def service_sign_in_yaml_validator(file)
    ServiceSignInYamlValidator.new(file)
  end

  def valid_yaml_file
    "lib/service_sign_in/example.yaml"
  end

  def invalid_file_path
    "invalid/file/path.yaml"
  end

  def content
    @file ||= YAML.load_file(valid_yaml_file)
  end

  context "#validate" do
    context "when a YAML file is valid" do
      should "return the YAML file as a hash" do
        validator = service_sign_in_yaml_validator(valid_yaml_file)
        assert_equal content, validator.validate
      end
    end

    context "when an invalid file path is provided" do
      should "log an 'Invalid file path' error" do
        validator = service_sign_in_yaml_validator(invalid_file_path)
        assert_includes validator.validate, "Invalid file path: #{invalid_file_path}"
      end
    end
  end
end
