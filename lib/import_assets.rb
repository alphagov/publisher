require 'uri' 
require 'fog'

class AssetImporter
  
  def self.perform
    ArticleEdition.all.each do |edition|
      if edition.content     
        matches = edition.content.scan /!\[.*?\]\((.*?)\)/
        unless matches.nil?
          matches.each do |match|
            origin = match[0]
            if origin.start_with?("/")
              url = 'http://www.theodi.org' + origin
            elsif origin.start_with?("theodi")
              url = 'http://' + origin
            else
              url = origin
            end
            
            puts edition.slug
            puts url
            
            new_url = upload(url)
            
            unless new_url.nil?
              edition.content = edition.content.gsub(origin, new_url)
              edition.save(validate: false) 
            end
            
          end
        end
      end
    end
  end
  
  def self.service
    Fog::Storage.new({
                  :provider            => 'Rackspace',
                  :rackspace_username  => ENV['RACKSPACE_USERNAME'],
                  :rackspace_api_key   => ENV['RACKSPACE_API_KEY'],
                  :rackspace_auth_url  => Fog::Rackspace::UK_AUTH_ENDPOINT,
                  :rackspace_region    => :lon
    })
  end
  
  def self.upload(url)
    dir = service.directories.get ENV['QUIRKAFLEEG_ASSET_MANAGER_RACKSPACE_CONTAINER']
    
    body = open(url) rescue nil
    
    unless body.nil?    
      uri = URI.parse(url)
      filename = File.basename(uri.path)
      destination = URI.unescape(filename).gsub(" ", "-")
    
      file = dir.files.create :key => "uploads/assets/legacy/" + destination, :body => body
      file.public_url
    end
  end
  
end
