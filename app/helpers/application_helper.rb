module ApplicationHelper
  # Set class on active navigation items
  def nav_link(text, link)
    recognized = Rails.application.routes.recognize_path(link)
    if recognized[:controller] == params[:controller] && recognized[:action] == params[:action]
      tag.li(class: "active") do
        link_to(text, link)
      end
    else
      tag.li do
        link_to(text, link)
      end
    end
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : "sortable"
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, permitted_params.merge(sort: column, direction:), class: css_class
  end

  def diff_html(version1, version2)
    content_blocks = ContentBlockTools::ContentBlockReference.find_all_in_document(version1)

    ref = content_blocks.first

    block = ContentBlockTools::ContentBlock.from_embed_code(ref.embed_code)

    block.render
  end

  def permitted_params
    params.permit(
      :user_filter,
      :list,
      :string_filter,
      :format_filter,
      :controller,
      :action,
      :direction,
    )
  end
end
