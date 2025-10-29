require_relative "lib/fact_check/version"

Gem::Specification.new do |spec|
  spec.name        = "fact_check"
  spec.version     = FactCheck::VERSION
  spec.authors     = [""]
  spec.email       = [""]
  spec.homepage    = "http://example.com"
  spec.summary     = "http://example.com/summary"
  spec.description = "http://example.com/description"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "http://example.com/repo"
  spec.metadata["changelog_uri"] = "http://example.com/changelog"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1.5.2"
end
