require_relative '../../test_helper'
require 'rake'

class LocalTransactionsRakeTest < ActiveSupport::TestCase

  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require("lib/tasks/local_transactions", [Rails.root.to_s], [])
    Rake::Task.define_task(:environment)
  end

  context "local_transactions:fetch" do
    should "call LocalAuthorityDataImporter.update_all" do
      LocalAuthorityDataImporter.expects(:update_all)
      @rake["local_transactions:fetch"].invoke
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
