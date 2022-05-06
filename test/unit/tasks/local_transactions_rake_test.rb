require "test_helper"
require "rake"

class LocalTransactionsRakeTest < ActiveSupport::TestCase
  context "local_transactions:update_services" do
    should "call LocalServiceImporter.run" do
      Rake::Task["local_transactions:update_services"].reenable

      LocalServiceImporter.expects(:run)
      Rake::Task["local_transactions:update_services"].invoke
    end
  end
end
