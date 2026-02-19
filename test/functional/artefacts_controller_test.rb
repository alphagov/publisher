require "test_helper"

class ArtefactsControllerTest < ActionController::TestCase
  context "#new" do
    should "render the 'new' template if govuk_editor" do
      login_as_govuk_editor

      get :new

      assert_response :ok
      assert_template :new
    end

    should "not render the 'new' template if welsh_editor" do
      login_as_welsh_editor

      get :new

      assert_redirected_to root_path
      assert_includes flash[:danger], "You do not have permission to see this page."
    end

    should "not render the 'new' template if no permissions" do
      user = FactoryBot.create(:user, name: "Non-editor")
      login_as(user)

      get :new

      assert_redirected_to root_path
      assert_includes flash[:danger], "You do not have permission to see this page."
    end
  end

  context "#content_details" do
    should "render the 'new' template if no params passed" do
      login_as_govuk_editor

      post :content_details

      assert_response :ok
      assert_template :new
    end

    should "render the 'new' template if no kind passed" do
      login_as_govuk_editor

      post :content_details, params: { artefact: { kind: "" } }

      assert_response :ok
      assert_template :new
    end

    should "render the 'content_details' template if govuk_editor and kind passed" do
      login_as_govuk_editor

      post :content_details, params: { artefact: { kind: "answer" } }

      assert_response :ok
      assert_template :content_details
    end

    should "not render the 'content_details' template if welsh_editor" do
      login_as_welsh_editor

      post :content_details, params: { artefact: { kind: "answer" } }

      assert_redirected_to root_path
      assert_includes flash[:danger], "You do not have permission to see this page."
    end

    should "not render the 'content_details' template if no permissions" do
      user = FactoryBot.create(:user, name: "Non-editor")
      login_as(user)

      post :content_details, params: { artefact: { kind: "answer" } }

      assert_redirected_to root_path
      assert_includes flash[:danger], "You do not have permission to see this page."
    end
  end

  context "#create" do
    should "redirect to the publication page if valid params passed" do
      login_as_govuk_editor

      post :create, params: { artefact: { kind: "answer", name: "Example name", slug: "example-name", language: "en" } }

      @artefact = Artefact.first
      assert_equal 1, Artefact.count
      assert_equal 1, Edition.count
      assert_equal 1, AnswerEdition.count

      assert_redirected_to publication_path(@artefact)
    end

    should "create an artefact with the correct attributes" do
      login_as_govuk_editor

      post :create, params: { artefact: { kind: "answer", name: "Example name", slug: "example-name", language: "en" } }

      @artefact = Artefact.first
      assert_equal "answer", @artefact.kind
      assert_equal "Example name", @artefact.name
      assert_equal "example-name", @artefact.slug
      assert_equal "en", @artefact.language
      assert_equal "publisher", @artefact.owning_app
    end

    should "render the 'content_details' template and not save if invalid params passed" do
      login_as_govuk_editor

      post :create, params: { artefact: { kind: "answer" } }

      assert_equal 0, Artefact.count
      assert_equal 0, Edition.count
      assert_equal 0, AnswerEdition.count

      assert_template :content_details
    end

    should "render the 'content_details' template and not save if no name" do
      login_as_govuk_editor

      post :create, params: { artefact: { kind: "answer", name: "", slug: "example-name", language: "en" } }

      assert_equal 0, Artefact.count
      assert_equal 0, Edition.count
      assert_equal 0, AnswerEdition.count

      assert_template :content_details
    end

    should "render the 'content_details' template and not save if no slug" do
      login_as_govuk_editor

      post :create, params: { artefact: { kind: "answer", name: "Example name", slug: "", language: "en" } }

      assert_equal 0, Artefact.count
      assert_equal 0, Edition.count
      assert_equal 0, AnswerEdition.count

      assert_template :content_details
    end

    should "render the 'content_details' template and not save if no language" do
      login_as_govuk_editor

      post :create, params: { artefact: { kind: "answer", name: "Example name", slug: "example-name", language: "" } }

      assert_equal 0, Artefact.count
      assert_equal 0, Edition.count
      assert_equal 0, AnswerEdition.count

      assert_template :content_details
    end

    should "create a help page with the correct attributes" do
      login_as_govuk_editor

      post :create, params: { artefact: { kind: "help_page", name: "Example name", slug: "example-name", language: "en" } }

      @artefact = Artefact.first
      assert_equal "help_page", @artefact.kind
      assert_equal "Example name", @artefact.name
      assert_equal "help/example-name", @artefact.slug
      assert_equal "en", @artefact.language
      assert_equal "publisher", @artefact.owning_app
    end

    should "create a completed transaction page with the correct attributes" do
      login_as_govuk_editor

      post :create, params: { artefact: { kind: "completed_transaction", name: "Example name", slug: "example-name", language: "en" } }

      @artefact = Artefact.first
      assert_equal "completed_transaction", @artefact.kind
      assert_equal "Example name", @artefact.name
      assert_equal "done/example-name", @artefact.slug
      assert_equal "en", @artefact.language
      assert_equal "publisher", @artefact.owning_app
    end

    context "when creating a local transaction edition" do
      setup do
        FactoryBot.create(:local_service, lgsl_code: 1)
      end

      should "create artefact and child records and redirect to the publication page if valid params passed" do
        login_as_govuk_editor

        post :create, params: { artefact: { kind: "local_transaction", name: "Example name", slug: "example-name", language: "en" },
                                local_transaction_edition: { lgsl_code: 1, lgil_code: 2 } }

        @artefact = Artefact.first
        assert_equal 1, Artefact.count
        assert_equal 1, Edition.count
        assert_equal 1, LocalTransactionEdition.count
        assert_redirected_to publication_path(@artefact)
      end

      should "create a local transaction with the correct attributes" do
        login_as_govuk_editor

        post :create, params: { artefact: { kind: "local_transaction", name: "Example name", slug: "example-name", language: "en" },
                                local_transaction_edition: { lgsl_code: 1, lgil_code: 2 } }

        @artefact = Artefact.first
        @local_transaction = LocalTransactionEdition.first
        assert_equal "local_transaction", @artefact.kind
        assert_equal "Example name", @artefact.name
        assert_equal "example-name", @artefact.slug
        assert_equal "en", @artefact.language
        assert_equal "publisher", @artefact.owning_app
        assert_equal 1, @local_transaction.lgsl_code
        assert_equal 2, @local_transaction.lgil_code
      end

      should "not create artefact or child records if invalid local transaction params passed" do
        login_as_govuk_editor

        post :create, params: { artefact: { kind: "local_transaction", name: "Example name", slug: "example-name", language: "en" },
                                local_transaction_edition: { lgsl_code: "invalid", lgil_code: 2 } }

        assert_equal 0, Artefact.count
        assert_equal 0, Edition.count
        assert_equal 0, LocalTransactionEdition.count

        assert_template :content_details
      end

      should "add local transaction error messages to artefact instance variable assignment" do
        login_as_govuk_editor

        post :create, params: { artefact: { kind: "local_transaction", name: "Example name", slug: "example-name", language: "en" },
                                local_transaction_edition: { lgsl_code: "invalid", lgil_code: "invalid" } }

        assert_includes assigns(:artefact).errors[:lgsl_code], "LGSL code is not recognised"
        assert_includes assigns(:artefact).errors[:lgil_code], "LGIL code can only be a whole number between 0 and 999"
      end

      should "not create artefact or child records if invalid artefact params passed" do
        login_as_govuk_editor

        post :create, params: { artefact: { kind: "local_transaction", name: nil, slug: nil, language: nil },
                                local_transaction_edition: { lgsl_code: 1, lgil_code: 2 } }

        assert_equal 0, Artefact.count
        assert_equal 0, Edition.count
        assert_equal 0, LocalTransactionEdition.count

        assert_template :content_details
      end
    end
  end
end
