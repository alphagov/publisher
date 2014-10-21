require "test_helper"

class RegisterableEditionTest < ActiveSupport::TestCase

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
      registerable = RegisterableEdition.new(@edition)
      assert_equal 'live', registerable.state
    end

    should "return archived if the edition is archived" do
      @edition.state = 'archived'
      registerable = RegisterableEdition.new(@edition)
      assert_equal 'archived', registerable.state
    end

    should "return draft if the edition is not published or archived" do
      @edition.state = 'other'
      registerable = RegisterableEdition.new(@edition)
      assert_equal 'draft', registerable.state
    end
  end

  context "description" do
    should "return the overview" do
      @edition.update_attribute(:overview, "Overviewiness")
      registerable = RegisterableEdition.new(@edition)
      assert_equal "Overviewiness", registerable.description
    end
  end

  context "sections" do
    should "return the browse pages" do
      @edition.update_attributes(
        browse_pages: ["tax/vat", "tax/capital-gains"]
      )
      registerable = RegisterableEdition.new(@edition)
      assert_equal ["tax/vat", "tax/capital-gains"], registerable.sections
    end
  end

  context "specialist_sectors" do
    should "return the combined topics" do
      @edition.update_attributes(
        primary_topic: "oil-and-gas/wells",
        additional_topics: ["oil-and-gas/licensing", "oil-and-gas/fields"]
      )
      registerable = RegisterableEdition.new(@edition)
      assert_equal ["oil-and-gas/wells", "oil-and-gas/licensing", "oil-and-gas/fields"], registerable.specialist_sectors
    end
  end

  context "paths and prefixes" do
    context "for a CampaignEdition" do
      should "generate /slug and /slug.json path" do
        edition = FactoryGirl.build(:campaign_edition, :slug => "a-slug")
        registerable = RegisterableEdition.new(edition)

        assert_equal [], registerable.prefixes
        assert_equal ["/a-slug", "/a-slug.json"], registerable.paths
      end
    end

    context "for a HelpPageEdition" do
      should "generate /slug and /slug.json path" do
        edition = FactoryGirl.build(:help_page_edition, :slug => "help/a-slug")
        registerable = RegisterableEdition.new(edition)

        assert_equal [], registerable.prefixes
        assert_equal ["/help/a-slug", "/help/a-slug.json"], registerable.paths
      end
    end

    context "for a TransactionEdition" do
      should "generate /slug and /slug.json path" do
        edition = FactoryGirl.build(:transaction_edition, :slug => "a-slug")
        registerable = RegisterableEdition.new(edition)

        assert_equal [], registerable.prefixes
        assert_equal ["/a-slug", "/a-slug.json"], registerable.paths
      end
    end

    context "for other edition types" do
      should "generate /slug prefix and /slug.json path" do
        edition = FactoryGirl.build(:answer_edition, :slug => "a-slug")
        registerable = RegisterableEdition.new(edition)

        assert_equal ["/a-slug"], registerable.prefixes
        assert_equal ["/a-slug.json"], registerable.paths
      end
    end
  end
end
