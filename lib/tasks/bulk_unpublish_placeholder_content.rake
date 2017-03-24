require 'csv'

module TheUnpublisher
module_function

  def gone(row)
    Services.publishing_api.unpublish(
      row['CONTENT_ID'],
      locale: row['LOCALE'] || 'en',
      type: 'gone',
      discard_drafts: true
    )
  end

  def vanish(row)
    Services.publishing_api.unpublish(
      row['CONTENT_ID'],
      locale: row['LOCALE'] || 'en',
      type: 'vanish',
      discard_drafts: true
    )
  end
end

task bulk_unpublish_placeholder_content: :environment do
  filename = File.join(Rails.root, 'data', 'placeholders.csv')
  redirect_to_own_url = [
    "/broadband-connection-voucher-scheme-newport",
    "/family-separation-support"
  ]

  CSV.read(filename, headers: true).each do |row|
    if row['404 (NOT FOUND)']
      TheUnpublisher.vanish(row)
      puts "✅ #{row['BASE_PATH']}"
    elsif redirect_to_own_url.include? row['BASE_PATH']
      TheUnpublisher.gone(row)
      puts "✅ #{row['BASE_PATH']}"
    end
  end
end
