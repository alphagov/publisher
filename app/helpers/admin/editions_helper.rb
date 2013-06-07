module Admin::EditionsHelper
  def format_content_diff( body )
    ContentDiffFormatter.new(body).to_html
  end

  # All guides should have at least one part
  # Those parts should be in the correct order
  def tidy_up_parts_before_editing(resource)
    resource.parts.build if resource.parts.empty?
    resource.parts.replace(resource.parts.sort_by(&:order))
  end
end
