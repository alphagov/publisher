class Admin::AttachmentsController < Admin::BaseController
  # NOTE: bailing out of the inherited resources defaults as they would return a 422 error on
  #   upload :(
  #actions :create, :update, :destroy
  #defaults :resource_class => Attachment, :collection_name => "attachments", :instance_name => "attachment"

  respond_to :json

  # FIXME: below is all WIP
  def show
    @attachment = Attachment.find(params[:id])
    respond_to do |format|
      format.json { render json: @attachment }
    end
  end

  def create
    @attachment = Attachment.new params[:attachment]
    if @attachment.save
      render json: @attachment
    else
      render json: { errors: @attachment.errors.full_messages }
    end
  end


end
