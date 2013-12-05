require 'open-uri'

class BusinessSupportFacetDataImporter
  def self.run
    endpoint = Plek.new.find('imminence')
    # Query Imminence for all schemes and cache this data
    raw = ''
    open("#{endpoint}/business_support_schemes.json") do |f|
      raw = f.read
    end
    imminence_data = JSON.parse(raw)
    imminence_results = imminence_data["results"]

    # Iterate published BusinessSupportEditions finding corresponding Imminence record in cache
    import_attrs = ["priority", "business_sizes", "locations",
                    "sectors", "stages", "support_types"]

    saved = []
    unsaved = []
    # Only modify unarchived editions
    editions = BusinessSupportEdition.excludes(state: 'archived')

    editions.each do |bse|

      # Ignore anything that doesn't have a published edition in the series
      unless bse.published_edition.nil?

        # Find the corresponding Imminence scheme data
        imminence_scheme = imminence_results.find { |bs|
          bs['business_support_identifier'] == bse.business_support_identifier
        }

        # Apply facet values from Imminence data to this Edition
        if imminence_scheme
          import_attrs.each do |attr|
            attrval = imminence_scheme[attr]
            bse.send("#{attr}=", attrval) if attrval
          end
          saved << bse.slug if bse.save!(validate: false)
        else
          unsaved << "(#{bse.business_support_identifier}) #{bse.slug}"
        end
      end
    end

    puts "Processed #{editions.size} BusinessSupportEditions."
    puts "#{saved.size} successfully updated. #{unsaved.size} didn't match Imminence data."
    puts "Updated: #{saved.join(', ')}"
    puts "Skipped: #{unsaved.join(', ')}"
  end
end
