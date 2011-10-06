class PublicationMetadata
  module HTMLGenerator
    def html
      buffer = StringIO.new
      builder = Builder::XmlMarkup.new :target => buffer
      yield builder
      buffer.rewind
      buffer.string.html_safe
    end
    private :html
  end

  class AudienceList
    include HTMLGenerator
    initialize_with :audiences

    def to_html
      html do |html|
        html.text! audiences.map { |a| a['name'] }.sort.join ', '
      end
    end
  end

  class RelatedItemList
    include HTMLGenerator
    initialize_with :related_items

    def to_html
      html do |html|
        html.text! related_items.map { |i| i['artefact']['name'] }.sort.join ', '
      end
    end
  end

  include HTMLGenerator

  initialize_with :publication

  def to_html
    html do |metadata|
      metadata.dl do |dl|
        attributes.each_pair do |name, value|
          presenter_name = name.classify
          presenter_name += 'List' if value.kind_of? Array
          if self.class.const_defined? presenter_name
            presenter = self.class.const_get presenter_name
            instance = presenter.new value
            value = instance.to_html
          end
          next if value.to_s.blank?
          dl.dt { |term| term.text! name.humanize }
          dl.dd { |definition| definition.text! value.to_s }
        end
      end
    end
  end

  def apply_to publication
    attributes = load_attributes
    publication.name = attributes['name']
    publication.slug = attributes['slug']
    publication.tags = attributes['tags']

    if attributes['audiences'].present?
      publication.audiences = attributes['audiences'].map { |a| a['name'] }
    end
    publication.section = attributes['section']
    publication.department = attributes['department']

    if attributes['related_items'].present?
      slugs = attributes['related_items'].map do |i|
        a = i['artefact']
        [ i['sort_key'], a['slug'], a['name'], a['kind'] ]
      end
      related_items = StringIO.new
      html = Builder::XmlMarkup.new :target => related_items
      slugs.sort_by { |order, slug, name, format| order }.each do |order, slug, name, format|
        related_item_class = [ format, 'related_item' ].join ' '
        html.li class: format do |item|
          item.a href: '/' + slug do |a|
            a.text! name
          end
        end
      end
      related_items.rewind
      publication.related_items = related_items.string
    end
  end

  def load_attributes
    data = JSON.parse open(uri).read
    data.except('updated_at', 'created_at', 'id', 'owning_app', 'kind', 'active')
  end
  
  def need_id
    attributes['need_id']
  end

  def attributes
    load_attributes
  rescue OpenURI::HTTPError
    {}
  end
  private :attributes

  def uri
    publication.panopticon_uri + '.js'
  end
  private :uri
end
