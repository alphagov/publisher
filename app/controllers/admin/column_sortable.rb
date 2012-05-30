module Admin::ColumnSortable

  # Override these in the including controller if you want a different ordering
  @@default_sort_column = "updated_at"
  @@default_sort_direction = "desc"

  def self.included(base)
    # Expose sort_column and sort_direction for template access
    base.helper_method :sort_column, :sort_direction
  end

private
  def sort_column
    WholeEdition.fields.keys.include?(params[:sort]) ? params[:sort] : @@default_sort_column
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : @@default_sort_direction
  end

end