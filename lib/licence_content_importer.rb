require 'csv'
require 'gds_api/helpers'
require 'retriable'
require 'reverse_markdown'

class LicenceContentImporter
  include GdsApi::Helpers

  attr_reader :data_path, :imported, :existing, :failed

  def initialize(data_path, importing_user)
    @imported = []
    @existing = []
    @failed = {}
    @data_path = data_path
    @user = User.where(name: importing_user).first
    raise "User #{importing_user} not found, please provide the name of a valid user." unless @user
  end

  def self.run(method, data_path, importing_user = User.first)
    importer = LicenceContentImporter.new(data_path, importing_user)

    importer.csv_data(data_path).each do |row|
      retriable on: GdsApi::TimedOutException, tries: 5, interval: 5 do
        importer.send(method, row)
      end
    end

    puts importer.formatted_result(method == :import)
  end

  def report row
    identifier = row['OID'].to_s.strip
    existing_editions = LicenceEdition.where(licence_identifier: identifier)

    if existing_editions.size > 0
      @existing << existing_editions
      @existing.flatten!
    else
      puts slug_for(row['NAME'])
      if row['LONGDESC']
        puts "---------------------------- marked down ---------------------------------"
        puts marked_down(row['LONGDESC'])
        puts "------------------------------- end --------------------------------------\n\n"
      end
      @imported << { identifier: identifier, slug: slug_for(row['NAME']), description: marked_down(row['LONGDESC']) }
    end
  end

  def import row
    identifier = row['OID'].to_s.strip
    existing_editions = LicenceEdition.where(licence_identifier: identifier)

    if existing_editions.size > 0
      @existing << existing_editions
      @existing.flatten!
    else
      title = CGI.unescapeHTML(to_utf8(row['NAME']))
      slug = slug_for(title)

      artefact = Artefact.find_by_slug(slug) ||
        Artefact.create(
          slug: slug, kind: 'licence', state: 'draft', owning_app: 'publisher',
          name: title, rendering_app: "frontend", need_id: 1
        )

      artefact_id = artefact['id']

      puts "Artefact id: #{artefact_id}, slug: #{slug}."

      edition = LicenceEdition.create title: title, panopticon_id: artefact_id, slug: slug,
        licence_identifier: identifier, licence_overview: marked_down(row['LONGDESC'])

      if edition
        add_workflow(@user, edition)
        puts "Created LicenceEdition in publisher with panopticon_id: #{artefact_id}, licence_identifier: #{identifier}"
        @imported << edition
      else
        @failed[identifier] = slug
        puts "Failed to import LicenceEdition into publisher. Identifier: #{identifier}, slug: #{slug}."
      end
    end
  end

  def add_workflow(user, edition)
    type = Action.const_get(Action::CREATE.to_s.upcase)
    edition.new_action(user, type, {})
    edition.save!
    user.record_note(edition, "Imported via LicenceContentImporter: #{Time.zone.today.to_s(:db)}")
  end

  def formatted_result(import = true)
    puts "--------------------------------------------------------------------------"
    puts "#{imported.size} LicenceEditions#{(import ? '' : ' can be')} imported."
    unless existing.empty?
      existing.map! { |e| "#{e.slug} (#{e.licence_identifier})" }
      existing.uniq!
      puts "#{existing.size} existing LicenceEditions:"
      puts existing
    end
    unless failed.empty?
      puts "#{failed.keys.size} failed imports:"
      failed.keys.each do |k|
        puts "#{k} : #{failed[k]}"
      end
    end
    puts "--------------------------------------------------------------------------"
  end

  def slug_for(title)
    title.parameterize.gsub("-amp-", "-and-")
  end

  def marked_down(str, unescape_html = false)
    return str if str.nil?
    str = to_utf8(str)
    str = CGI.unescapeHTML(str) if unescape_html
    ReverseMarkdown.parse(str).gsub(/\n((\-.*\n)+)/) {|_match|
      "\n\n#{$1}"
    }
  end

  def to_utf8(str)
    (str.nil? ? nil : str.force_encoding("UTF-8"))
  end

  def csv_data(data_path)
    CSV.read "#{Rails.root}/#{data_path}", headers: true
  end
end
