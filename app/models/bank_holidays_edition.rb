class BankHolidaysEdition < Edition
    field :year, type: Array
  
    # def create_draft_popular_links_from_last_record
    #   last_popular_links = PopularLinksEdition.last
    #   popular_links = PopularLinksEdition.new(title: last_popular_links.title, link_items: last_popular_links.link_items, version_number: last_popular_links.version_number.next)
    #   popular_links.save!
    #   popular_links
    # end
  
    GOVSPEAK_FIELDS = [:body].freeze

    def publish_latest
      save_draft if is_draft?
      Services.publishing_api.publish(content_id, update_type, locale:)
      publish
    end
  
    def save_draft
      UpdateService.call(self)
      save!
    end
  
    def content_id
      "58f79dbd-e57f-4ab2-ae96-96df5767d1b2".freeze
    end
  
    def update_type
      "major".freeze
    end
  
    def locale
      "en".freeze
    end
  
    def can_delete?
      is_draft?
    end
  
  private
  
    def is_draft?
      state == "draft"
    end
  end