module TopicChanges
  class Processor
    def initialize(rows, logger = nil)
      @rows = rows
      @logger = logger || Rails.logger
    end

    def run
      logger.info "Rows: #{rows.size}"

      rows.each do |row|
        process_row(row)
      end
    end

  private

    attr_reader :rows, :logger, :republish

    def process_row(row)
      logger.info "#{row['slug']}:"

      unless row['slug'].present?
        logger.warn 'Skipping row: no slug provided'
        return
      end

      editions = find_non_archived_editions(row['slug'])
      unless editions.any?
        logger.warn "No editions found with slug '#{row['slug']}'."
        return
      end

      editions.each do |edition|
        process_edition(edition, row)
      end

      logger.info "All editions updated"

      republish_slug(row['slug'])
    end

    def process_edition(edition, row)
      logger.info "Edition ##{edition.version_number}:"

      if row['add_topic'].present? && row['remove_topic'].present?
        replace_topic(
          edition,
          row['add_topic'],
          row['remove_topic']
        )
      elsif row['remove_topic'].present?
        remove_topic(
          edition,
          row['remove_topic']
        )
      end
    end

    def replace_topic(edition, topic_to_add, topic_to_remove)
      logger.info "Attempting to replace topic '#{topic_to_remove}' with '#{topic_to_add}'"

      if edition.additional_topics.include?(topic_to_remove)
        logger.info "Found topic in additional_topics attribute"

        # By using a map instead of specific addition or subtraction from the
        # array, we can maintain the same position of the topic id.
        #
        edition.additional_topics = edition.additional_topics.map {|topic_id|
          topic_id == topic_to_remove ? topic_to_add : topic_id
        }
      end

      if edition.primary_topic == topic_to_remove
        logger.info "Found topic in primary_topic attribute"

        edition.primary_topic = topic_to_add
      end

      logger.info "Saving edition"
      edition.save!(validate: false)
    end

    def remove_topic(edition, topic_to_remove)
      logger.info "Attempting to remove topic '#{topic_to_remove}'"

      if edition.additional_topics.include?(topic_to_remove)
        logger.info "Found topic in additional_topics attribute"

        edition.additional_topics = edition.additional_topics - [ topic_to_remove ]
      end

      if edition.primary_topic == topic_to_remove
        logger.info "Found topic in primary_topic attribute"

        edition.primary_topic = nil
      end

      logger.info "Saving edition"
      edition.save!(validate: false)
    end

    def republish_slug(slug)
      logger.info "Republishing"

      registerer = PublishedSlugRegisterer.new(logger, [slug])
      registerer.run
    end

    def find_non_archived_editions(slug)
      Edition.where(:slug => slug, :state.ne => 'archived')
    end

  end
end
