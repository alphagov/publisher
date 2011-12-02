require 'test_helper'
require 'capybara/rails'

SimpleCov.at_exit do
  coverage_file = File.absolute_path(File.join(Rails.root, 'coverage.txt'))
  expected_coverage = File.read(coverage_file).to_f
  result = SimpleCov.result
  result.format!
  coverage = (result.covered_percent * 100).to_i.to_f / 100
  puts "C0 code coverage: #{coverage}%"
  if coverage != expected_coverage
    puts "Expected integration tests coverage of #{expected_coverage}%"
    if coverage > expected_coverage
      puts "You can increase the coverage in #{coverage_file}"
    else
      puts "Coverage went down. How sad."
    end
  end
end

class ActionDispatch::IntegrationTest
  include Capybara::DSL

  teardown do
    DatabaseCleaner.clean
  end
end

class MockImminence

  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'] == '/places/registry-offices.json'
      return [ 200, {}, "[]" ]
    else
      @app.call(env)
    end
  end
end

Capybara.default_driver = :webkit
Capybara.app = Rack::Builder.new do
  map "/" do
    run Capybara.app
  end
end
