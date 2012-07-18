require 'integration_test_helper'

class LocalTransactionApiTest < ActionDispatch::IntegrationTest
  setup do
    authority = FactoryGirl.create(:local_authority_with_contact,
      snac: "AA00",
      contact_address: ["Line 1", "line 2"],
      contact_url: "http://some.council.gov.uk/contact",
      contact_phone: "0000000000",
      contact_email: "contact@some.council.gov.uk"
    )
    interaction = FactoryGirl.create(:local_interaction,
      local_authority: authority,
      url: "http://some.council.gov.uk/do.html"
    )
    service = FactoryGirl.create(:local_service, lgsl_code: interaction.lgsl_code)
    edition = FactoryGirl.create(:local_transaction_edition,
      title: "Some Edition",
      slug: "some-edition",
      state: "published",
      lgsl_code: interaction.lgsl_code
    )
  end

  test "basic edition information but no interaction is returned when no snac is provided" do
    visit "/publications/some-edition.json"
    assert_equal 200, page.status_code
    response = JSON.parse(page.source)
    assert_equal "Some Edition", response['title']
    assert_false response.has_key? "interaction"
  end

  test "basic edition information and interaction is returned when there is an interaction for the provided snac" do
    visit "/publications/some-edition.json?snac=AA00"
    assert_equal 200, page.status_code
    response = JSON.parse(page.source)
    assert_equal "Some Edition", response['title']
    assert_true response.has_key? "interaction"
    assert_equal "http://some.council.gov.uk/do.html", response['interaction']['url']
    authority = response['interaction']['authority']
    assert_equal ['Line 1', 'line 2'], authority['contact_address']
    assert_equal "http://some.council.gov.uk/contact", authority['contact_url']
    assert_equal "0000000000", authority['contact_phone']
    assert_equal "contact@some.council.gov.uk", authority['contact_email']
  end

  test "404 if snac code not found" do
    visit "/local_transactions/find_by_snac?snac=bloop"
    assert_equal 404, page.status_code
    assert_equal " ", page.source
  end

  test "returns a council hash if provided with a snac code" do
    visit "/local_transactions/find_by_snac?snac=AA00"
    assert_equal 200, page.status_code
    response = JSON.parse(page.source)
    expected = {"name" => "Some Council", "snac" => "AA00"}
    assert_equal expected, response
  end

  test "404 if council not found" do
    visit "/local_transactions/find_by_council?council=bloop"
    assert_equal 404, page.status_code
    assert_equal " ", page.source
  end

  test "returns a council hash if provided with a lower case council name" do
    visit "/local_transactions/find_by_council?council=some%20council"
    assert_equal 200, page.status_code
    response = JSON.parse(page.source)
    expected = {"name" => "Some Council", "snac" => "AA00"}
    assert_equal expected, response
  end

  test "returns a council hash if provided with a mixed case council name" do
    visit "/local_transactions/find_by_council?council=Some%20Council"
    assert_equal 200, page.status_code
    response = JSON.parse(page.source)
    expected = {"name" => "Some Council", "snac" => "AA00"}
    assert_equal expected, response
  end
end
