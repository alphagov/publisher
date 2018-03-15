require "test_helper"

class LocalTransactionEditionTest < ActiveSupport::TestCase
  include LocalServicesHelper
  BINS = 1
  HOUSING_BENEFIT = 2
  NONEXISTENT = 999

  def setup
    @artefact = FactoryBot.create(:artefact)
  end

  test "should be a transaction search format" do
    bins_transaction = LocalTransactionEdition.new(
      lgsl_code:     BINS,
      title:         "Transaction",
      slug:          "slug",
      panopticon_id: @artefact.id
    )
    assert_equal "transaction", bins_transaction.search_format
  end


  test "should validate on save that a LocalService exists for that lgsl_code" do
    service = LocalService.create!(lgsl_code: BINS, providing_tier: %w{county unitary})

    local_transaction = LocalTransactionEdition.new(lgsl_code: NONEXISTENT, lgil_code: 1, title: "Foo", slug: "foo", panopticon_id: @artefact.id)
    local_transaction.save
    assert !local_transaction.valid?

    local_transaction = LocalTransactionEdition.new(lgsl_code: service.lgsl_code, lgil_code: 1, title: "Bar", slug: "bar", panopticon_id: @artefact.id)
    local_transaction.save
    assert local_transaction.valid?
    assert local_transaction.persisted?
  end
end
