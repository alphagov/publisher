require 'test_helper'

class LocalTransactionSourceTest < ActiveSupport::TestCase
  test "retrieving the most recent LocalTransactionsSource" do
    previous = LocalTransactionsSource.create(created_at: Time.now - 1.day)
    current = LocalTransactionsSource.create

    assert_equal current, LocalTransactionsSource.current
  end

  test "finding an LGSL in the current LocalTransactionsSource" do
    previous = LocalTransactionsSource.create(created_at: Time.now - 1.day)
    current = LocalTransactionsSource.create

    prev_lgsl = previous.lgsls.create(code: "1")
    current_lgsl = current.lgsls.create(code: "1")

    assert_equal current_lgsl, LocalTransactionsSource.find_current_lgsl("1")
  end
end
