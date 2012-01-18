class Admin::PublicationSubclassesController < Admin::BaseController

  def show
    @resource = resource
    @latest_edition = resource.latest_edition
  end

  def create
    @publication = current_user.create_publication(class_identifier, params[class_identifier])
    if @publication.persisted?
      redirect_to resource_path(@publication),
        :notice => "#{description(@publication)} successfully created"
      return
    else
      render :action => "new"
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
    update! do |s, f|
      s.json { render :json => @resource }
      f.json { render :json => @resource.errors, :status => 406 }
    end
  end

private
  def resource_path(r)
    __send__("admin_#{class_identifier}_path", r)
  end

  def description(r)
    r.class.to_s.underscore.humanize
  end

  def class_identifier
    @class_identifier ||=
      self.class.to_s[/::(.*?)Controller$/, 1].underscore.singularize.to_sym
  end
end
