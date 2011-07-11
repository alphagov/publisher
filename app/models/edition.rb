class Edition
  include Mongoid::Document
  
  embedded_in :guide
  
  embeds_many :parts
  embeds_many :actions
  
  field :version_number, :type => Integer, :default => 1
  field :title, :type => String
  field :introduction, :type => String
  field :created_at, :type => DateTime, :default => lambda { Time.now }

  accepts_nested_attributes_for :parts

  def build_clone
    new_edition = self.guide.build_edition(self.title,self.introduction)
    new_edition.parts = self.parts.map {|p| p.dup }
    new_edition
  end
  
  def order_parts
    parts.each_with_index do |obj, i|
      obj.order = i + 1
    end
  end
  
  def new_action(user,type,comment)
    self.actions << Action.new(:requester_id=>user.id,:request_type=>type,:comment=>comment)
    self.guide.calculate_statuses
  end

  def latest_action
    actions.desc(:created_at).first
  end

end
