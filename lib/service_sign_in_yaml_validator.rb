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
  end

  def load_yaml_file
    begin
      @yaml_file = YAML.load_file(@file_name)
    rescue SystemCallError
      @errors << "Invalid file path: #{@file_name}"
      return false
    end
  end
end
