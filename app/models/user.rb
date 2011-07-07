class User
  include Mongoid::Document
  include GDS::SSO::User
  
  field  :uid, :type => String
  field  :email, :type => String
  field  :version, :type => Integer
  field  :name, :type => String
  
  def self.find_by_uid(uid)
    first(conditions: {uid: uid})
  end
  
end