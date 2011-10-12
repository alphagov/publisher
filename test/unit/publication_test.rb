require 'test_helper'

class PublicationTest < ActiveSupport::TestCase
  def template_published_answer
    without_metadata_denormalisation(Answer) do
      answer = Answer.create(:slug=>"childcare",:name=>"Something")
      edition = answer.editions.first
      edition.title = 'One'
      edition.body = 'Lots of info'
      answer.save
      edition.publish(edition, 'Testing')

      answer
    end
  end

  test "edition finder should return the published edition when given an empty edition parameter" do
    dummy_publication = template_published_answer
    assert dummy_publication.published_edition
    Publication.stubs(:where).returns([dummy_publication])
    assert_equal Publication.find_and_identify_edition('register-offices', ''), dummy_publication.published_edition
  end
  
  test 'a publication should not have a video' do
    dummy_publication = template_published_answer
    assert !dummy_publication.has_video?
  end

  test "should create a publication based on data imported from panopticon" do
    json = JSON.dump(
      "id"   => 2356,
      "slug" => "foo-bar",
      "kind" => "answer",
      "name" => "Foo bar"
    )
    stub_request(:get, "http://panopticon.test.gov.uk/artefacts/2356.js").
     to_return(:status => 200, :body => json, :headers => {})
    user = User.create

    publication = Publication.import 2356, user

    assert_kind_of Answer, publication
    assert_equal "Foo bar", publication.name
    assert_equal "foo-bar", publication.slug
    assert_equal 2356,      publication.panopticon_id
  end

  test "should scope publications by assignee" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
     to_return(:status => 200, :body => "{}", :headers => {})

    a, b = 2.times.map { FactoryGirl.create(:guide) }
    alice, bob, charlie = %w[ alice bob charlie ].map{ |s|
      FactoryGirl.create(:user, name: s)
    }
    alice.assign(a.editions.first, bob)
    alice.assign(a.editions.first, charlie)
    alice.assign(b.editions.first, bob)

    assert_equal [b], Publication.assigned_to(bob).to_a
  end
end
