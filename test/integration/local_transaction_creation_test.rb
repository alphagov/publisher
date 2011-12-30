#encoding: utf-8
require 'integration_test_helper'

class LocalTransactionCreationTest < ActionDispatch::IntegrationTest
  setup do
    current = LocalTransactionsSource.create
    current_lgsl = current.lgsls.create(code: "1")
    current_lgsl.authorities.create(snac: 'ABCDE')
  end

  test "creating a local transaction from panopticon requests an LGSL code" do
    setup_users

    panopticon_has_metadata(
      "id" => 2357,
      "slug" => "foo-bar",
      "kind" => "local_transaction",
      "name" => "Foo bar"
    )

    visit "/admin/publications/2357"
    assert page.has_content? "We need a bit more information to create your local transaction."
  end
end