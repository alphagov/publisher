require 'test_helper'

class LicenceGenerationTest < ActiveSupport::TestCase
  setup do
    #@updated_time = Time.now
    @licence = FactoryGirl.create(:licence_edition,
                                  slug: 'test_slug',
                                  title: 'Test Licence',
                                  alternative_title: 'This is an example licence title',
                                  licence_identifier: 'AB1234',
                                  licence_overview: 'Overview of Licence')
  end

  def generated
    Api::Generator.edition_to_hash(@licence)
  end

  should "return the standard data for a licence" do
    result = generated
    assert_equal "Test Licence", result['title']
    assert_equal "This is an example licence title", result['alternative_title']
  end

  should "return the extra fields for a licence" do
    result = generated
    assert_equal "AB1234", result['licence_identifier']
    assert_equal "Overview of Licence", result['licence_overview']
  end
end
