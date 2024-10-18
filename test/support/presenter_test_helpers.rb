module PresenterTestHelpers
  def it_includes_last_edited_by_editor_id
    test "[:last_edited_by_editor_id] should return the creator of the edition" do
      editor = FactoryBot.create(:user)
      edition.actions.create!(request_type: Action::CREATE, requester: editor)

      assert_equal editor.uid, result[:last_edited_by_editor_id]
    end

    test "[:last_edited_by_editor_id] should return the creator of a new version" do
      editor = FactoryBot.create(:user)
      edition.actions.create!(request_type: Action::NEW_VERSION, requester: editor)

      assert_equal editor.uid, result[:last_edited_by_editor_id]
    end

    test "[:last_edited_by_editor_id] should return nil when there are no new version or create actions" do
      assert_nil result[:last_edited_by_editor_id]
    end
  end
end
