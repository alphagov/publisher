require 'test_helper'

class PublicationTest < ActiveSupport::TestCase

  setup do
    stub_request(:get, "http://panopticon.test.gov.uk/artefacts/childcare.js").
      to_return(:status => 200, :body => '{"name":"Something","slug":"childcare"}', :headers => {})
  end

  def template_published_answer
    without_metadata_denormalisation(Answer) do
      answer = Answer.create(:slug=>"childcare", :name=>"Something")
      edition = answer.editions.first
      edition.title = 'One'
      edition.body = 'Lots of info'
      answer.save
      edition.state = 'ready'
      edition.publish
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

  test "struct for search index" do
    dummy_publication = template_published_answer
    out = dummy_publication.search_index
    assert_equal ["title", "link", "format", "description", "indexable_content"], out.keys
  end

  test "search index for all publications" do
    dummy_publication = template_published_answer
    out = Publication.search_index_all
    assert_equal 1, out.count
    assert_equal ["title", "link", "format", "description", "indexable_content"], out.first.keys
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
      guide.latest_edition.state = 'ready'
      guide.latest_edition.save!
      guide.save!
      User.create(:name => "Winston").publish(guide.latest_edition, comment: 'testing')
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

  test "cannot delete a published publication with a new draft edition" do
    without_metadata_denormalisation(Answer) do
      dummy_answer = template_published_answer

      edition = dummy_answer.editions.first
      new_edition = edition.build_clone
      new_edition.body = 'Two'
      dummy_answer.save

      assert_raise (Publication::CannotDeletePublishedPublication) do
        dummy_answer.destroy
      end

    end
  end

  test "can delete a publication that has not been published" do
    dummy_answer = template_unpublished_answer
    loaded_answer = Answer.first(conditions: {:slug=>"unpublished"})

    assert_equal loaded_answer, dummy_answer

    dummy_answer.destroy

    loaded_answer = Answer.first(conditions: {:slug=>"unpublished"})
    assert_nil loaded_answer

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

  test "should update Rummager on publication" do
    without_metadata_denormalisation(Guide) do
      publication = FactoryGirl.create(:guide)
      edition = publication.editions.first
      publication.save

      Rummageable.expects(:index).with(publication.search_index)

      User.create(:name => 'Winston').publish(edition, comment: 'Testing')
      publication.save
    end
  end

  test "should update Rummager on deletion" do
    without_metadata_denormalisation(Guide) do
      publication = FactoryGirl.create(:guide, :slug => "hedgehog-topiary")
      publication.save

      Rummageable.expects(:delete).with("/hedgehog-topiary")

      publication.destroy
    end
  end
end
