if User.where(name: "Test user").present?
  puts "Skipping because user already exists"
else
  gds_organisation_id = "af07d5a5-df63-4ddc-9383-6a666845ebe9"
  user_id = SecureRandom.uuid

  User.create!(
    name: "Test user",
    uid: user_id,
    permissions: ["signin", "editor", "skip_review"],
    organisation_content_id: gds_organisation_id,
  )
end
