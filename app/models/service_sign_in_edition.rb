class ServiceSignInEdition
  include Mongoid::Document
  include Mongoid::Timestamps
  include RecordableActions
  include BaseHelper

  field :slug, type: String
  field :content_item, type: Hash


end
