require 'gds_api/need_api'
require 'gds_api/publishing_api_v2'

namespace :needs do
  desc "Send links to the Publishing API specifying which needs a piece of content is associated with"
  task send_content_ids_for_needs_to_publishingapi: :environment do
    @need_api = GdsApi::NeedApi.new(Plek.current.find('need-api'), bearer_token: ENV['NEED_API_BEARER_TOKEN'])
    @publishing_api = GdsApi::PublishingApiV2.new(Plek.current.find('publishing-api'), timeout: 30)

    Artefact.where(owning_app: 'publisher').each do |a|
      if a.need_ids.present?
        puts "#{a.content_id}, #{a.slug}:\n"

        need_content_ids = a.need_ids.map do |need|
          begin
            @need_api.content_id(need)
          rescue GdsApi::HTTPNotFound
            # For when the provided need_id doesn't exist in the Need API.
            nil
          end
        end

        puts "Patching links..."
        payload = {
          links: {
            meets_user_needs: need_content_ids.compact
          }
        }
        @publishing_api.patch_links(a.content_id, payload)

        puts "\n"
      end
    end
  end
end
