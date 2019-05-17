revision_path = Rails.root.join("REVISION")
if File.exist?(revision_path)
  revision = File.read(revision_path).chomp
  CURRENT_RELEASE_SHA = revision[0..10] # Just get the short SHA
else
  CURRENT_RELEASE_SHA = "development".freeze
end
