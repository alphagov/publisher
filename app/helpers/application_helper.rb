module ApplicationHelper
  # Set class on active navigation items
  def nav_link(text, link)
    recognized = Rails.application.routes.recognize_path(link)
    if recognized[:controller] == params[:controller] && recognized[:action] == params[:action]
      content_tag(:li, class: "active") do
        link_to(text, link)
      end
    else
      content_tag(:li) do
        link_to(text, link)
      end
    end
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : "sortable"
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, permitted_params.merge(sort: column, direction: direction), class: css_class
  end

  def diff_html(version_1, version_2)
    Diffy::Diff.new(version_1, version_2, allow_empty_diff: false).to_s(:html).html_safe
  end

  def permitted_params
    params.permit(
      :user_filter,
      :list,
      :string_filter,
      :format_filter,
      :controller,
      :action,
      :direction
    )
  end
end
