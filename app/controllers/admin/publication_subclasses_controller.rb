class Admin::PublicationSubclassesController < Admin::BaseController

  def new
    render :controller => "admin/#{class_identifier.to_s.pluralize}", :action => 'new'
  end

  def show
    @resource = resource
    @latest_edition = resource.latest_edition
    render :controller => "admin/#{class_identifier.to_s.pluralize}", :action => 'show'
  end

  def create
    @resource = create_new
    if @resource.save
      redirect_to resource_path(@resource),
        :notice => "#{description(@resource)} successfully created"
      return
    else
      render :controller => "admin/#{class_identifier.to_s.pluralize}", :action => 'new'
    end
  end

  def destroy
    if resource.can_destroy?
      destroy! do
        redirect_to admin_root_url, :notice => "#{description(resource)} destroyed"
        return
      end
    else
      redirect_to resource_path(resource),
        :notice => "Cannot delete a #{description(resource).downcase} that has ever been published."
      return
    end
  end

  def update
    update! do |s,f|
      s.json { render :json => @resource }
      f.json { render :json => @resource.errors, :status => 406 }
    end
  end

private
  def resource_path(r)
    __send__("admin_#{class_identifier}_path", r)
  end

  def create_new
    current_user.__send__("create_#{class_identifier}", params[class_identifier])
  end

  def description(r)
    r.class.to_s.underscore.humanize
  end

  def class_identifier
    @class_identifier ||=
      self.class.to_s[/::(.*?)Controller$/, 1].underscore.singularize.to_sym
  end
end
