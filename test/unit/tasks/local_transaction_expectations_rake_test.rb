require_relative '../../test_helper'
require 'rake'

class LocalTransactionExpectationsRakeTest < ActiveSupport::TestCase

  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require("lib/tasks/local_transaction_expectations", [Rails.root.to_s], [])
    Rake::Task.define_task(:environment)
  end

  context "local_transaction_expectations:add_wales_only_expectation" do
    should "create the 'Available in Wales only' expectation" do
      assert_equal 0, Expectation.where(:text => 'Available in Wales only').count
      @rake["local_transaction_expectations:add_wales_only_expectation"].invoke
      assert_equal 1, Expectation.where(:text => 'Available in Wales only').count
    end
    should "not create another expectation if one exists" do
      FactoryGirl.create(:expectation, :text => 'Available in Wales only')
      assert_equal 1, Expectation.where(:text => 'Available in Wales only').count
      @rake["local_transaction_expectations:add_wales_only_expectation"].invoke
      assert_equal 1, Expectation.where(:text => 'Available in Wales only').count
    end
  end

  context "local_transaction_expectations:update_local_transaction_regional_expectations" do
    setup do
      LocalTransactionEdition.any_instance.stubs(:service).returns(true)
    end
    should "replace 'Available in England only' expectations on local transactions with 'Available in England and Wales only'" do
      england_only = FactoryGirl.create(:expectation, :text => 'Available in England only')
      england_and_wales_only = FactoryGirl.create(:expectation, :text => 'Available in England and Wales only')
      local_transaction = FactoryGirl.create(:local_transaction_edition, :state => 'draft')
      local_transaction.expectation_ids << england_only._id.to_s
      local_transaction.save

      assert local_transaction.expectations.include?(england_only)

      @rake["local_transaction_expectations:update_local_transaction_regional_expectations"].invoke
     
      local_transaction.reload

      assert local_transaction.expectations.include?(england_and_wales_only)
      refute local_transaction.expectations.include?(england_only)
    end
  end

end
