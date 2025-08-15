require "test_helper"
require "rake"

class AccessAndPermissionsTaskTest < ActiveSupport::TestCase
  setup do
    $stdout.stubs(puts: "")

    @add_organisation_access_task = Rake::Task["permissions:add_organisation_access"]
    @bulk_process_task = Rake::Task["permissions:bulk_process_access_flags"]

    @add_organisation_access_task.reenable
    @bulk_process_task.reenable

    @artefact1 = FactoryBot.create(:artefact, slug: "example-slug-1")
    @artefact2 = FactoryBot.create(:artefact, slug: "example-slug-2")
    @edition1 = FactoryBot.create(:edition, panopticon_id: @artefact1.id, owning_org_content_ids: [])
    @edition2 = FactoryBot.create(:edition, panopticon_id: @artefact2.id, owning_org_content_ids: [])
    @csv_file_path = Rails.root.join("tmp/test_bulk_access.csv")
    CSV.open(@csv_file_path, "w") do |csv|
      csv << %w[Header1 URL]
      csv << ["Row1", "https://www.gov.uk/example-slug-1"]
      csv << ["Row2", "https://www.gov.uk/example-slug-2"]
    end
  end

  test "add_organisation_access assigns permissions correctly" do
    organisation_id = "test-org-id"

    @add_organisation_access_task.invoke(@artefact1.id, organisation_id)
    @edition1.reload

    assert_includes @edition1.owning_org_content_ids, organisation_id
    assert_not_includes @edition2.owning_org_content_ids, organisation_id
  end

  test "add_organisation_access does not duplicate access" do
    organisation_id = "test-org-id"
    @edition1.update!(owning_org_content_ids: [organisation_id])

    @add_organisation_access_task.invoke(@artefact1.id, organisation_id)
    @edition1.reload

    assert_equal(1, @edition1.owning_org_content_ids.count { |id| id == organisation_id })
  end

  test "add_organisation_access does not update 'updated_at' values" do
    organisation_id = "test-org-id"
    # For some reason, the "updated_at" value when reloaded is different from the one in the object returned by the
    # factory, so we need to do a reload before storing a copy of the original value.
    @edition1.reload
    @artefact1.reload
    original_edition_updated_at = @edition1.updated_at
    original_artefact_updated_at = @artefact1.updated_at

    @add_organisation_access_task.invoke(@artefact1.id, organisation_id)
    @edition1.reload
    @artefact1.reload

    assert_equal(original_edition_updated_at, @edition1.updated_at)
    assert_equal(original_artefact_updated_at, @artefact1.updated_at)
  end

  test "bulk_process_access_flags processes all rows in CSV" do
    organisation_id = "test-org-id"

    @bulk_process_task.invoke(@csv_file_path.to_s, organisation_id)

    @edition1.reload
    @edition2.reload

    assert_includes @edition1.owning_org_content_ids, organisation_id
    assert_includes @edition2.owning_org_content_ids, organisation_id
  end
end
