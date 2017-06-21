module PrerenderedEntity
  def create_or_update_by_slug!(attributes)
    find_or_initialize_by(
      slug: attributes.fetch(:slug)
    ).tap do |doc|
      doc.update_attributes!(attributes)
    end
  end

  def find_by_slug(slug)
    where(slug: slug).first # rubocop:disable Rails/FindBy
  end
end
