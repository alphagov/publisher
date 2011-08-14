require 'test_helper'

class LocalTransactionClientTest < ActiveSupport::TestCase
  setup do
    @lt_client = Api::Client::LocalTransaction.from_hash(
      "slug"=>"test_slug", "tags" => "tag, other", "introduction"=>"", "more_information"=>"", "title"=>"test lt", 
      "expectations"=>[{"css_class"=>"less_than_40", "text"=>"Less than 40 minutes"}, {"css_class"=>"need_ni", "text"=>"National Insurance Number required"}], 
      "authority"=>{
        "name"=>"Authority", "snac"=>"00BC", 
        "lgils"=>[
          {"code"=>"0", "url"=>"http://authority.gov.uk/service/about"}, 
          {"code"=>"8", "url"=>"http://authority.gov.uk/service/transaction"}
        ]
      }
    )
  end

  test "has slug" do
    assert_equal "test_slug", @lt_client.slug
  end

  test "has tags" do
    assert_equal "tag, other", @lt_client.tags
  end

  test "has edition title" do
    assert_equal "test lt", @lt_client.title
  end

  test "has expectations" do
    assert_equal 2, @lt_client.expectations.length
  end

  test "has expectation css class name" do
    assert_equal "less_than_40", @lt_client.expectations.first.css_class
  end

  test "has expectation text" do
    assert_equal "Less than 40 minutes", @lt_client.expectations.first.text
  end

  test "has authority name" do
    assert_equal 'Authority', @lt_client.authority.name
  end

  test "has authority SNAC" do
    assert_equal "00BC", @lt_client.authority.snac
  end

  test "has lgils" do
    assert_equal 2, @lt_client.authority.lgils.length
  end

  test "has lgil code" do
    assert_equal "0", @lt_client.authority.lgils.first.code
  end

  test "has lgil url" do
    assert_equal "http://authority.gov.uk/service/about", @lt_client.authority.lgils.first.url
  end
end