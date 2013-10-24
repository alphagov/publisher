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
      format.json { render json: @attachment.as_json(methods: [:file_url, *ATTACHMENT_METADATA_FIELDS.map { |m| "file_#{m}"}]) }
    end
  end

  def create
    @attachment = Attachment.new
    @attachment.file = params[:attachment][:file]
    if @attachment.save
      render json: @attachment.as_json(methods: [:file_url, *ATTACHMENT_METADATA_FIELDS.map { |m| "file_#{m}"}])
    else
      render json: { errors: @attachment.errors.full_messages }
    end
  end

  def update
    @attachment = Attachment.find(params[:id])
    params[:attachment].each do |metadata_field, value|
      @attachment.send "#{metadata_field}=", value
    end

    if @attachment.save
      render json: @attachment.as_json(methods: [:file_url, *ATTACHMENT_METADATA_FIELDS.map { |m| "file_#{m}"}])
    else
      render json: { errors: @attachment.errors.full_mesasges }
    end
  end

end
