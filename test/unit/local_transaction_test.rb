require 'test_helper'

class LocalTransactionTest < ActiveSupport::TestCase
  test "looks up the LGSL before validating a new record" do
    lgsl = LocalTransactionsSource::Lgsl.create(code: "1")
    LocalTransactionsSource.expects(:find_current_lgsl).with("1").returns(lgsl)
    
    lt = LocalTransaction.new(lgsl_code: "1", name: "Transaction", slug: "slug")
    assert lt.valid?
  end

  test "doesn't bother looking up the LGSL before validating an existing record" do
    lgsl = LocalTransactionsSource::Lgsl.create(code: "1")

    LocalTransactionsSource.expects(:find_current_lgsl).never
    
    lt = LocalTransaction.new(lgsl_code: "1", name: "Transaction", slug: "slug")
    lt.save(validate: false)
    assert lt.valid?
  end
end
