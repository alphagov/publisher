class ServiceSignInYamlValidator
  attr_reader :yaml_file

  REQUIRED_TOP_LEVEL_FIELDS =
    %w(change_note choose_sign_in locale start_page_slug update_type).freeze

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
end
