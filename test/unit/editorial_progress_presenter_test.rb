require 'test_helper'

class EditoriaProgressPresenterTest < ActiveSupport::TestCase
  setup do
    @artefact = FactoryBot.create(:artefact, name: "Childcare", slug: "childcare")
    @guide = FactoryBot.create(:guide_edition, slug: "childcare", title: "One", panopticon_id: @artefact.id)
  end

  test "produces CSV output even if items aren't assigned" do
    presenter = EditorialProgressPresenter.new(Edition.all)
    result = presenter.to_csv
    assert result
  end

  test "it includes the preview URL" do
    presenter = EditorialProgressPresenter.new(Edition.all)
    result = presenter.to_csv

    parsed = CSV.parse(result, headers: true)
    assert parsed['Preview url'].present?
  end

  test "lists out each separate edition of an item" do
    @guide.update_attribute :state, 'published'
    second_guide = @guide.build_clone
    second_guide.save

    presenter = EditorialProgressPresenter.new(Edition.all)
    result = presenter.to_csv
    assert_equal 3, result.lines.count
  end
end
