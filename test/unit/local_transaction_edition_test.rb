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

  def create_authority(snac = "00BC")
    @authority ||= lgsl.authorities.create(snac: snac)
  end
  alias_method :authority, :create_authority

  def basic_new_local_transaction
    LocalTransactionEdition.new(lgsl_code: "1", title: "Transaction", slug: "slug", panopticon_id: 1243)
  end
  
  test "looks up the LGSL before validating a new record" do
    LocalTransactionsSource.expects(:find_current_lgsl).with("1").returns(lgsl)
    lt = basic_new_local_transaction
    assert lt.valid?
  end

  test "doesn't bother looking up the LGSL before validating an existing record" do
    LocalTransactionsSource.expects(:find_current_lgsl).never

    lt = basic_new_local_transaction
    lt.save(validate: false)
    assert lt.valid?
  end

  test "can verify whether an authority provides the transaction service, given its SNAC" do
    lt = basic_new_local_transaction
    lt.stubs(:lgsl).returns(lgsl)
    create_authority("45UB")

    assert lt.verify_snac("45UB")
  end

  test "can verify that an authority does not provide the transaction service" do
    lt = basic_new_local_transaction
    lt.stubs(:lgsl).returns(lgsl)
    create_authority("45UB")

    assert !lt.verify_snac("00BC")
  end
  
end
