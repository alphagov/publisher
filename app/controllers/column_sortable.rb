module ColumnSortable
  def self.included(base)
    # Expose sort_column and sort_direction for template access
    base.helper_method :sort_column, :sort_direction
  end

private

  def sort_column
    Edition.fields.keys.include?(params[:sort]) ? params[:sort] : 'updated_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
