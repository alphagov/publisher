require 'test_helper'

class LicenceGenerationTest < ActiveSupport::TestCase
  def setup
    @updated_time = Time.now
    @licence = FactoryGirl.create(:licence_edition, slug: 'test_slug', title: 'Test Licence', alternative_title: 'This is an example licence title')
  end

  def generated
    Api::Generator.edition_to_hash(@licence)
  end

  def test_api_licence_has_alternative_title
    assert_equal "This is an example licence title", generated['alternative_title']
  end
end
