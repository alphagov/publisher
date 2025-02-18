if User.where(name: "Test user").blank?
  gds_organisation_id = "af07d5a5-df63-4ddc-9383-6a666845ebe9"

  User.create!(
    name: "Test user",
    permissions: %w[signin govuk_editor skip_review],
    organisation_content_id: gds_organisation_id,
  )
end
