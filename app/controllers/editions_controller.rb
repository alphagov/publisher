class EditionsController < InheritedResources::Base
  include TabbedNavHelper
  layout "design_system"

  defaults resource_class: Edition, collection_name: "editions", instance_name: "resource"
  before_action :setup_view_paths, except: %i[index]

  helper_method :locale_to_language

  def index
    redirect_to root_path
  end

  def show
    @artefact = @resource.artefact

    render action: "show"
  end

  alias_method :metadata, :show

  def history
    render action: "show"
  end

  def admin
    render action: "show"
  end

  def linking
    render action: "show"
  end

  def unpublish
    render action: "show"
  end

protected

  def setup_view_paths
    setup_view_paths_for(resource)
  end

private

  def setup_view_paths_for(publication)
    prepend_view_path "app/views/editions"
    prepend_view_path template_folder_for(publication)
  end

  def locale_to_language(locale)
    case locale
    when "en"
      "English"
    when "cy"
      "Welsh"
    else
      ""
    end
  end
end
