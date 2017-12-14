class ServiceSignInYamlValidator
  attr_reader :yaml_file

  REQUIRED_TOP_LEVEL_FIELDS =
    %w(change_note choose_sign_in locale start_page_slug update_type).freeze
  REQUIRED_CHOOSE_SIGN_IN_FIELDS = %w(options slug title).freeze
  REQUIRED_CREATE_NEW_ACCOUNT_FIELDS = %w(body slug title).freeze

  def initialize(file_name)
    @file_name = file_name
    @errors = []
  end

  def validate
    valid? ? @yaml_file : @errors
  end

private

  def valid?
    load_yaml_file
    return unless @yaml_file.present?
    check_for_top_level_required_fields
    check_for_choose_sign_in_required_fields if choose_sign_in.present?
    check_for_create_new_account_required_fields if create_new_account.present?
    @errors.empty?
  end

  def load_yaml_file
    begin
      @yaml_file = YAML.load_file(@file_name)
      unless @yaml_file.present?
        @errors << "Invalid file type"
      end
    rescue SystemCallError
      @errors << "Invalid file path: #{@file_name}"
    end
  end

  def check_for_top_level_required_fields
    REQUIRED_TOP_LEVEL_FIELDS.each do |field|
      @errors << "Missing field: #{field}" unless @yaml_file.has_key?(field)
    end
  end

  def check_for_choose_sign_in_required_fields
    error_message = "Missing choose_sign_in field: "
    unless choose_sign_in.is_a?(Hash)
      @errors << error_message + REQUIRED_CHOOSE_SIGN_IN_FIELDS.join(", ")
      return
    end

    check_choose_sign_in_top_level_fields(error_message)
    return unless choose_sign_in["options"].present?
    check_choose_sign_in_options_fields(error_message)
  end

  def check_choose_sign_in_top_level_fields(error_message)
    REQUIRED_CHOOSE_SIGN_IN_FIELDS.each do |field|
      unless choose_sign_in.has_key?(field)
        @errors << error_message + field
      end
    end
  end

  def check_choose_sign_in_options_fields(error_message)
    error_message += "option > "
    unless choose_sign_in["options"].is_a?(Array)
      @errors << error_message + "text, slug or url"
      return
    end

    choose_sign_in["options"].each do |option|
      @errors << error_message + "text" unless option.has_key?("text")
      unless option.has_key?("slug") || option.has_key?("url")
        @errors << error_message + "slug or url"
      end
    end
  end

  def check_for_create_new_account_required_fields
    REQUIRED_CREATE_NEW_ACCOUNT_FIELDS.each do |field|
      unless create_new_account.has_key?(field)
        @errors << "Missing create_new_account field: #{field}"
      end
    end
  end

  def choose_sign_in
    @yaml_file["choose_sign_in"]
  end

  def create_new_account
    @yaml_file["create_new_account"]
  end
end
