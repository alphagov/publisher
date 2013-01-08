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

  context "paths" do
    should "generate paths, including .json" do
      edition = FactoryGirl.create(:edition,
        slug: "slug",
        title: "A publication",
        state: "published")
      registerable = RegisterableEdition.new(edition)

      assert_equal ["slug", "slug.json"], registerable.paths
    end

    context "GuideEdition" do
      should "generate standard paths, plus slug/print" do
        edition = GuideEdition.create(slug: "slug", title: "A guide edition", state: "published")
        registerable = RegisterableEdition.new(edition)

        assert_equal ["slug", "slug.json", "slug/print"], registerable.paths
      end

      should "also generate video path when applicable" do
        edition = FactoryGirl.create(:guide_edition_with_two_parts, slug: "slug", title: "A guide edition", state: "published")
        registerable = RegisterableEdition.new(edition)

        assert_equal ["slug", "slug.json", "slug/print", "slug/part-one", "slug/part-two"], registerable.paths
      end
    end

    context "ProgrammeEdition" do
      should "generate standard paths, paths for all parts, plus slug/print" do
        edition = FactoryGirl.create(:programme_edition, slug: "slug", title: "A programme edition", state: "published")
        edition.setup_default_parts
        registerable = RegisterableEdition.new(edition)

        assert_equal ["slug", "slug.json", "slug/print", "slug/overview",
          "slug/what-youll-get", "slug/eligibility", "slug/how-to-claim",
          "slug/further-information"], registerable.paths
      end
    end

    context "LocalTransactionEdition" do
      should "generate standard paths, plus slug/not_found" do
        edition = LocalTransactionEdition.create(slug: "slug", title: "A title", state: "published")
        registerable = RegisterableEdition.new(edition)

        assert_equal ["slug", "slug.json", "slug/not_found"], registerable.paths
      end
    end

    context "PlaceEdition" do
      should "generate standard paths, plus .kml" do
        edition = PlaceEdition.create(slug: "slug", title: "A places edition", state: "published")
        registerable = RegisterableEdition.new(edition)

        assert_equal ["slug", "slug.json", "slug.kml"], registerable.paths
      end
    end

    context "LicenceEdition" do
      should "generate only a json path" do
        edition = LicenceEdition.create(slug: "slug", title: "A title", state: "published")
        registerable = RegisterableEdition.new(edition)

        assert_equal ["slug.json"], registerable.paths
      end
    end
  end

  context "prefix" do
    context "LicenceEdition" do
      should "generate prefix routes for licences" do
        edition = LicenceEdition.create(slug: "slug", title: "A title", state: "published")
        registerable = RegisterableEdition.new(edition)

        assert_equal ["slug"], registerable.prefixes
      end
    end
  end
end
