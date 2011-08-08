class Admin::RootController < Admin::BaseController
  respond_to :html, :json

  def index
    @drafts = Publication.in_draft
    @published = Publication.published
    @archive = Publication.archive
    @review_requested = Publication.review_requested
  end
end
