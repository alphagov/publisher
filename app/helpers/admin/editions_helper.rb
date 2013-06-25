module Admin::EditionsHelper
  def format_content_diff( body )
    ContentDiffFormatter.new(body).to_html
  end
end
