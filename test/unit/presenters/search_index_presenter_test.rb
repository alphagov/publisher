require "test_helper"

class SearchIndexPresenterTest < ActiveSupport::TestCase
  def template_answer(version_number = 1)
    artefact = FactoryGirl.create(:artefact)
    AnswerEdition.create(state: 'ready', slug: "childcare", panopticon_id: artefact.id,
      title: 'Child care stuff', body: 'Lots of info', version_number: version_number)
  end

  def template_published_answer(version_number = 1)
    answer = template_answer(version_number)
    answer.publish
    answer.save
    answer
  end

  def template_transaction
    artefact = FactoryGirl.create(:artefact)
    TransactionEdition.create(title: 'One', introduction: 'introduction',
      more_information: 'more info', panopticon_id: artefact.id, slug: "childcare")
  end

  def template_unpublished_answer(version_number = 1)
    template_answer(version_number)
  end

  setup do
    stub_register_published_content
    @artefact = FactoryGirl.create(:artefact)
    @edition = FactoryGirl.create(:guide_edition, state: "published", panopticon_id: @artefact.id)
  end

  context "state" do
    should "return live if the edition is published" do
      presenter = SearchIndexPresenter.new(@edition)
      assert_equal 'live', presenter.state
    end

    should "return archived if the edition is archived" do
      @edition.state = 'archived'
      presenter = SearchIndexPresenter.new(@edition)
      assert_equal 'archived', presenter.state
    end

    should "return draft if the edition is not published or archived" do
      @edition.state = 'other'
      presenter = SearchIndexPresenter.new(@edition)
      assert_equal 'draft', presenter.state
    end
  end

  context "description" do
    should "return the overview" do
      @edition.update_attribute(:overview, "Overviewiness")
      presenter = SearchIndexPresenter.new(@edition)
      assert_equal "Overviewiness", presenter.description
    end
  end

  context "latest changes" do
    setup do
      @edition_with_major_change = FactoryGirl.create(:answer_edition, major_change: true,
                                                                       change_note: 'First edition',
                                                                       updated_at: 1.minute.ago,
                                                                       state: 'published')
      @presenter = SearchIndexPresenter.new(@edition_with_major_change)
    end

    should "return the latest_change_note" do
      assert_equal 'First edition', @presenter.latest_change_note
    end

    should 'return the public_timestamp' do
      assert_equal @edition_with_major_change.updated_at.to_i, @presenter.public_timestamp.to_i
    end
  end

  context "paths and prefixes" do
    context "for a HelpPageEdition" do
      should "generate /slug and /slug.json path" do
        edition = FactoryGirl.build(:help_page_edition, :slug => "help/a-slug")
        presenter = SearchIndexPresenter.new(edition)

        assert_equal [], presenter.prefixes
        assert_equal ["/help/a-slug", "/help/a-slug.json"], presenter.paths
      end
    end

    context "for a TransactionEdition" do
      should "generate /slug and /slug.json path" do
        edition = FactoryGirl.build(:transaction_edition, :slug => "a-slug")
        presenter = SearchIndexPresenter.new(edition)

        assert_equal [], presenter.prefixes
        assert_equal ["/a-slug", "/a-slug.json"], presenter.paths
      end
    end

    context "for other edition types" do
      should "generate /slug prefix and /slug.json path" do
        edition = FactoryGirl.build(:answer_edition, :slug => "a-slug")
        presenter = SearchIndexPresenter.new(edition)

        assert_equal ["/a-slug"], presenter.prefixes
        assert_equal ["/a-slug.json"], presenter.paths
      end
    end
  end
end
