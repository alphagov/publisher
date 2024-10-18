module PresenterTestHelpers
  def it_includes_last_edited_by_editor_id
    should "[:last_edited_by_editor_id]" do
      editor = FactoryBot.create(:user)
      edition.actions.create!(request_type: Action::CREATE, requester: editor)

      assert_equal editor.uid, result[:last_edited_by_editor_id]
    end
  end
end
