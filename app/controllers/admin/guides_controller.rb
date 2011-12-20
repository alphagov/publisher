class Admin::GuidesController <  Admin::PublicationSubclassesController
  defaults :resource_class => GuideEdition, :collection_name => 'publications', :instance_name => 'publication'
end
