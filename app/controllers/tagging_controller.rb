# frozen_string_literal: true

class TaggingController < InheritedResources::Base
  layout "design_system"

  defaults resource_class: Edition, collection_name: "editions", instance_name: "resource"

  before_action :setup_view_paths
  before_action only: %i[tagging_breadcrumb_page] do
    require_editor_permissions
  end

  SERVICE_REQUEST_ERROR_MESSAGE = "Due to a service problem, the request could not be made"

  def tagging_breadcrumb_page
    populate_tagging_form_values_from_publishing_api
    @radio_groups = build_radio_groups_for_tagging_breadcrumb_page(@tagging_update_form_values)
    render "secondary_nav_tabs/tagging_breadcrumb_page"
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = SERVICE_REQUEST_ERROR_MESSAGE
    render "editions/show"
  end

protected

  def setup_view_paths
    setup_view_paths_for(resource)
  end

private

  def populate_tagging_form_values_from_publishing_api
    @tagging_update_form_values = Tagging::TaggingUpdateForm.build_from_publishing_api(
      resource.artefact.content_id,
      resource.artefact.language,
    )
  end

  def build_radio_groups_for_tagging_breadcrumb_page(tagging_update_form_values)
    Tagging::Linkables.new.mainstream_browse_pages.map do |k, v|
      {
        heading: k,
        items: v.map do |item|
          {
            text: item.first.split(" / ").last,
            value: item.last,
            checked: tagging_update_form_values.parent&.include?(item.last),
          }
        end,
      }
    end
  end
end
