class SlugGenerator
  attr_accessor :text
  private :text=, :text

  def initialize text
    self.text = text
  end

  def execute
    result = text.dup
    result.strip!
    result.gsub! /[^a-zA-Z0-9]+/, '-'
    result.gsub! /\s+/, '-'
    result.gsub! /^-+|-+$/, ''
    result.downcase!
    result
  end
end
