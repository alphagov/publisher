class PanopticonAdapter
  cattr_accessor :endpoint
  attr_accessor :kind, :owning_app, :name
  
  def initialize(attributes = {})
    attributes.each { |k, v| send("#{k}=", v) }
  end
  
  def save
    attributes_to_send = {
      'slug[kind]' => self.kind,
      'slug[owning_app]' => self.owning_app,
      'slug[name]' => self.name
    }
    uri = URI.parse("#{self.class.endpoint}/slugs")
    res = Net::HTTP.post_form(uri, attributes_to_send)

    case res
    when Net::HTTPCreated
      return true
    when Net::HTTPNotAcceptable
      return false
    else
      Rails.logger.warn "Panopticon communications error: #{res.inspect}"
      return false
    end
  end
  
  def destroy
    n = Net::HTTP.start(self.class.endpoint)
    res = n.delete("/slugs/#{self.name}")
    return res.is_a?(Net::HTTPOK)
  end
  
  class <<self
    def find(slug)
      res = Net::HTTP.get("#{endpoint}/slugs/#{slug}")
      case res
      when Net::HTTPCreated
        JSON.parse(res.body)
      when Net::HTTPNotFound
        false
      else
        false
      end
    end
  end
end