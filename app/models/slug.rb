class Slug
  attr_accessor :raw, :authority
  private :raw=, :raw, :authority=, :authority

  def initialize raw, authority = PANOPTICON_HOST
    self.raw = raw.to_s
    self.authority = authority.to_s
  end

  def uri
    URI.parse authority.to_s + '/slugs/' + raw.to_s
  end

  def exists?
    # TODO: We don't really care about the entity body here, just the status code.
    # Use a HEAD request.
    res = Net::HTTP.get_response uri

    case res
    when Net::HTTPOK
      return true
    when Net::HTTPNotFound
      return false
    else
      Rails.logger.warn "Panopticon communications error: #{res.inspect}"
      return true # Assume it exists unless we're told it definitely doesn't
    end
  end

  def to_s
    raw
  end
end
