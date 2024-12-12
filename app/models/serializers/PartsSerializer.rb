require 'json'

class PartsSerializer
  def self.dump(parts)
    parts.to_json
  end

  def self.load(json_array)
    return [] if json_array.nil? || json_array.empty?

    JSON.parse(json_array).map do |obj|
      Part.new(order: obj['order'], title: obj['title'], body: obj['body'], slug: obj['slug'], created_at: obj['created_at'])
    end
  end
end
