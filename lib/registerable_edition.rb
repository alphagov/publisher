class RegisterableEdition
  extend Forwardable

  def_delegators :@edition, :slug, :title, :indexable_content

  def initialize(edition)
    @edition = edition
  end

  def live
    true
  end

  def description
    @edition.overview
  end
end
