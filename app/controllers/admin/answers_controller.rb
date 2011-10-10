class Admin::AnswersController < Admin::BaseController
  respond_to :html, :json

  def show
    @answer = resource
    @latest_edition = resource.latest_edition
  end

  def create
    @answer = current_user.create_answer(params[:answer])
    if @answer.save
      redirect_to admin_answer_path(@answer)
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
      s.json { render :json => @answer }
      f.json { render :json => @answer.errors, :status => 406 }
    end
  end
end
