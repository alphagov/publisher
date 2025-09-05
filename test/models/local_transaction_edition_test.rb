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
    bins_transaction = FactoryBot.build(:local_transaction_edition,
                                        lgsl_code: BINS,
                                        title: "Transaction",
                                        slug: "slug",
                                        panopticon_id: @artefact.id)
    assert_equal "transaction", bins_transaction.search_format
  end

  test "should validate that a LocalService exists for that lgsl_code" do
    service = LocalService.create!(lgsl_code: BINS, providing_tier: %w[county unitary])
    local_transaction = FactoryBot.build(:local_transaction_edition, lgsl_code: NONEXISTENT, lgil_code: 1, title: "Foo", slug: "foo", panopticon_id: @artefact.id)

    assert_not local_transaction.valid?

    local_transaction = FactoryBot.create(:local_transaction_edition, lgsl_code: service.lgsl_code, lgil_code: 1, title: "Bar", slug: "bar", panopticon_id: @artefact.id)

    assert local_transaction.valid?
  end

  should "copy the devolved administration availability fields when cloning an edition" do
    edition = FactoryBot.build(
      :local_transaction_edition,
      panopticon_id: @artefact.id,
      state: "published",
      scotland_availability: FactoryBot.build(:scotland_availability, alternative_url: "https://test.com", authority_type: "local_authority_service"),
      wales_availability: FactoryBot.build(:wales_availability, alternative_url: "https://test.com", authority_type: "devolved_administration_service"),
      northern_ireland_availability: FactoryBot.build(:northern_ireland_availability, alternative_url: "https://test.com", authority_type: "unavailable"),
    )

    edition.save!(validate: false)

    cloned_edition = edition.build_clone
    cloned_edition.save!(validate: false)

    assert_equal edition.scotland_availability.type, cloned_edition.scotland_availability.type
    assert_equal edition.scotland_availability.alternative_url, cloned_edition.scotland_availability.alternative_url
    assert_equal edition.scotland_availability.authority_type, cloned_edition.scotland_availability.authority_type
    assert_equal edition.wales_availability.type, cloned_edition.wales_availability.type
    assert_equal edition.wales_availability.alternative_url, cloned_edition.wales_availability.alternative_url
    assert_equal edition.wales_availability.authority_type, cloned_edition.wales_availability.authority_type
    assert_equal edition.northern_ireland_availability.type, cloned_edition.northern_ireland_availability.type
    assert_equal edition.northern_ireland_availability.authority_type, cloned_edition.northern_ireland_availability.authority_type
  end

  should "not copy the devolved administration availability fields when new edition is not a LocalTransactionEdition" do
    edition = FactoryBot.build(
      :local_transaction_edition,
      panopticon_id: @artefact.id,
      state: "published",
      scotland_availability: FactoryBot.build(:scotland_availability, alternative_url: "https://test.com", authority_type: "devolved_administration_service"),
    )

    edition.save!(validate: false)

    cloned_edition = edition.build_clone(TransactionEdition)
    cloned_edition.save!(validate: false)

    assert cloned_edition.editionable.is_a?(TransactionEdition)
    assert_equal edition.scotland_availability.authority_type, "devolved_administration_service"
    assert_not cloned_edition.editionable.respond_to?(:scotland_availability)
  end

  should "not copy the devolved administration availability mongo_id fields when cloning an edition" do
    edition = FactoryBot.build(
      :local_transaction_edition,
      panopticon_id: @artefact.id,
      state: "published",
      scotland_availability: FactoryBot.build(:scotland_availability, alternative_url: "https://test.com", mongo_id: "OldMongoId1"),
      wales_availability: FactoryBot.build(:wales_availability, alternative_url: "https://test.com", mongo_id: "OldMongoId2"),
      northern_ireland_availability: FactoryBot.build(:northern_ireland_availability, alternative_url: "https://test.com", mongo_id: "OldMongoId3"),
    )

    edition.save!(validate: false)
    cloned_edition = edition.build_clone
    cloned_edition.save!(validate: false)

    assert_nil cloned_edition.scotland_availability.mongo_id
    assert_nil cloned_edition.wales_availability.mongo_id
    assert_nil cloned_edition.northern_ireland_availability.mongo_id
  end
end
