require 'test_helper'
require 'rake'

class LocalTransactionsRakeTest < ActiveSupport::TestCase
  context "local_transactions:update_services" do
    should "call LocalServiceImporter.update" do
      LocalServiceImporter.expects(:update)
      Rake::Task['local_transactions:update_services'].invoke
    end
  end
end
