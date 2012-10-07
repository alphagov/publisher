require 'gds_api/panopticon'

class EditionSlugMigrator

  attr_reader :logger

  def initialize(logger = nil)
    @logger = logger || Logger.new(STDOUT)
  end

  def run
    logger.info "Migrating slugs for #{slugs.size} editions"
    slugs.each do |slug, new_slug|
      editions = Edition.where(slug: slug)
      raise "Edition not found with slug #{slug}" unless editions.any?

      count = editions.count
      editions.each do |edition|
        edition.update_attribute(:slug, new_slug)

        edition.register_with_panopticon if edition.published?
        edition.actions.create!(
          :request_type => Action::NOTE,
          :comment => "Edition moved from '#{slug}' to '#{new_slug}"
        )
      end

      logger.info "     #{slug} -> #{new_slug} (#{count} editions)"
    end
    logger.info "Sequence complete."
  end

  private
    def slugs
      @slugs ||= load_slugs
    end

    def load_slugs
      json = File.open(Rails.root.join('data','slugs_to_migrate.json')).read
      JSON.parse(json) || [ ]
    end

end
