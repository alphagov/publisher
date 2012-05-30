require 'test_helper'

class EditionTest < ActiveSupport::TestCase

  def template_answer(version_number = 1)
    AnswerEdition.create(state: 'ready', slug: "childcare", panopticon_id: 1,
      title: 'Child care stuff', body: 'Lots of info', version_number: version_number)
  end

  def template_published_answer(version_number = 1)
    answer = template_answer(version_number)
    answer.publish
    answer.save
    answer
  end

  def template_transaction
    TransactionEdition.create(title: 'One', introduction: 'introduction',
      more_information: 'more info', panopticon_id: 2, slug: "childcare")
  end

  def template_unpublished_answer(version_number = 1)
    template_answer(version_number)
  end

  test "should update Rummager on publication with no parts" do
    edition = FactoryGirl.create(:guide_edition, :state => 'ready')
    edition.stubs(:search_index).returns("stuff for search index")

    Rummageable.expects(:index).with("stuff for search index")
    user = FactoryGirl.create(:user)
    user.publish(edition, comment: 'Testing')
  end

  test "should update Rummager on deletion" do
    artefact = FactoryGirl.create(:artefact,
        slug: "hedgehog-topiary",
        kind: "guide",
        name: "Foo bar",
        owning_app: "publisher",
    )

    user = User.create
    edition = Edition.find_or_create_from_panopticon_data(artefact.id, user, {})

    Rummageable.expects(:delete).with("/hedgehog-topiary")
    edition.destroy
  end

  test "struct for search index" do
    dummy_publication = template_published_answer
    out = dummy_publication.search_index
    assert_equal ["title", "link", "format", "description", "indexable_content", "section", "subsection"], out.keys
  end

  test "search index for all publications" do
    dummy_publication = template_published_answer
    out = Edition.search_index_all
    assert_equal 1, out.count
    assert_equal ["title", "link", "format", "description", "indexable_content", "section", "subsection"], out.first.keys
  end

  test "search indexable content for answer" do
    dummy_publication = template_published_answer
    assert_equal dummy_publication.indexable_content, "Lots of info"
  end

  test "search indexable content for transaction" do
    dummy_publication = template_transaction
    assert_equal dummy_publication.indexable_content, "introduction more info"
  end

  test "search_index for a single part thing should have the normalised content of that part" do
    edition = FactoryGirl.create(:guide_edition, :state => 'ready', :title => 'one part thing', :alternative_title => 'alternative one part thing')
    edition.publish
    generated_search_content = edition.search_index
    assert_equal generated_search_content['indexable_content'], "alternative one part thing"
    assert_equal generated_search_content['additional_links'].length, 0
  end

  test "search_index for a multi part thing should have the normalised content of all parts" do
    edition = FactoryGirl.create(:guide_edition_with_two_parts, :state => 'ready')
    edition.publish
    generated_search_content = edition.search_index
    assert_equal generated_search_content['indexable_content'], "PART ! This is some version text. PART !! This is some more version text."
    assert generated_search_content['additional_links'][1].has_value?("/#{edition.slug}/part-two")
  end
end
