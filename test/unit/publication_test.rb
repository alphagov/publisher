require 'test_helper'

class PublicationTest < ActiveSupport::TestCase
  def template_published_answer
    without_metadata_denormalisation(Answer) do
      answer = Answer.create(:slug=>"childcare", :name=>"Something")
      edition = answer.editions.first
      edition.title = 'One'
      edition.body = 'Lots of info'
      answer.save
      edition.publish(edition, 'Testing')
      answer.save
      answer
    end
  end

  def template_unpublished_answer
    without_metadata_denormalisation(Answer) do
      answer = Answer.create(:slug=>"unpublished", :name=>"Nothing")
      edition = answer.editions.first
      edition.title = 'One'
      edition.body = 'Lots of info'
      answer.save
      answer
    end
  end

  def panopticon_has_metadata(metadata)
    json = JSON.dump(metadata)
    url = "http://panopticon.test.gov.uk/artefacts/#{metadata['id']}.js"
    stub_request(:get, url).to_return(:status => 200, :body => json, :headers => {})
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
    panopticon_has_metadata(
        "id" => 2356,
        "slug" => "foo-bar",
        "kind" => "answer",
        "name" => "Foo bar"
    )

    user = User.create

    publication = Publication.import 2356, user

    assert_kind_of Answer, publication
    assert_equal "Foo bar", publication.name
    assert_equal "foo-bar", publication.slug
    assert_equal 2356, publication.panopticon_id
  end

  test "changes to name in panopticon should be reflected in the title of the latest edition on save" do
    guide = without_metadata_denormalisation(Guide) do
      Factory(:guide,
              panopticon_id: 2356,
              name: "Original title",
              slug: "original-title"
      )
    end
    panopticon_has_metadata(
        "id" => 2356,
        "slug" => "foo-bar",
        "kind" => "guide",
        "name" => "New title"
    )
    guide.save!

    assert_equal "New title", guide.reload.latest_edition.title
  end

  test "should not change edition name if published" do
    guide = nil
    without_metadata_denormalisation(Guide) do
      guide = Factory(:guide,
                      panopticon_id: 2356,
                      name: "Original title",
                      slug: "original-title"
      )
      guide.latest_edition.title = guide.name
      guide.save!
      guide.publish(guide.latest_edition, 'testing')
    end

    panopticon_has_metadata(
        "id" => 2356,
        "slug" => "foo-bar",
        "kind" => "guide",
        "name" => "New title"
    )
    guide.save!

    assert_equal "Original title", guide.reload.latest_edition.title
  end

  test "should scope publications by assignee" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
        to_return(:status => 200, :body => "{}", :headers => {})

    a, b = 2.times.map { FactoryGirl.create(:guide) }
    alice, bob, charlie = %w[ alice bob charlie ].map { |s|
      FactoryGirl.create(:user, name: s)
    }
    alice.assign(a.editions.first, bob)
    alice.assign(a.editions.first, charlie)
    alice.assign(b.editions.first, bob)

    assert_equal [b], Publication.assigned_to(bob).to_a
  end

  test "cannot delete a publication that has been published" do
    dummy_answer = template_published_answer
    loaded_answer = Answer.first(conditions: {:slug=>"childcare"})

    assert_equal loaded_answer, dummy_answer

    assert_raise (Publication::CannotDeletePublishedPublication) do
      dummy_answer.destroy
    end
  end

  test "should scope publications assigned to nobody" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
        to_return(:status => 200, :body => "{}", :headers => {})

    a, b = 2.times.map { FactoryGirl.create(:guide) }
    alice, bob, charlie = %w[ alice bob charlie ].map { |s|
      FactoryGirl.create(:user, name: s)
    }
    alice.assign(a.editions.first, bob)
    alice.assign(a.editions.first, charlie)

    assert_equal [b], Publication.assigned_to(nil).to_a
  end
end
