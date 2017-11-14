gds_organisation_id = "af07d5a5-df63-4ddc-9383-6a666845ebe9"

User.create!(
  name: "Test user",
  permissions: ["signin", "editor", "skip_review"],
  organisation_content_id: gds_organisation_id,
) unless User.where(name: "Test user").present?
