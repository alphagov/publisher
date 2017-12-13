class ServiceSignInYamlValidator
  attr_reader :yaml_file

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
end
