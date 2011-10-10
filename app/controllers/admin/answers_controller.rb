class Admin::AnswersController < Admin::BaseController
  respond_to :html, :json

  def show
    @resource = resource
    @latest_edition = resource.latest_edition
  end

  def create
    @resource = current_user.create_answer(params[:answer])
    if @resource.save
      redirect_to admin_answer_path(@resource)
    else
      render :action => 'new'
    end
  end

  def destroy
    if resource.can_destroy?
      destroy! { redirect_to admin_root_url, :notice => "Answer destroyed" and return }
    else
      redirect_to admin_answer_path(resource), :notice => 'Cannot delete an answer that has ever been published.' and return
    end
  end

  def update
    update! do |s,f|
      s.json { render :json => @resource }
      f.json { render :json => @resource.errors, :status => 406 }
    end
  end
end
