class RelatedItemsAreAnArrayOfSlugs < Mongoid::Migration
  class LegacyRelatedItemField
    attr_accessor :raw_text
    private :raw_text=, :raw_text
    def initialize raw_text
      self.raw_text = raw_text
    end

    def doc
      Nokogiri::XML raw_text
    end

    def each
      items = doc.css "li"
      items.to_a.each do |li|
	publication_type = li['class'].to_s.strip
	slug = li.css("a").to_a[0]['href'].to_s.strip
	name = li.css("a").to_a[0].text.to_s.strip

        if slug == '#' || slug.blank?
          slug = SlugGenerator.new(name).execute
        end
	item = OpenStruct.new :publication_type => publication_type,
	  :slug => slug, :name => name
	def item.exists?
	  Slug.new(self.slug).exists?
	end
	def item.create_for user
          unless user.respond_to? "create_#{self.publication_type}"
            self.name += " (#{publication_type})"
            self.publication_type = "answer"
          end
	  new_pub = user.send "create_#{self.publication_type}", :name => self.name, :slug => self.slug
          new_pub.save!
	end
        def item.to_s
          [ publication_type, name, slug ].join ' '
        end

	yield item
      end
    end

    def migrate_to publication
      publication.related_items = [] unless publication.related_items.kind_of? Array

      each do |item|
        if !item.exists?
          item.create_for publication.editions.last.created_by
        end
        publication.related_items << item.slug
      end

      publication.save!
    end
  end

  def self.up
    publications = Publication.where {}
    publications.select! { |pub| pub.related_items.present? }
    publications.each do |pub|
      if pub.related_items.kind_of? String
        related_items = LegacyRelatedItemField.new pub.related_items
        related_items.migrate_to pub
      end
    end
  end

  def self.down
  end
end
