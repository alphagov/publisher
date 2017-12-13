class ServiceSignInYamlValidator
  def initialize(file_name)
    @file_name = file_name
  end

  def validate
    load_yaml_file
  end

private

  def load_yaml_file
    YAML.load_file(@file_name)
  end
end
