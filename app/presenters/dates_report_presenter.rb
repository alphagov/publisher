class DatesReportPresenter < CSVPresenter
  def initialize(start_date, end_date)
    start_date = start_date.beginning_of_day
    end_date = end_date.end_of_day
    scope = Edition.where(state: "published").or(Edition.where(state: "archived"))
    scope =   scope.where("updated_at > ?", start_date)
    scope =   scope.where("created_at < ?", end_date)
    scope = scope.order(created_at: :asc)
    scope = rename_this(scope, start_date, end_date)
    # scope.select do |item|
    #   item.actions.select { |a|
    #       a.request_type == "publish" &&
    #         a.created_at >= start_date &&
    #         a.created_at <= end_date
    #     }.any?
    #   end
    super(scope)

    self.column_headings = %i[
      created_at
      title
      url
    ]
  end

private

  def rename_this(scope, start_date, end_date)
    scope.each do |item|
      valid_action = false
      item.actions.each do |action|
        if action.request_type == "publish" && action.created_at >= start_date && action.created_at <= end_date
          valid_action = true
        end
      end
      unless valid_action
        scope = scope.reject { |x| x.id == item.id }
      end
    end
    scope
  end

  def build_csv(csv)
    csv << %w[created_at title url]
    scope.each do |item|
      item.actions.each do |action|
        next unless action.request_type == "publish"

        csv << [
          action.created_at.to_fs(:db),
          item.title,
          "#{Plek.website_root}/#{item.slug}",
        ]
      end
    end
  end
end
