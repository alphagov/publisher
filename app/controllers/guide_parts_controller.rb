# frozen_string_literal: true

class GuidePartsController < InheritedResources::Base
  belongs_to :edition
  layout "design_system"

  defaults resource_class: Part, collection_name: "parts", instance_name: "part"

  before_action do
    @edition = parent
  end
  before_action :setup_view_paths
  before_action do
    require_user_accessibility_to_edition(@edition)
  end
  before_action only: %i[new create edit update] do
    require_editor_permissions(@edition)
  end
  before_action only: %i[new create edit update] do
    require_editing_state(@edition)
  end

  def create
    @part = @edition.editionable.parts.build(permitted_parts_params.merge(order: @edition.editionable.parts.size))
    if @edition.save
      if params[:save] == "save and summary"
        flash[:success] = "New chapter added successfully."
        redirect_to edition_path(@edition)
      elsif params[:save] == "save"
        flash[:success] = "New chapter added successfully."
        redirect_to edit_edition_guide_part_path(@edition, @part)
      end
    else
      render "new"
    end
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    @edition.errors.add(:show, "Due to a service problem, the edition couldn't be updated")
    render "new"
  end

  def update
    @part = Part.find(params[:id])
    @part.assign_attributes(permitted_parts_params)

    if @part.save
      if params[:save] == "save and summary"
        flash[:success] = "Chapter updated successfully."
        redirect_to edition_path(@edition)
      elsif params[:save] == "save"
        flash[:success] = "Chapter updated successfully."
        redirect_to edit_edition_guide_part_path(@edition, @part)
      end
    else
      render "edit"
    end
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    @resource.errors.add(:show, "Due to a service problem, the edition couldn't be updated")
    render "edit"
  end

private

  def setup_view_paths
    setup_view_paths_for(@edition)
  end

  def permitted_parts_params
    params.require(:part).permit(part_type_params)
  end

  def part_type_params
    %i[
      body
      slug
      title
      id
    ]
  end

  def require_editing_state(edition)
    return if %w[published archived scheduled_for_publishing].exclude? edition.state

    flash[:danger] = "You are not allowed to perform this action in the current state."
    redirect_to edition_path(edition)
  end
end
