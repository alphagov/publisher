module PartedEdition  
  def whole_body
    self.parts.map {|i| %Q{\# #{i.title}\n\n#{i.body}} }.join("\n\n")
  end
end