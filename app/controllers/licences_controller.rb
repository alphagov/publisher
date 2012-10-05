class LicencesController < ApplicationController
  respond_to :json

  def index
    licence_ids = (params[:ids] || '').split(',')
    @licences = LicenceEdition.published.in(:licence_identifier => licence_ids)
    respond_with @licences.map {|l| l.as_json(:only => [:slug, :title, :licence_identifier, :licence_short_description]) }
  end
end
