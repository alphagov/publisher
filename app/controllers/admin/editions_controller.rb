class Admin::EditionsController <  Admin::BaseController
  polymorphic_belongs_to :guide, :answer, :transaction, :local_transaction, :place, :programme

  def create
    new_edition = current_user.new_version(edition_parent.latest_edition)
    if new_edition and new_edition.save
      redirect_to [:admin, edition_parent], :notice => 'New edition created'
    else
      alert = 'Failed to create new edition'
      alert += new_edition ? ": #{new_edition.errors.inspect}" : ": couldn't initialise"
      redirect_to [:admin, edition_parent], :alert => alert
    end
  end

  def update
    update! do |success, failure| 
      success.html { redirect_to [:admin, parent] }
      failure.html { 
        tmpl_folder = parent.class.to_s.pluralize.downcase
        instance_variable_set("@#{parent.class.to_s.downcase}".to_sym, parent)
        @latest_edition = parent.latest_edition
        flash.now[:alert] = "We had some problems saving. Please check the form below."
        render :template => "admin/#{tmpl_folder}/show"
      } 
      success.json { render :json => resource }
      failure.json { render :json => resource.errors, :status=>406 }
    end
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
        elsif params[:programme_id]
          Programme.find(params[:programme_id])
        elsif params[:local_transaction_id]
          LocalTransaction.find(params[:local_transaction_id])
        elsif params[:place_id]
          Place.find(params[:place_id])
        end
      @edition_parent
    end
end
