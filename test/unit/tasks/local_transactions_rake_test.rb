require 'test_helper'
require 'rake'

class LocalTransactionsRakeTest < ActiveSupport::TestCase

  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require("lib/tasks/local_transactions", [Rails.root.to_s], [])
    Rake::Task.define_task(:environment)
  end

  context "local_transactions:fetch" do
    setup do
      @task_name = "local_transactions:fetch"

      LocalServiceImporter.stubs(:update)
      LocalInteractionImporter.stubs(:update)
      LocalContactImporter.stubs(:update)
    end

    should "call LocalServiceImporter.update" do
      LocalServiceImporter.expects(:update)
      @rake[@task_name].invoke
    end

    should "call LocalInteractionImporter.update" do
      LocalInteractionImporter.expects(:update)
      @rake[@task_name].invoke
    end

    should "call LocalContactImporter.update" do
      LocalContactImporter.expects(:update)
      @rake[@task_name].invoke
    end
  end

  context "local_transactions:update_contacts" do
    should "call LocalContactImporter.update" do
      LocalContactImporter.expects(:update)
      @rake['local_transactions:update_contacts'].invoke
    end
  end

  context "local_transactions:update_interactions" do
    should "call LocalInteractionImporter.update" do
      LocalInteractionImporter.expects(:update)
      @rake['local_transactions:update_interactions'].invoke
    end
  end

  context "local_transactions:update_services" do
    should "call LocalServiceImporter.update" do
      LocalServiceImporter.expects(:update)
      @rake['local_transactions:update_services'].invoke
    end
  end
end
