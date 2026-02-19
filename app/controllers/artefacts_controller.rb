class ArtefactsController < ApplicationController
  layout "design_system"
  before_action :require_govuk_editor

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

  helper_method :slug_prefix

private

  def artefact_params
    params.require(:artefact).permit(:name, :slug, :kind, :language)
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
