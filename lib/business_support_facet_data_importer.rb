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
    invalid = []

    # Only modify unarchived editions
    editions = BusinessSupportEdition.excludes(state: 'archived')

    editions.each do |bse|

      # Ignore anything that doesn't have a published edition in the series
      unless bse.artefact.archived? or bse.published_edition.nil?
        # Find the corresponding Imminence scheme data
        imminence_scheme = imminence_results.find { |bs|
          bs['business_support_identifier'] == bse.business_support_identifier
        }

        scheme_details = "slug: #{bse.slug}, id: #{bse.business_support_identifier}, state: #{bse.state}"

        unless (saved + unsaved).include?(scheme_details)
          # Apply facet values from Imminence data to this Edition
          if imminence_scheme
            import_attrs.each do |attr|
              attrval = imminence_scheme[attr]
              bse.send("#{attr}=", attrval) if attrval
            end
            saved << scheme_details if bse.save!(validate: false)
          else
            unsaved << scheme_details
          end
        end
      else
        # Having an archived artefact or no published editions.
        invalid << bse.slug
      end
    end

    puts "Processed #{editions.size} BusinessSupportEditions."
    puts "#{saved.size} successfully updated. #{unsaved.size} didn't match Imminence data. #{invalid.size} were inelligible for update."
    puts "Updated: #{saved.sort.join(', ')}"
    puts "Skipped: #{unsaved.sort.join(', ')}"
  end
end
