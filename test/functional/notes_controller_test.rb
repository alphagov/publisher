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

    context "when an Edition note is provided" do
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

        assert_redirected_to history_add_edition_note_edition_path(@edition)
        assert_includes flash[:danger], "Note failed to save"
      end
    end

    context "when an Important note is provided" do
      should "confirm the note was successfully recorded" do
        post :create,
             params: {
               edition_id: @edition.id,
               note: {
                 type: "important_note",
                 comment: @note_text,
               },
             }

        @edition.reload

        assert_equal(@note_text, @edition.important_note.comment)
        assert_redirected_to history_edition_path(@edition)
        assert_includes flash[:success], "Note recorded"
      end
    end

    # TODO: Test that a blank note is saved and message is "Note resolved"

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
      end
    end
  end
end
