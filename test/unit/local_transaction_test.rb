require 'test_helper'

class LocalTransactionTest < ActiveSupport::TestCase
  def lgsl
    @lgsl ||= LocalTransactionsSource::Lgsl.create(code: "1")
  end

  def create_authority(snac = "00BC")
    @authority ||= lgsl.authorities.create(snac: snac)
  end
  alias_method :authority, :create_authority

  test "looks up the LGSL before validating a new record" do
    without_panopticon_validation do
      LocalTransactionsSource.expects(:find_current_lgsl).with("1").returns(lgsl)

      lt = LocalTransaction.new(lgsl_code: "1", name: "Transaction", slug: "slug")
      assert lt.valid?
    end
  end

  test "doesn't bother looking up the LGSL before validating an existing record" do
    without_panopticon_validation do
      LocalTransactionsSource.expects(:find_current_lgsl).never

      lt = LocalTransaction.new(lgsl_code: "1", name: "Transaction", slug: "slug")
      lt.save(validate: false)
      assert lt.valid?
    end
  end

  test "can verify whether an authority provides the transaction service, given its SNAC" do
    lt = LocalTransaction.new(lgsl_code: "1", name: "Transaction", slug: "slug")
    lt.stubs(:lgsl).returns(lgsl)
    create_authority("45UB")

    assert lt.verify_snac("45UB")
  end

  test "can verify that an authority does not provide the transaction service" do
    lt = LocalTransaction.new(lgsl_code: "1", name: "Transaction", slug: "slug")
    lt.stubs(:lgsl).returns(lgsl)
    create_authority("45UB")

    assert !lt.verify_snac("00BC")
  end
end
