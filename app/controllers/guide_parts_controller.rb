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
  before_action only: %i[new
                         create
                         edit
                         update
                         reorder
                         bulk_update_reorder
                         confirm_destroy
                         destroy] do
    require_editor_permissions(@edition)
  end
  before_action only: %i[new
                         create
                         edit
                         update
                         reorder
                         bulk_update_reorder
                         confirm_destroy
                         destroy] do
    require_editing_state(@edition)
  end
  before_action only: %i[reorder bulk_update_reorder] do
    require_multiple_parts(@edition)
  end

  def create
    @edition.order_parts
    @part = @edition.editionable.parts.build(permitted_parts_params.merge(order: @edition.editionable.parts.size + 1))
    if @edition.save
      UpdateWorker.perform_async(@edition.id.to_s)
      if params[:save] == "save and summary"
        flash[:success] = "New chapter added successfully."
        redirect_to edition_path(@edition)
      elsif params[:save] == "save"
        flash[:success] = "New chapter added successfully."
        if Flipflop.enabled?(:guide_chapter_accordion_interface)
          redirect_to edition_path(@edition)
        else
          redirect_to edit_edition_guide_part_path(@edition, @part)
        end
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
      UpdateWorker.perform_async(@edition.id.to_s)
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
    @edition.errors.add(:show, "Due to a service problem, the edition couldn't be updated")
    render "edit"
  end

  def reorder
    render "secondary_nav_tabs/guide_reorder_chapters_page"
  end

  def bulk_update_reorder
    chapters = params.permit(reordered_chapters: {}).to_h[:reordered_chapters]
    reorder_chapters(@edition, chapters)

    flash[:success] = "Chapter order updated"
    redirect_to edition_path(@edition)
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    @edition.errors.add(:show, "Due to a service problem, the chapter order couldn't be updated")
    redirect_to edition_path(@edition)
  end

  def confirm_destroy
    @part = Part.find(params[:id])
  end

  def destroy
    @part = Part.find(params[:id])
    if @part.destroy!
      UpdateWorker.perform_async(@edition.id.to_s)
      flash[:success] = "Chapter deleted successfully"
      redirect_to edition_path(@edition)
    else
      render "confirm_destroy"
    end
  rescue StandardError => e
    Rails.logger.error "Error #{e.class} #{e.message}"
    flash.now[:danger] = "Due to a service problem, the chapter couldn't be deleted"
    render "confirm_destroy"
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

  def require_multiple_parts(edition)
    return if edition.parts.count > 1

    flash[:danger] = "You can only reorder chapters when there are at least 2."
    redirect_to edition_path(edition)
  end

  def reorder_chapters(edition, chapters)
    chapters.each { |chapter_id, new_index| edition.parts.find(chapter_id).update(order: new_index.to_i) }
    UpdateWorker.perform_async(edition.id.to_s) if edition.save!
  end
end
