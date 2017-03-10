class DowntimesController < ApplicationController
  before_filter :load_edition, except: [:index]
  before_filter :process_params, only: [:create, :update]

  def index
    @transactions = TransactionEdition.published.order_by([:title, :asc])
  end

  def new
    @downtime = Downtime.new(artefact: @edition.artefact)
  end

  def create
    @downtime = Downtime.new(downtime_params)
    if @downtime.save
      DowntimeScheduler.schedule_publish_and_expiry(@downtime)
      flash[:success] = "#{edition_link} downtime message scheduled (from #{view_context.downtime_datetime(@downtime)})".html_safe
      redirect_to downtimes_path
    else
      render :new
    end
  end

  def edit
    @downtime = Downtime.for(@edition.artefact)
  end

  def update
    @downtime = Downtime.for(@edition.artefact)

    if params['commit'] == 'Cancel downtime'
      DowntimeRemover.destroy_immediately(@downtime)
      flash[:success] = "#{edition_link} downtime message cancelled".html_safe
      redirect_to downtimes_path
    elsif @downtime.update_attributes(downtime_params)
      DowntimeScheduler.schedule_publish_and_expiry(@downtime)
      flash[:success] = "#{edition_link} downtime message re-scheduled (from #{view_context.downtime_datetime(@downtime)})".html_safe
      redirect_to downtimes_path
    else
      render :edit
    end
  end

  private

  def downtime_params
    params[:downtime].permit(:message, :artefact_id, :start_time, :end_time)
  end

  def load_edition
    @edition = Edition.find(params[:edition_id])
  end

  def process_params
    squash_multiparameter_datetime_attributes(params[:downtime], ['start_time', 'end_time'])
  end

  def edition_link
    view_context.link_to(@edition.title, edit_edition_downtime_path(@edition), class: 'link-inherit bold')
  end
end
