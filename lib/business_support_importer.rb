require 'csv'
require 'gds_api/helpers'
require 'retriable'
require 'reverse_markdown'

class BusinessSupportImporter

  include GdsApi::Helpers
  
  attr_reader :imported, :failed
   
  def initialize(data_path, importing_user)
    @imported = 0
    @failed = []
    @api = panopticon_api
    @user = User.where(name: importing_user).first
    raise "User #{importing_user} not found, please provide the name of a valid user." unless @user
  end
  
  def self.run(method, data_path, importing_user=User.first)
      timeouts = 0
      importer = BusinessSupportImporter.new(data_path, importing_user)
      importer.csv_data(data_path).each do |row|
        retriable :on => GdsApi::TimedOutException, :tries => 5, :interval => 5 do
          importer.send(method, row)
        end
      end
    ensure
      puts importer.formatted_result(method == :import)
  end
  
  def report row
    slug = slug_for(row['title'])
    long_desc = marked_down(row['long_description'])
    if LicenceEdition.where(slug: slug).size == 0
      puts slug
      puts "---------------------------- marked down ---------------------------------"
      puts long_desc
      puts "------------------------------- end --------------------------------------\n\n"
      @imported += 1
    else
      @failed << "Failed to import LicenceEdition. Slug: #{slug}"
    end
  end
  
  def import row
    
    title = CGI.unescapeHTML(to_utf8(row['title']))
    slug = slug_for(title)
      
    api_response = @api.create_artefact(slug: slug, kind: 'business_support', state: 'draft',
      owning_app: 'publisher', name: title, rendering_app: "frontend", need_id: 1)
      
    if api_response && api_response.code == 201 # 'created' http response code
      artefact_id = api_response.to_hash['id']
                  
      puts "Created Artefact in panopticon with id: #{artefact_id}, slug: #{slug}."
      
      short_desc = marked_down(row['short_description'])
      
      edition = BusinessSupportEdition.create title: title, panopticon_id: artefact_id, slug: slug, 
        business_support_identifier: slug, short_description: short_desc, max_employees: to_utf8(row['max_employees']), 
        min_value: row['min_grant_value'], max_value: to_utf8(row['max_grant_value']), organiser: to_utf8(row['organiser']), 
        continuation_link: to_utf8(row['url']), contact_details: to_utf8(row['contact_details']), business_proposition: true
      
      if edition
        
        set_part_body edition, "description", marked_down(row['additional_information'])
        set_part_body edition, "eligibility", marked_down(row['eligibility'])
        set_part_body edition, "additional-information", marked_down(row['long_description'])
      
        add_workflow(@user, edition)
        
        puts "Created BusinessSupportEdition in publisher with panopticon_id: #{artefact_id}, Slug: #{slug}"       
        @imported += 1
      else
        @failed << "Failed to import BusinessSupportEdition into publisher. Slug: #{slug}."
      end
    else
      @failed << "Failed to import BusinessSupportEdition via panopticon API. Slug: #{slug}."
    end
  end
  
  def add_workflow(user, edition)
    type = Action.const_get(Action::CREATE.to_s.upcase)
    action = edition.new_action(user, type, {})
    user.record_note(edition, "Imported via BusinessSupportContentImporter: #{Date.today.to_s(:db)}")
  end
  
  def set_part_body(edition, slug, body)
    parts = edition.parts.where(slug: slug)
    parts.first.body = body if parts.size > 0
  end
  
  def formatted_result(import=true)
    puts "--------------------------------------------------------------------------"
    puts "#{imported} BusinessSupportEditions#{(import ? '' : ' can be')} imported."
    failed.each { |f| puts f }
    puts "--------------------------------------------------------------------------"
  end
  
  def slug_for(title)
    title.parameterize.gsub("-amp-", "-and-")
  end
  
  def to_utf8(str)
    (str.nil? ? nil : str.force_encoding("UTF-8"))
  end
  
  def marked_down(str, unescape_html=false)
    return nil if str.nil?
    str = CGI.unescapeHTML(to_utf8(str)) if unescape_html
    ReverseMarkdown.parse(str).gsub(/\n((\-.*\n)+)/) {|match|
      "\n\n#{$1}"
    }
  end
  
  def csv_data(path)
    path << ".csv" unless path =~ /\.csv$/ 
    CSV.read(File.join(Rails.root, path), headers: true)
  end
  
end
