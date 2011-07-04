class Admin::EditionsController < InheritedResources::Base
 defaults :route_prefix => 'admin'
 belongs_to :guide
end
