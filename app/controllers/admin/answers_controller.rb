class Admin::AnswersController < Admin::BaseController
  def create
    @answer = current_user.create_answer(params[:answer])
    if @answer.save
      redirect_to admin_answer_path(@answer)
    else
      render :action => 'new'
    end
  end
  
  def show
    @answer = resource
    @latest_edition = resource.latest_edition
  end
  
  def update
    update! do |s,f| 
      s.json { render :json => @answer }
      f.json { render :json => @answer.errors, :status => 406 }
    end
  end
  
  def destroy
    if resource.can_destroy?
      destroy! { redirect_to admin_root_url, :notice => "Answer destroyed" and return }
    else
      redirect_to admin_answer_path(resource), :notice => 'Cannot delete a answer that has ever been published.' and return
    end
  end
  
  def progress
    current_user = self.current_user
    notes = params[:comment] || ''
    resource.latest_edition.progress(params[:activity],current_user,notes)    
    redirect_to admin_answer_path(resource), :notice => 'Answer updated'
  end
end
