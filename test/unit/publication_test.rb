require 'test_helper'

class PublicationTest < ActiveSupport::TestCase
  def template_published_answer
    without_metadata_denormalisation(Answer) do
      g = Answer.create(:slug=>"childcare",:name=>"Something")
      edition = g.editions.first
      edition.title = 'One'
      edition.body = 'Lots of info'
      g.save
      edition.publish(edition, 'Testing')
      g
    end
  end

  test "edition finder should return the published edition when given an empty edition parameter" do
    dummy_publication = template_published_answer
    assert dummy_publication.published_edition
    Publication.stubs(:where).returns([dummy_publication])
    assert_equal Publication.find_and_identify_edition('register-offices', ''), dummy_publication.published_edition
  end
  
  test 'a publication should not have a video' do
    g = Answer.create(:slug=>"childcare")
    assert !g.has_video?
  end
end
