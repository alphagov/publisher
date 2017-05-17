desc "Export Local Transactions' slugs, names, LGSL and LGIL codes as CSV"

task export_local_transactions: :environment do
  require "csv"

  csv_string = CSV.generate do |csv|
    csv << %w(slug lgsl lgil title state)

    Edition.where(_type: "LocalTransactionEdition").each do |lte|
      csv << [lte.slug, lte.lgsl_code, lte.lgil_code, lte.title, lte.state]
    end
  end

  puts csv_string
end
