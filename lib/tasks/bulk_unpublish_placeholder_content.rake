require 'csv'

module TheUnpublisher
module_function

  def unpublish_with_exact_redirect(row)
    Services.publishing_api.unpublish(
      row['CONTENT_ID'],
      locale: row['LOCALE'] || 'en',
      type: 'redirect',
      alternative_path: row['REDIRECT'],
      discard_drafts: true
    )
  end

  def unpublish_wth_prefix_redirect(row)
    Services.publishing_api.unpublish(
      row['CONTENT_ID'],
      locale: row['LOCALE'] || 'en',
      type: 'redirect',
      redirects: [
        {
          path: row['BASE_PATH'],
          type: 'prefix',
          destination: row['REDIRECT']
        }
      ],
      discard_drafts: true
    )
  end

  def unpublish_without_redirect(row)
    Services.publishing_api.unpublish(
      row['CONTENT_ID'],
      locale: row['LOCALE'] || 'en',
      type: 'gone',
      discard_drafts: true
    )
  end
end

task bulk_unpublish_placeholder_content: :environment do
  filename = File.join(Rails.root, 'data', 'placeholders.csv')
  CSV.read(filename, headers: true).each do |row|
    begin
      if row['PROCESSED']
        puts row['PROCESSED']
      elsif row['REDIRECT']
        if 'exact' == row['REDIRECT_TYPE']
          TheUnpublisher.unpublish_with_exact_redirect(row)
          puts '✅'
        elsif 'prefix' == row['REDIRECT_TYPE']
          TheUnpublisher.unpublish_wth_prefix_redirect(row)
          puts '✅'
        else
          puts '❌'
        end
      elsif row['410 (GONE)']
        TheUnpublisher.unpublish_without_redirect(row)
        puts '✅'
      elsif row['404 (NOT FOUND)']
        puts '🕵'
      else
        puts '🆘'
      end
    rescue
      puts '😱'
    end
  end
end
