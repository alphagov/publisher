require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
  end

  context "#show" do
    context "with existing edition" do
      should "redirect to the latest edition when requesting a panopticon_id" do
        artefact = FactoryGirl.create(:artefact,
          slug: "hedgehog-topiary",
          kind: "guide",
          name: "Foo bar",
          owning_app: "publisher",
                                     )

        FactoryGirl.create(:edition, panopticon_id: artefact.id, state: 'archived', version_number: 1)
        FactoryGirl.create(:edition, panopticon_id: artefact.id, state: 'published', version_number: 2)
        latest_edition = FactoryGirl.create(:edition, panopticon_id: artefact.id, state: 'draft', version_number: 3)

        get :show, params: { id: artefact.id }

        assert_redirected_to(controller: 'editions', action: 'show', id: latest_edition.id)
      end
    end

    context "without existing edition" do
      setup do
        @artefact = FactoryGirl.create(
          :artefact,
          slug: "hedgehog-topiary",
          kind: "guide",
          name: "Foo bar",
          owning_app: "publisher"
        )
      end

      should "redirect to new edition when requesting a panopticon_id" do
        get :show, params: { id: @artefact.id }

        latest_edition = GuideEdition.find_by(slug: "hedgehog-topiary")
        assert_redirected_to(controller: 'editions', action: 'show', id: latest_edition.id)
      end

      should "send updated content to the PublishingAPI" do
        UpdateWorker.expects(:perform_async)

        get :show, params: { id: @artefact.id }
      end
    end

    should "show a page when saving publication fails" do
      artefact = FactoryGirl.create(
        :artefact,
        slug: "hedgehog-topiary",
        kind: "local_transaction",
        name: "Foo bar",
        owning_app: "publisher"
      )
      assert Edition.where(panopticon_id: artefact.id).first.nil?

      get :show, params: { id: artefact.id }
      assert Edition.where(panopticon_id: artefact.id).first.nil?
      assert_response :success
    end
  end
end
