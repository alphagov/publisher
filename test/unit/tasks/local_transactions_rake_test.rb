require_relative '../../test_helper'
require 'rake'

class LocalTransactionsRakeTest < ActiveSupport::TestCase

  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require("lib/tasks/local_transactions", [Rails.root.to_s], [])
    Rake::Task.define_task(:environment)
  end

  context "local_transactions:update_services" do
    should "call LocalServiceImporter.update" do
      LocalServiceImporter.expects(:update)
      @rake['local_transactions:update_services'].invoke
    end
  end
end
