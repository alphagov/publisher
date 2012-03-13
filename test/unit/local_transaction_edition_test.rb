require 'test_helper'
require_relative 'helpers/local_services_helper'

class LocalTransactionEditionTest < ActiveSupport::TestCase
  include LocalServicesHelper
  
  def local_transaction_edition
    make_service(149, %w{county unitary})
    lt = LocalTransactionEdition.new(:name => "Transaction", :slug=>"transaction", :lgsl_code => "149")
    edition = lt.editions.first
    edition
  end

  test "editions, return their title for use in the publications admin-interface lists" do
    assert_equal "Transaction", local_transaction_edition.admin_list_title
  end

  test "a new edition of a local transaction creates a diff between the introduction when published" do
    without_metadata_denormalisation(LocalTransaction) do
      local_transaction = local_transaction_edition.container
      local_transaction.save!

      user = User.create :name => 'Thomas'

      edition_one = local_transaction.editions.first
      edition_one.introduction = 'Test'
      edition_one.save!

      edition_one.state = :ready
      user.publish edition_one, comment: "First edition"

      edition_two = edition_one.build_clone
      edition_two.save!
      edition_two.introduction = "Testing"
      edition_two.state = :ready
      user.publish edition_two, comment: "Second edition"

      publish_action = edition_two.actions.where(request_type: "publish").last

      assert_equal "{\"Test\" >> \"Testing\"}", publish_action.diff
    end
  end

end
