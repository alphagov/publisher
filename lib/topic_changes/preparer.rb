require 'csv'

module TopicChanges
  class Preparer
    def initialize(source_topic_id, destination_topic_id)
      @source_topic_id = source_topic_id
      @destination_topic_id = destination_topic_id
    end

    def build_csv
      CSV.generate do |csv|
        csv << header_row

        slugs.each do |slug|
          csv << row_for_slug(slug)
        end
      end
    end

  private

    attr_reader :source_topic_id, :destination_topic_id

    def row_for_slug(slug)
      [slug, source_topic_id, destination_topic_id]
    end

    def header_row
      ['slug', 'remove_topic', 'add_topic']
    end

    def slugs
      tagged_editions.map(&:slug)
    end

    def tagged_editions
      Edition.any_of(
        { :primary_topic => source_topic_id },
        { :additional_topics.in => [ source_topic_id ] }
      )
    end

  end
end
