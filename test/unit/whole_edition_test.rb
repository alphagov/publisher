require 'test_helper'

class WholeEditionTest < ActiveSupport::TestCase
  setup do
    panopticon_has_metadata("id" => '2356', "slug" => 'childcare', "name" => "Childcare")
  end
  
  def template_published_answer(version_number = 1)
    answer = AnswerEdition.create(slug: "childcare", panopticon_id: 1, title: 'Child care stuff', body: 'Lots of info', version_number: version_number)
    answer.state = 'ready'
    answer.publish
    answer.save
    answer
  end

  def template_transaction
    transaction = TransactionEdition.create(panopticon_id: 2, slug: "childcare")
    transaction.title = 'One'
    transaction.introduction = 'introduction'
    transaction.more_information = 'more info'
    transaction.save
    transaction
  end

  def template_unpublished_answer(version_number = 1)
    without_metadata_denormalisation(AnswerEdition) do
      AnswerEdition.create(panopticon_id: 3, slug: "unpublished", title: "One", body: "Lots of info", version_number: version_number)
    end
  end

  test "it should give a friendly (legacy supporting) description of its format" do
    a = LocalTransactionEdition.new
    assert_equal 'LocalTransaction', a.format
  end

  test "it should be able to find its siblings" do
  	g1 = FactoryGirl.create(:guide_edition, :panopticon_id => 1, :version_number => 1)
  	g2 = FactoryGirl.create(:guide_edition, :panopticon_id => 2, :version_number => 1)
  	g3 = FactoryGirl.create(:guide_edition, :panopticon_id => 1, :version_number => 2)
  	assert_equal [], g2.siblings.to_a
  	assert_equal [g3], g1.siblings.to_a
  end

  test "it should be able to find its previous siblings" do
  	g1 = FactoryGirl.create(:guide_edition, :panopticon_id => 1, :version_number => 1)
  	g2 = FactoryGirl.create(:guide_edition, :panopticon_id => 2, :version_number => 1)
  	g3 = FactoryGirl.create(:guide_edition, :panopticon_id => 1, :version_number => 2)
  	
  	assert_equal [], g1.previous_siblings.to_a
  	assert_equal [g1], g3.previous_siblings.to_a
  end

  test "edition finder should return the published edition when given an empty edition parameter" do
    dummy_publication = template_published_answer
    second_publication = template_unpublished_answer(2)

    assert dummy_publication.published?
    assert_equal dummy_publication, WholeEdition.find_and_identify('childcare', '')
  end

  test "struct for search index" do
    dummy_publication = template_published_answer
    out = dummy_publication.search_index
    assert_equal ["title", "link", "section", "format", "description", "indexable_content"], out.keys
  end

  test "search index for all publications" do
    dummy_publication = template_published_answer
    out = WholeEdition.search_index_all
    assert_equal 1, out.count
    assert_equal ["title", "link", "section", "format", "description", "indexable_content"], out.first.keys
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

    publication = WholeEdition.create_from_panopticon_data(2356, user)

    assert_kind_of AnswerEdition, publication
    assert_equal "Foo bar", publication.title
    assert_equal 2356, publication.panopticon_id
  end

  test "should not change edition name if published" do
    guide = Factory(:guide_edition,
                    panopticon_id: 2356,
                    title: "Original title",
                    slug: "original-title"
    )
    guide.state = 'ready'
    guide.save!
    User.create(:name => "Winston").publish(guide, comment: 'testing')

    panopticon_has_metadata(
        "id" => 2356,
        "slug" => "foo-bar",
        "kind" => "guide",
        "name" => "New title"
    )
    guide.save!

    assert_equal "Original title", guide.reload.title
  end

  test "should scope publications by assignee" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
        to_return(:status => 200, :body => "{}", :headers => {})

    a, b = 2.times.map { FactoryGirl.create(:guide_edition) }

    alice, bob, charlie = %w[ alice bob charlie ].map { |s|
      FactoryGirl.create(:user, name: s)
    }
    alice.assign(a, bob)
    alice.assign(a, charlie)
    alice.assign(b, bob)

    assert_equal [b], WholeEdition.assigned_to(bob).to_a
  end

  test "cannot delete a publication that has been published" do
    dummy_answer = template_published_answer
    loaded_answer = AnswerEdition.where(slug: 'childcare').first

    assert_equal loaded_answer, dummy_answer
    assert ! dummy_answer.can_destroy?
    assert_raise (Workflow::CannotDeletePublishedPublication) do
      dummy_answer.destroy
    end
  end

  test "cannot delete a published publication with a new draft edition" do
    dummy_answer = template_published_answer

    new_edition = dummy_answer.build_clone
    new_edition.body = 'Two'
    dummy_answer.save

    assert_raise (WholeEdition::CannotDeletePublishedPublication) do
      dummy_answer.destroy
    end
  end

  test "can delete a publication that has not been published" do
    dummy_answer = template_unpublished_answer
    loaded_answer = AnswerEdition.first(conditions: {:slug=>"unpublished"})

    assert_equal loaded_answer, dummy_answer

    dummy_answer.destroy

    loaded_answer = AnswerEdition.first(conditions: {:slug=>"unpublished"})
    assert_nil loaded_answer
  end

  test "should scope publications assigned to nobody" do
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
        to_return(:status => 200, :body => "{}", :headers => {})

    Rails.logger.warn "MONGODB: ABout to create two guides"
    a, b = 2.times.map { |i| GuideEdition.create!(panopticon_id: i, title: "Guide #{i}", slug: "guide-#{i}") }
    Rails.logger.warn "MONGODB: Done creating two guides"
    
    alice, bob, charlie = %w[ alice bob charlie ].map { |s|
      FactoryGirl.create(:user, name: s)
    }

    alice.assign(a, bob)
    a.reload
    assert_equal bob, a.assigned_to
    
    alice.assign(a, charlie)
    a.reload
    assert_equal charlie, a.assigned_to

    assert_equal 2, WholeEdition.count
    assert_equal [b], WholeEdition.assigned_to(nil).to_a
    assert_equal [], WholeEdition.assigned_to(bob).to_a
    assert_equal [a], WholeEdition.assigned_to(charlie).to_a
  end

  test "should update Rummager on publication" do
    user = FactoryGirl.create(:user, name: 'Winston')
    
    publication = FactoryGirl.create(:guide_edition)
    publication.update_attribute(:state, 'ready')

    Rummageable.expects(:index).with(publication.search_index).returns(true)

    user.publish(publication, comment: 'Testing')
    publication.save
  end

  test "should update Rummager on deletion" do
    publication = FactoryGirl.create(:guide_edition, :slug => "hedgehog-topiary")
    publication.save

    Rummageable.expects(:delete).with("/hedgehog-topiary")

    publication.destroy
  end

  test "given multiple editions, can return the most recent published edition" do
    publication = FactoryGirl.create(:guide_edition, :slug => "hedgehog-topiary")
    publication.save

    publication.update_attribute(:state, 'archived')

    second_edition = publication.build_clone
    second_edition.update_attribute(:state, 'published')

    third_edition = second_edition.build_clone
    third_edition.update_attribute(:state, 'draft')

    assert_equal publication.published_edition, second_edition
  end
end
