require 'test_helper'
require 'capybara/rails'

SimpleCov.at_exit do
  result = SimpleCov.result
  result.format!
  coverage = (result.covered_percent * 100).to_i.to_f / 100
  puts "C0 code coverage: #{coverage}%"
  @exit_status = 100 if coverage != 62.96
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
