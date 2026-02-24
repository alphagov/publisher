module Api
  class FactCheckResponseController < Api::BaseController
    def process_response
      # Temporarily locking this down to local running and Integration environment while FCM is in development
      unless Rails.env.local? || Rails.env.test || ENV["GOVUK_ENVIRONMENT"] == "integration"
        return render json: { errors: "Not enabled on this environment" }, status: :bad_request
      end

      if response_params.failure?
        return param_errors
      end

      edition = Edition.find(response_params[:edition_id])

      if User.new.progress(edition,
                           request_type: :receive_fact_check,
                           comment: comment,
                           requester_name: response_params[:responder_name])
        render json: { id: edition.id }, status: :ok
      else
        render json: { errors: edition.errors.full_messages }, status: :unprocessable_entity
      end
    end

  private

    def comment
      response_params["accepted"] ? "Changes are correct." : response_params["comment"]
    end

    def response_params
      contract = FactCheckResponseContract.new
      params_to_validate = params.require(:fact_check_response).to_unsafe_h
      contract.call(params_to_validate)
    end

    def param_errors
      errors = []

      response_params.errors(full: true).to_h.each_value do |e|
        errors << e[0]
      end

      render json: { errors: errors }, status: :unprocessable_entity
    end
  end
end
