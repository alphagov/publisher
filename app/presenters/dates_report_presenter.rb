class DatesReportPresenter < CSVPresenter
  def initialize(start_date, end_date)
    start_date = start_date.beginning_of_day
    end_date = end_date.end_of_day

    scope = Edition.any_of({ state: "published" }, state: "archived")
      .where(:updated_at.gte => start_date)
      .where(:created_at.lte => end_date)
      .order_by(created_at: 'asc')
      .select { |item|
        item.actions.select { |a|
          a.request_type == "publish" &&
            a.created_at >= start_date &&
            a.created_at <= end_date
        }.any?
      }
    super(scope)

    self.column_headings = [
      :created_at,
      :title,
      :url,
    ]
  end

private

  def build_csv(csv)
    csv << %w(created_at title url)
    scope.each do |item|
      item.actions.each do |action|
        csv << [
          action.created_at.to_s(:db),
          item.title,
          "#{Plek.current.website_root}/#{item.slug}",
        ] if action.request_type == "publish"
      end
    end
  end
end
