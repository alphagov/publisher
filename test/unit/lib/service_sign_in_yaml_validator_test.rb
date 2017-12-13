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

  def invalid_file_type
    "test/fixtures/service_sign_in/invalid.txt"
  end

  def content
    @file ||= YAML.load_file(valid_yaml_file)
  end

  def required_top_level_fields
    ServiceSignInYamlValidator::REQUIRED_TOP_LEVEL_FIELDS
  end

  def missing_top_level_fields
    "test/fixtures/service_sign_in/missing_top_level_fields.yaml"
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

    context "when a file is provided that is not YAML" do
      should "log an 'Invalid file type' error" do
        validator = service_sign_in_yaml_validator(invalid_file_type)
        assert_includes validator.validate, "Invalid file type"
      end
    end

    context "when a required top level field is missing in the YAML file" do
      should "log a 'Missing field: field_name' error" do
        validator = service_sign_in_yaml_validator(missing_top_level_fields)
        required_top_level_fields.each do |field|
          assert_includes validator.validate, "Missing field: #{field}"
        end
      end
    end
  end
end
