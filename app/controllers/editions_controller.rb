require "edition_duplicator"
require "edition_progressor"

class EditionsController < InheritedResources::Base
  layout "design_system"

  defaults resource_class: Edition, collection_name: "editions", instance_name: "resource"
  before_action :setup_view_paths, except: %i[index new]

  def index
    redirect_to root_path
  end

  def show
    @linkables = Tagging::Linkables.new

    if @resource.is_a?(Parted)
      @ordered_parts = @resource.parts.in_order
    end

    if @resource.is_a?(Varianted)
      @ordered_variants = @resource.variants.in_order
    end

    @tagging_update = tagging_update_form
    @artefact = @resource.artefact
    render action: "show"
  end

  def new
    @publication = build_resource
    setup_view_paths_for(@publication)
  end

protected

  def permitted_params(subtype: nil)
    subtype = @resource.class.to_s.underscore.to_sym if subtype.nil?
    params.permit(edition: type_specific_params(subtype) + common_params)
  end

  def type_specific_params(subtype)
    case subtype
    when :guide_edition
      [
        :hide_chapter_navigation,
        { parts_attributes: %i[title body slug order id _destroy] },
      ]
    when :local_transaction_edition
      [
        :lgsl_code,
        :lgil_code,
        :introduction,
        :more_information,
        :need_to_know,
        { scotland_availability_attributes: %i[type alternative_url] },
        { wales_availability_attributes: %i[type alternative_url] },
        { northern_ireland_availability_attributes: %i[type alternative_url] },
      ]
    when :place_edition
      %i[
        place_type
        introduction
        more_information
        need_to_know
      ]
    when :simple_smart_answer_edition
      [
        :body,
        :start_button_text,
        { nodes_attributes: [
          :slug,
          :title,
          :body,
          :order,
          :kind,
          :id,
          :_destroy,
          { options_attributes: %i[label next_node id _destroy] },
        ] },
      ]
    when :transaction_edition
      [
        :introduction,
        :start_button_text,
        :will_continue_on,
        :link,
        :more_information,
        :alternate_methods,
        :need_to_know,
        { variants_attributes: %i[title slug introduction link more_information alternate_methods order id _destroy] },
      ]
    when :completed_transaction_edition
      %i[
        body
        promotion_choice
        promotion_choice_url
        promotion_choice_opt_in_url
        promotion_choice_opt_out_url
      ]
    else
      # answer_edition, help_page_edition
      [
        :body,
      ]
    end
  end

  def common_params
    %i[
      assigned_to_id
      reviewer
      panopticon_id
      slug
      change_note
      major_change
      title
      in_beta
      overview
    ]
  end

  def new_assignee
    assignee_id = (params[:edition] || {}).delete(:assigned_to_id)
    User.find(assignee_id) if assignee_id.present?
  end

  def update_assignment(edition, assignee)
    return if edition.assigned_to == assignee

    if !assignee
      current_user.unassign(edition)
    elsif assignee.has_editor_permissions?(resource)
      current_user.assign(edition, assignee)
    else
      flash[:danger] = "Chosen assignee does not have correct editor permissions."
    end
  end

  def setup_view_paths
    setup_view_paths_for(resource)
  end

private

  def tagging_update_form
    Tagging::TaggingUpdateForm.build_from_publishing_api(
      @resource.artefact.content_id,
      @resource.artefact.language,
    )
  end

  def tagging_update_form_params
    params[:tagging_tagging_update_form].permit(
      :content_id,
      :previous_version,
      :parent,
      mainstream_browse_pages: [],
      organisations: [],
      meets_user_needs: [],
      ordered_related_items: [],
    ).to_h
  end

  def setup_view_paths_for(publication)
    prepend_view_path "app/views/editions"
    prepend_view_path template_folder_for(publication)
  end
end
