class DowntimesController < ApplicationController
  before_action :require_govuk_editor
  before_action :load_edition, except: [:index]

  layout "design_system"

  def index
    @transactions = Edition.where(editionable_type: "TransactionEdition", state: "published").order(%i[title])
  end

  def new
    @downtime = Downtime.new(artefact_id: @edition.artefact.id)
  end

  def create
    datetime_validation_errors = datetime_validation_errors(downtime_params, %w[start_time end_time])
    begin
      @downtime = Downtime.new(downtime_params)

      if datetime_validation_errors.empty? && @downtime.save
        DowntimeScheduler.schedule_publish_and_expiry(@downtime)
        flash[:success] = "#{@edition.title} downtime message scheduled (from #{view_context.downtime_datetime(@downtime)})".html_safe
        redirect_to downtimes_path
      else
        @downtime.valid? # Make sure the model validations have run
        add_errors(datetime_validation_errors)
        render :new
      end
    rescue ActiveRecord::MultiparameterAssignmentErrors
      @downtime = Downtime.new(artefact_id: downtime_params[:artefact_id])
      add_errors(datetime_validation_errors)
      render :new
    end
  end

  def add_errors(datetime_validation_errors)
    datetime_validation_errors.each do |name, message|
      # Remove any default messages for this field added by the model validation
      @downtime.errors.delete(name)
      @downtime.errors.add(name, message)
    end
  end

  def edit
    @downtime = Downtime.for(@edition.artefact)
  end

  def update
    @downtime = Downtime.for(@edition.artefact)

    if params[:downtime]
      datetime_validation_errors = datetime_validation_errors(downtime_params, %w[start_time end_time])
      if datetime_validation_errors.empty? && @downtime.update(downtime_params)
        DowntimeScheduler.schedule_publish_and_expiry(@downtime)
        flash[:success] = "#{@edition.title} downtime message re-scheduled (from #{view_context.downtime_datetime(@downtime)})".html_safe
        redirect_to downtimes_path
      else
        @downtime.valid? # Make sure the model validations have run
        datetime_validation_errors.each do |name, message|
          # Remove any default messages for this field added by the model validation
          @downtime.errors.delete(name)
          @downtime.errors.add(name, message)
        end
        render :edit
      end
    else
      DowntimeRemover.destroy_immediately(@downtime)
      flash[:success] = "#{@edition.title} downtime message cancelled".html_safe
      redirect_to downtimes_path
    end
  end

  def destroy
    @downtime = Downtime.for(@edition.artefact)
    render :delete
  end

private

  def downtime_params
    params[:downtime].permit(%w[
      artefact_id
      message
      end_time
      start_time
    ])
  end

  def load_edition
    @edition = Edition.find(params[:edition_id])
  end

  def edition_link
    view_context.link_to(@edition.title, edit_edition_downtime_path(@edition), class: "link-inherit bold")
  end

  def datetime_validation_errors(params, attribute_names = [])
    errors = {}
    attribute_names.each do |name|
      year, month, day, hour, minute = params.select { |k, _| k.include? name }.to_h.sort.map { |_, v| v }
      unless year.match?(/^\d{4}$/) && month.match?(/^\d{1,2}$/) && day.match?(/^\d{1,2}$/) \
        && hour.match?(/^\d{1,2}$/) && minute.match?(/^\d{1,2}$/)

        errors[name] = "format is invalid"
      end
      begin
        Time.zone.local(year.to_i, month.to_i, day.to_i, hour.to_i, minute.to_i)
      rescue ArgumentError
        errors[name] = "format is invalid"
      end
    end
    errors
  end
end
