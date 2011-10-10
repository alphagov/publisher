class Admin::AnswersController < Admin::PublicationSubclassController

private
  def resource_path(r)
    admin_answer_path(r)
  end

  def create_new
    current_user.create_answer(params[:answer])
  end
end
