require 'csv'
# For some reason making the task depend on the "environment" task lead to
# stack overflow. Doing it this way solved that.
require File.expand_path('../../../config/environment',  __FILE__)

desc "Attempt to Publish the Editions specified in data/batch_publish.csv"
task :batch_publish do
  # If a given edition is already published, it is skipped.
  # The format of the file should be as follows:
  #
  # Slug,Edition
  # foo,1
  # bar,3
  #

  user_email = ENV['PUBLISH_AS_EMAIL'] or raise("PUBLISH_AS_EMAIL is required")
  filename = "data/batch_publish.csv"
  if File.exists?(filename)
    rows = CSV.read(filename, headers: true)
    rows = rows.reject(&:empty?)

    edition_identifers = rows.map do |row|
      if row["Slug"].present? && row["Edition"].present?
        { slug: row["Slug"], edition: Integer(row["Edition"]) }
      else
        raise "Unexpected row content: #{row.to_s}"
      end
    end
    BatchPublish.new(edition_identifers, user_email).call
  else
    raise "No file found: #{filename}"
  end
end
