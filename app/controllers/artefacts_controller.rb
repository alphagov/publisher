class ArtefactsController < ApplicationController
  layout "design_system"
  before_action :require_govuk_editor, except: :update
  before_action only: %i[update] do
    # In Bootstrap, it is possible to attempt to update the Metadata as a non govuk_editor.
    # This stops such an attempt from kicking all the way back to the root path
    # TODO: Remove this and the except: clause above once SimpleSmartAnswerEdition is migrated to Design System
    next if current_user.govuk_editor?

    flash[:danger] = "You do not have permissions to update this page"
    artefact = Artefact.find(params[:id])
    redirect_to metadata_edition_path(artefact.latest_edition)
  end

  def new
    @artefact = Artefact.new
  end

  def content_details
    if params.dig(:artefact, :kind).blank?
      @artefact = Artefact.new
      @artefact.errors.add(:kind, "Select a content type")
      render :new
      return
    end

    @artefact = Artefact.new(kind: artefact_params[:kind])
  end

  def create
    @artefact = Artefact.new({ content_id: SecureRandom.uuid, owning_app: "publisher" })
    user_slug_value = artefact_params[:slug]

    if create_artefact_and_edition
      redirect_to publication_path(@artefact)
    else
      @artefact.slug = user_slug_value
      @artefact.errors.merge!(local_transaction_edition_errors) if local_transaction_edition?
      render "content_details"
    end
  end

  def update
    @artefact = Artefact.find(updatable_params[:id])
    if @artefact.update_as(current_user, updatable_params)
      UpdateWorker.perform_async(@artefact.latest_edition_id)
      flash[:success] = "Metadata has successfully updated".html_safe
    else
      flash[:danger] = @artefact.errors.full_messages.join("\n")
    end

    redirect_to metadata_artefact_path(@artefact)
  end

  helper_method :slug_prefix

private

  def metadata_artefact_path(artefact)
    edition = Edition.where(panopticon_id: artefact.id).order(version_number: :desc).first
    metadata_edition_path(edition)
  end

  def artefact_params
    params.require(:artefact).permit(:name, :slug, :kind, :language)
  end

  def updatable_params
    params.require(:artefact).permit(:id, :slug, :language)
  end

  def local_transaction_edition_params
    return {} unless local_transaction_edition?

    params.require(:local_transaction_edition).permit(:lgsl_code, :lgil_code)
  end

  def slug_prefix
    case @artefact.kind
    when "help_page"
      "help/"
    when "completed_transaction"
      "done/"
    else
      "/"
    end
  end

  def slug_with_prefix(artefact_params)
    return if artefact_params[:slug].blank?

    case artefact_params[:kind]
    when "help_page"
      "help/#{artefact_params[:slug]}"
    when "completed_transaction"
      "done/#{artefact_params[:slug]}"
    else
      artefact_params[:slug]
    end
  end

  def create_artefact_and_edition
    ActiveRecord::Base.transaction do
      if @artefact.update_as(current_user, artefact_params.merge({ slug: slug_with_prefix(artefact_params) })) && create_edition.persisted?
        return true
      else
        raise ActiveRecord::Rollback
      end
    end

    false
  end

  def create_edition
    current_user.create_edition(
      @artefact.kind.to_sym,
      panopticon_id: @artefact.id,
      slug: @artefact.slug,
      title: @artefact.name,
      assigned_to_id: current_user.id,
      **local_transaction_edition_params,
    )
  end

  def local_transaction_edition?
    artefact_params[:kind] == "local_transaction"
  end

  def local_transaction_edition_errors
    return unless local_transaction_edition?

    @local_transaction_edition ||= LocalTransactionEdition.new(local_transaction_edition_params)
    @local_transaction_edition.validate
    @local_transaction_edition.errors
  end
end
