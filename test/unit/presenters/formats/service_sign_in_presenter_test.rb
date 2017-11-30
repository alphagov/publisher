require 'test_helper'

class ServiceSignInTest < ActiveSupport::TestCase
  include GovukContentSchemaTestHelpers::TestUnit

  def subject
    Formats::ServiceSignInPresenter.new
  end

  def result
    subject.render_for_publishing_api
  end

  should "[:schema_name]" do
    assert_equal 'service_sign_in', result[:schema_name]
  end

  should "[:rendering_app]" do
    assert_equal 'government-frontend', result[:rendering_app]
  end

  should "[:publishing_app]" do
    assert_equal 'publisher', result[:publishing_app]
  end

  should "[:document_type]" do
    assert_equal 'service_sign_in', result[:document_type]
  end
end
