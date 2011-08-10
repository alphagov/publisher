require 'test_helper'

class LocalTransactionEditionTest < ActiveSupport::TestCase
  def local_transaction_edition
    lgsl = LocalTransactionsSource::Lgsl.new()
    lt = LocalTransaction.new(:name => "Transaction", :slug=>"transaction", :lgsl_code => "149", :lgsl => lgsl)
    edition = lt.editions.first
    edition
  end

  test "editions, return their title + LGSL + number of providers for use in the publications admin-interface lists" do
    assert_equal "Transaction (LGSL 149) [0]", local_transaction_edition.admin_list_title
  end
end
