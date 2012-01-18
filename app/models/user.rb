class User
  include Mongoid::Document
  include GDS::SSO::User
  include WorkflowActor

  cache

  field :uid, :type => String
  field :email, :type => String
  field :version, :type => Integer
  field :name, :type => String

  scope :alphabetized, order_by(name: :asc)

  def self.find_by_uid(uid)
    first(conditions: {uid: uid})
  end

  def to_s
    name || ""
  end

  def gravatar_url(opts = {})
    opts.symbolize_keys!
    qs = opts.select { |k, v| k == :s }.collect { |k, v| "#{k}=#{Rack::Utils.escape(v)}" }.join("&")
    qs = "?" + qs unless qs == ""
    scheme_and_host = opts[:ssl] ? "https://secure.gravatar.com" : "http://www.gravatar.com"
    "#{scheme_and_host}/avatar/#{Digest::MD5.hexdigest(email.downcase)}#{qs}"
  end
end
