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
    @downtime = Downtime.new(params[:downtime])

    if @downtime.save
      flash[:success] = 'Successfully scheduled downtime'
      redirect_to edit_edition_downtime_path(@edition)
    else
      render :new
    end
  end

  def edit
    @downtime = Downtime.for(@edition.artefact)
  end

  def update
    @downtime = Downtime.for(@edition.artefact)

    if params['commit'] == 'Remove downtime'
      @downtime.destroy
      flash[:success] = 'Successfully removed downtime'
      redirect_to downtimes_path
      return
    end

    if @downtime.update_attributes(params[:downtime])
      flash[:success] = 'Successfully updated downtime'
      redirect_to downtimes_path
    else
      render :edit
    end
  end

  private

  def load_edition
    @edition = Edition.find(params[:edition_id])
  end

  def process_params
    squash_multiparameter_datetime_attributes(params[:downtime], ['start_time', 'end_time'])
  end
end
