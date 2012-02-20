require 'test_helper'

class PublicationTest < ActiveSupport::TestCase

  setup do
    panopticon_has_metadata("id" => '2356', "slug" => 'childcare', "name" => "Childcare")
  end

  def template_published_answer
    answer = Answer.create(:slug=>"childcare", :name=>"Something")
    edition = answer.editions.first
    edition.title = 'One'
    edition.body = '*Lots of info*'
    answer.save
    edition.state = 'ready'
    edition.publish
    answer.save
    answer
  end

  def template_transaction
    trans = Transaction.create(:slug=>"childcare", :name=>"Something")
    edition = trans.editions.first
    edition.title = 'One'
    edition.introduction = '*introduction*'
    edition.more_information = '*more info*'
    trans.save
    trans
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

  test "edition finder should return the published edition when given an empty edition parameter" do
    dummy_publication = template_published_answer
    assert dummy_publication.published_edition
    Publication.stubs(:where).returns([dummy_publication])
    assert_equal Publication.find_and_identify_edition('register-offices', ''), dummy_publication.published_edition
  end

  test "struct for search index" do
    dummy_publication = template_published_answer
    out = dummy_publication.search_index
    assert_equal ["title", "link", "section", "subsection", "format", "description", "indexable_content"].sort, out.keys.sort
  end

  test "search index for all publications" do
    dummy_publication = template_published_answer
    out = Publication.search_index_all
    assert_equal 1, out.count
    assert_equal ["title", "link", "section", "subsection", "format", "description", "indexable_content"].sort, out.first.keys.sort
  end

  test "search indexable content for answer" do
    dummy_publication = template_published_answer
    assert_equal dummy_publication.indexable_content, "Lots of info"
  end

  test "search indexable content for transaction" do
    dummy_publication = template_transaction
    assert_equal dummy_publication.indexable_content, "introduction more info"
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

    publication = Publication.create_from_panopticon_data(2356, user)

    assert_kind_of Answer, publication
    assert_equal "Foo bar", publication.name
    assert_equal 2356, publication.panopticon_id
  end

  test "should not change edition name if published" do
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
    dummy_answer = template_published_answer

    edition = dummy_answer.editions.first
    new_edition = edition.build_clone
    new_edition.body = 'Two'
    dummy_answer.save

    assert_raise (Publication::CannotDeletePublishedPublication) do
      dummy_answer.destroy
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

    assert_equal([], Publication.assigned_to(bob))
    assert_equal([a], Publication.assigned_to(charlie))
    assert_equal [b], Publication.assigned_to(nil).to_a
  end

  test "should update Rummager on publication" do
    publication = FactoryGirl.create(:guide)
    edition = publication.editions.first
    edition.update_attribute(:state, 'ready')
    Rummageable.expects(:index).with(publication.search_index)

    User.create(:name => 'Winston').publish(edition, comment: 'Testing')
    publication.save
  end

  test "should update Rummager on deletion" do
    publication = FactoryGirl.create(:guide, :slug => "hedgehog-topiary")
    publication.save

    Rummageable.expects(:delete).with("/hedgehog-topiary")

    publication.destroy
  end

  test "given multiple editions, can return the most recent published edition" do
    publication = FactoryGirl.create(:guide, :slug => "hedgehog-topiary")
    publication.save

    first_edition = publication.editions.create(version_number: 1)
    first_edition.update_attribute(:state, 'archived')

    second_edition = publication.editions.create(version_number: 2)
    second_edition.update_attribute(:state, 'published')

    third_edition = publication.editions.create(version_number: 3)
    third_edition.update_attribute(:state, 'draft')

    assert_equal publication.published_edition, second_edition
  end
end
