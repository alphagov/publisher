module Admin::EditionsHelper
  def setup_association(object, associated, opts)
    associated = object.send(associated.to_s) if associated.is_a? Symbol
    associated = associated.is_a?(Array) ? associated : [associated] # preserve association proxy if this is one

    opts.symbolize_keys!

    (opts[:new] - associated.select(&:new_record?).length).times  { associated.build } if opts[:new] and object.new_record? == true
    if opts[:edit] and object.new_record? == false
      (opts[:edit] - associated.count).times { associated.build }
    elsif opts[:new_in_edit] and object.new_record? == false
      opts[:new_in_edit].times { associated.build }
    end
  end
end
