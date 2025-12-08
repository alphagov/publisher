# frozen_string_literal: true

class TaggingController < InheritedResources::Base
  layout "design_system"

  defaults resource_class: Edition, collection_name: "editions", instance_name: "resource"

  before_action :setup_view_paths
  before_action only: %i[
    breadcrumb_page
    remove_breadcrumb_page
    mainstream_browse_page
    related_content_page
    reorder_related_content_page
    organisations_page
  ] do
    require_editor_permissions
  end

  SERVICE_REQUEST_ERROR_MESSAGE = "Due to a service problem, the request could not be made"

  def breadcrumb_page
    @tagging_update_form_values = build_tagging_form_values_from_publishing_api
    @radio_groups = build_radio_groups_for_breadcrumb_page(@tagging_update_form_values)
    render "secondary_nav_tabs/tagging_breadcrumb_page"
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = SERVICE_REQUEST_ERROR_MESSAGE
    render "editions/show"
  end

  def update_breadcrumb
    update_tags(
      breadcrumb_update_params[:previous_version],
      "GOV.UK breadcrumbs updated",
    ) do |form_values|
      form_values.parent = breadcrumb_update_params[:parent]
    end
  end

  def remove_breadcrumb_page
    @tagging_update_form_values = build_tagging_form_values_from_publishing_api
    render "secondary_nav_tabs/tagging_remove_breadcrumb_page"
  end

  def remove_breadcrumb
    if breadcrumb_remove_params[:remove_parent] == "no"
      redirect_to tagging_edition_path
    elsif !breadcrumb_remove_params[:remove_parent]
      @tagging_update_form_values = build_tagging_form_values_from_publishing_api
      @resource.errors.add(:remove_parent, "Select an option")
      render "secondary_nav_tabs/tagging_remove_breadcrumb_page"
    else
      update_tags(
        breadcrumb_remove_params[:previous_version],
        "GOV.UK breadcrumb removed",
      ) do |form_values|
        form_values.parent = nil
      end
    end
  end

  def mainstream_browse_page
    @tagging_update_form_values = build_tagging_form_values_from_publishing_api
    @checkbox_groups = build_checkbox_groups_for_mainstream_browse_page(@tagging_update_form_values)
    render "secondary_nav_tabs/tagging_mainstream_browse_page"
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = SERVICE_REQUEST_ERROR_MESSAGE
    render "editions/show"
  end

  def related_content_page
    @tagging_update_form_values = build_tagging_form_values_from_publishing_api

    render "secondary_nav_tabs/tagging_related_content_page"
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = SERVICE_REQUEST_ERROR_MESSAGE
    render "editions/show"
  end

  def reorder_related_content_page
    @tagging_update_form_values = build_tagging_form_values_from_publishing_api

    render "secondary_nav_tabs/tagging_reorder_related_content_page"
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = SERVICE_REQUEST_ERROR_MESSAGE
    render "editions/show"
  end

  def organisations_page
    @tagging_update_form_values = build_tagging_form_values_from_publishing_api

    @linkables = Tagging::Linkables.new.organisations.map do |linkable|
      {
        text: linkable[0],
        value: linkable[1],
        selected: @tagging_update_form_values.organisations&.include?(linkable[1]),
      }
    end

    render "secondary_nav_tabs/tagging_organisations_page"
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = SERVICE_REQUEST_ERROR_MESSAGE
    render "editions/show"
  end

  def update_tagging
    success_message = case params[:tagging_tagging_update_form][:tagging_type]
                      when "related_content"
                        "Related content updated"
                      when "reorder_related_content"
                        "Related content order updated"
                      when "mainstream_browse_page"
                        "Mainstream browse pages updated"
                      when "organisations"
                        "Organisations updated"
                      else
                        "Tags have been updated!"
                      end

    create_tagging_update_form_values(tagging_update_params)

    if @tagging_update_form_values.valid?
      @tagging_update_form_values.publish!
      flash[:success] = success_message
      redirect_to tagging_edition_path
    else
      render "secondary_nav_tabs/tagging_related_content_page"
    end
  rescue GdsApi::HTTPConflict
    redirect_to tagging_edition_path,
                flash: {
                  danger: "Somebody changed the tags before you could. Your changes have not been saved.",
                }
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash[:danger] = SERVICE_REQUEST_ERROR_MESSAGE
    render "editions/show"
  end

protected

  def setup_view_paths
    setup_view_paths_for(resource)
  end

private

  def update_tags(previous_version, success_message, &update_form_values)
    raise "Must provide a block" unless block_given?

    @tagging_update_form_values = build_tagging_form_values_from_publishing_api
    @tagging_update_form_values.previous_version = previous_version
    update_form_values.call(@tagging_update_form_values)

    @tagging_update_form_values.publish!
    redirect_to tagging_edition_path,
                flash: { success: success_message }
  rescue GdsApi::HTTPConflict
    redirect_to tagging_edition_path,
                flash: {
                  danger: "Somebody changed the tags before you could. Your changes have not been saved.",
                }
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = SERVICE_REQUEST_ERROR_MESSAGE
    render "editions/show"
  end

  def build_tagging_form_values_from_publishing_api
    Tagging::TaggingUpdateForm.build_from_publishing_api(
      resource.artefact.content_id,
      resource.artefact.language,
    )
  end

  def build_radio_groups_for_breadcrumb_page(tagging_update_form_values)
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

  def build_checkbox_groups_for_mainstream_browse_page(tagging_update_form_values)
    Tagging::Linkables.new.mainstream_browse_pages.map do |k, v|
      {
        heading: k,
        items: v.map do |item|
          {
            label: item.first.split(" / ").last,
            value: item.last,
            checked: tagging_update_form_values.mainstream_browse_pages&.include?(item.last),
          }
        end,
      }
    end
  end

  def create_tagging_update_form_values(tagging_update_params)
    @tagging_update_form_values = Tagging::TaggingUpdateForm.build_from_submitted_form(tagging_update_params)
  end

  def breadcrumb_remove_params
    params.require(:tagging_tagging_update_form).permit(:previous_version, :remove_parent)
  end

  def breadcrumb_update_params
    params.require(:tagging_tagging_update_form).permit(:previous_version, parent: [])
  end

  def tagging_update_params
    update_params = params.require(:tagging_tagging_update_form).permit(
      :content_id,
      :previous_version,
      :tagging_type,
      parent: [],
      mainstream_browse_pages: [],
      organisations: [],
      ordered_related_items: [],
      ordered_related_items_destroy: [],
    ).to_h
    if params[:tagging_tagging_update_form][:tagging_type] == "reorder_related_content"
      update_params[:reordered_related_items] = params.permit(reordered_related_items: {})
                                                      .to_h[:reordered_related_items]
                                                      .sort_by(&:last).map { |url| url[0] }
    end
    update_params
  end
end
