require "test_helper"

class NotesControllerTest < ActionController::TestCase
  setup do
    login_as_stub_user
    stub_linkables
    stub_holidays_used_by_fact_check
  end

  context "#create" do
    setup do
      @edition = FactoryBot.create(:edition)
      @note_text = "A New Note!"
    end

    context "when a comment is not provided" do
      should "resolve any ImportantNotes if the edition has an existing ImportantNote" do
        post :create,
             params: {
               edition_id: @edition.id,
               note: {
                 type: "important_note",
                 comment: "Important note text",
               },
             }

        @edition.reload
        assert_equal "Important note text", @edition.actions.first.comment
        assert_equal "important_note", @edition.actions.first.request_type

        post :create,
             params: {
               edition_id: @edition.id,
               note: {
                 type: "important_note",
               },
             }

        assert_redirected_to history_edition_path(@edition)
        assert_includes flash[:success], "Note resolved"

        @edition.reload
        assert_nil @edition.actions.last.comment
        assert_equal "important_note_resolved", @edition.actions.last.request_type
      end

      should "flash a warning that the note did not save if the edition does not have an existing ImportantNote" do
        post :create,
             params: {
               edition_id: @edition.id,
               note: {
                 type: "note",
               },
             }

        @edition.reload

        assert_redirected_to history_edition_path(@edition)
        assert_includes flash[:warning], "Didn’t save empty note"
        assert_equal [], @edition.actions
      end
    end

    context "when a comment is provided" do
      should "confirm the note was successfully recorded" do
        post :create,
             params: {
               edition_id: @edition.id,
               note: {
                 type: "note",
                 comment: @note_text,
               },
             }

        @edition.reload

        assert_redirected_to history_edition_path(@edition)
        assert_includes flash[:success], "Note recorded"
        assert_equal @note_text, @edition.actions.first.comment
      end

      should "flash a danger message if the note did not save" do
        @user.stubs(:record_note).with(@edition, @note_text, "note").returns(false)

        post :create,
             params: {
               edition_id: @edition.id,
               note: {
                 type: "note",
                 comment: @note_text,
               },
             }

        @edition.reload

        assert_redirected_to history_edition_path(@edition)
        assert_includes flash[:danger], "Note failed to save"
        assert_equal [], @edition.actions
      end
    end

    context "Welsh editors" do
      setup do
        login_as_welsh_editor
      end

      should "not be able to create notes for non-Welsh editions" do
        post :create,
             params: {
               edition_id: @edition.id,
               note: {
                 type: "note",
                 comment: @note_text,
               },
             }

        assert_redirected_to edition_path(@edition)
        assert_includes flash[:danger], "You do not have correct editor permissions for this action."
      end

      should "be able to create notes for Welsh editions" do
        welsh_edition = FactoryBot.create(:edition, :welsh)

        post :create,
             params: {
               edition_id: welsh_edition.id,
               note: {
                 type: "note",
                 comment: "Welsh note text",
               },
             }

        welsh_edition.reload

        assert_redirected_to history_edition_path(welsh_edition)
        assert_includes flash[:success], "Note recorded"
        assert_equal "Welsh note text", welsh_edition.actions.first.comment
      end
    end
  end
end
