Dir[Rails.root.join("lib", "enhancements", "*.rb")].each do |path|
  name = File.basename(path, ".rb")
  require "enhancements/#{name}"
end
