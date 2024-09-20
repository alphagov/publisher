require "edition_duplicator"
require "edition_progressor"

class EditionsController < InheritedResources::Base
  layout "design_system"

  defaults resource_class: Edition, collection_name: "editions", instance_name: "resource"
  before_action :setup_view_paths, except: %i[index]

  def index
    redirect_to root_path
  end

  def show
    @artefact = @resource.artefact
    render action: "show"
  end

  def metadata
    render action: "show"
  end

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
end
