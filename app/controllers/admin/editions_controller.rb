class Admin::EditionsController < InheritedResources::Base
  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'
  polymorphic_belongs_to :guide, :answer, :transaction
 
  def create
    new_edition = current_user.new_version(edition_parent.latest_edition)
    if new_edition.save
      redirect_to [:admin, edition_parent], :notice => 'New edition created'
    else
      redirect_to [:admin, edition_parent], :notice => 'Failed to create new edition'
    end
  end

  def update
    update! { [:admin, parent] }
  end
  
  protected
    # I think we can get this via InheritedResources' "parent" method, but that wasn't
    # working for our create method and I can't see where it's initialised
    def edition_parent
      @edition_parent ||= 
        if params[:answer_id]
          Answer.find(params[:answer_id]) 
        elsif params[:guide_id]
          Guide.find(params[:guide_id])
        elsif params[:transaction_id]
          Transaction.find(params[:transaction_id])
        end
    end
end
