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
end
