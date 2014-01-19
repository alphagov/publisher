require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user


  end

  test "requesting a panopticon_id should redirect to the latest edition" do
    artefact = FactoryGirl.create(:artefact,
        slug: "hedgehog-topiary",
        kind: "guide",
        name: "Foo bar",
        owning_app: "publisher",
    )


    FactoryGirl.create(:edition, :panopticon_id => artefact.id, :state => 'archived', :version_number => 1)
    FactoryGirl.create(:edition, :panopticon_id => artefact.id, :state => 'published', :version_number => 2)
    latest_edition = FactoryGirl.create(:edition, :panopticon_id => artefact.id, :state => 'draft', :version_number => 3)

    get :show, :id => artefact.id

    assert_redirected_to(:controller => 'editions', :action => 'show', :id => latest_edition.id)
  end

  test "when saving publication fails we show a page" do
    artefact = FactoryGirl.create(:artefact,
        slug: "hedgehog-topiary",
        kind: "local_transaction",
        name: "Foo bar",
        owning_app: "publisher",
    )
    assert Edition.where(panopticon_id: artefact.id).first.nil?

    get :show, :id => artefact.id
    assert Edition.where(panopticon_id: artefact.id).first.nil?
    assert_response :success
  end
end
