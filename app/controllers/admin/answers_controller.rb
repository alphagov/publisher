class Admin::AnswersController < InheritedResources::Base
  before_filter :authenticate_user!
  defaults :route_prefix => 'admin'
  
  def index
    redirect_to admin_guides_url
  end
  
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
  
  def progress
    @answer = resource
    @latest_edition = resource.latest_edition
    notes = ''

    case params[:activity]
    when 'request_review'
      current_user.request_review(@latest_edition, notes)
    when 'review'
      current_user.review(@latest_edition, notes)
    when 'okay'
      current_user.okay(@latest_edition, notes)
    when 'publish'
      current_user.publish(@latest_edition, notes)
    end

    @latest_edition.save
    
    redirect_to admin_answer_path(@answer), :notice => 'Answer updated'
  end
end
