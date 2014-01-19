class ExpectationsController < InheritedResources::Base
  actions :all, :except => [:destroy, :edit, :update]

  def index
    @expectations = Expectation.all
    @expectation = Expectation.new
  end

  def create
    @expectation = Expectation.new(params[:expectation])
    if @expectation.save
      redirect_to expectations_path, :notice => 'Expectation set'
    else
      @expectations = Expectation.all
      render :action => 'index'
    end
  end
end
