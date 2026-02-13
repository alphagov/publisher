module Api
  class FactCheckResponseController < Api::BaseController
    def process_response
      if !request_params[:accepted] && !request_params[:message]
        render json: {errors: "If a fact check is rejected, a comment must be provided explaining why"}, status: :bad_request
      end

      edition = Edition.find(request_params['source_id'])

      if User.new.progress(edition,
                           request_type: :receive_fact_check,
                           comment: comment,
                           requester_name: request_params['responder_name'],)
        render json: { id: edition.id }, status: :success
      else
        render json: { errors: edition.errors.full_messages }, status: :bad_request
      end
    end

    private

    def comment
      request_params.fetch(:message, "This fact check has been accepted.")
    end

    def request_params
      params.require(:source_id, :responder_name, :accepted)
      params.permit(
        :source_id, # edition_id
        :responder_name,
        :accepted,
        :message, # optional if accepted == true
        )
    end
  end
end
