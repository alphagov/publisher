require 'test_helper'

class LocalTransactionGenerationTest < ActiveSupport::TestCase
  setup do
    @updated_time = Time.now
    @local_transaction = LocalTransaction.new(slug: 'test_slug', tags: 'tag, other', :lgsl => lgsl, :lgsl_code => @lgsl.code)
    @local_transaction.editions.first.attributes = {version_number: 1, title: 'Test local transaction', updated_at: @updated_time}
    @edition = @local_transaction.editions.first
  end

  def lgsl
    return @lgsl if @lgsl
    @lgsl = LocalTransactionsSource::Lgsl.new(code: "149")
    authority = LocalTransactionsSource::Authority.new(snac: "00BC", name: "Authority")
    authority.lgils << LocalTransactionsSource::Lgil.new(code: "8", url: "http://authority.gov.uk/service")
    @lgsl.authorities << authority
    @lgsl
  end

  def generated(*args)
    Api::Generator::LocalTransaction.edition_to_hash(@edition, *args)
  end

  test "generated hash has slug" do
    assert_equal "test_slug", generated['slug']
  end

  test "generated hash has tags" do
    assert_equal "tag, other", generated['tags']
  end

  test "generated hash has the edition's title" do
    assert_equal "Test local transaction", generated['title']
  end

  test "generated hash has nothing about service provision" do
    assert !generated.has_key?('authority')
  end

  test "generated hash for result page has the authority" do
    assert generated("00BC").has_key?('authority')
  end

  test "generated hash for result page has the authorities' name" do
    assert "Authority", generated("00BC")['authority']['name']
  end

  test "generated hash for result page has the authorities' snac code" do
    assert "00BC", generated("00BC")['authority']['snac']
  end

  test "generated hash for result page has an lgil code for the authority" do
    assert "8", generated("00BC")['authority']['lgils'].first['code']
  end

  test "generated hash for result page has an lgil url for the authority" do
    assert "http://authority.gov.uk/service", generated("00BC")['authority']['lgils'].first['url']
  end
end