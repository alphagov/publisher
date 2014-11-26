# This endpoint is a temporary requirement until
# the content store pipeline is in full effect.
class Api::SearchController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:reindex_topic_editions]

  def reindex_topic_editions
    published_and_tagged_editions = Edition.published.or(
      {primary_topic: params[:slug]},
      {:additional_topics.in => [params[:slug]]}
    )

    published_and_tagged_editions.each do |edition|
      PanopticonReregisterer.perform_async(edition.id.to_s)
    end

    render json: {result: 'ok', count: published_and_tagged_editions.count}, status: 202
  end
end
