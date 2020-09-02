require "csv"
require "retriable"
require "reverse_markdown"

class LicenceContentImporter
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

    Rails.logger.debug importer.formatted_result(method == :import)
  end

  def report(row)
    identifier = row["OID"].to_s.strip
    existing_editions = LicenceEdition.where(licence_identifier: identifier)

    if !existing_editions.empty?
      @existing << existing_editions
      @existing.flatten!
    else
      Rails.logger.debug slug_for(row["NAME"])
      if row["LONGDESC"]
        Rails.logger.debug "---------------------------- marked down ---------------------------------"
        Rails.logger.debug marked_down(row["LONGDESC"])
        Rails.logger.debug "------------------------------- end --------------------------------------\n\n"
      end
      @imported << { identifier: identifier, slug: slug_for(row["NAME"]), description: marked_down(row["LONGDESC"]) }
    end
  end

  def import(row)
    identifier = row["OID"].to_s.strip
    existing_editions = LicenceEdition.where(licence_identifier: identifier)

    if !existing_editions.empty?
      @existing << existing_editions
      @existing.flatten!
    else
      title = CGI.unescapeHTML(to_utf8(row["NAME"]))
      slug = slug_for(title)

      artefact = Artefact.find_by(slug: slug) ||
        Artefact.create!(
          slug: slug,
          kind: "licence",
          state: "draft",
          owning_app: "publisher",
          name: title,
          rendering_app: "frontend",
        )

      artefact_id = artefact["id"]

      Rails.logger.debug "Artefact id: #{artefact_id}, slug: #{slug}."

      edition = LicenceEdition.create! title: title,
                                       panopticon_id: artefact_id,
                                       slug: slug,
                                       licence_identifier: identifier,
                                       licence_overview: marked_down(row["LONGDESC"])

      if edition
        add_workflow(@user, edition)
        Rails.logger.debug "Created LicenceEdition in publisher with panopticon_id: #{artefact_id}, licence_identifier: #{identifier}"
        @imported << edition
      else
        @failed[identifier] = slug
        Rails.logger.debug "Failed to import LicenceEdition into publisher. Identifier: #{identifier}, slug: #{slug}."
      end
    end
  end

  def add_workflow(user, edition)
    type = Action::CREATE
    edition.new_action(user, type, {})
    edition.save!
    user.record_note(edition, "Imported via LicenceContentImporter: #{Time.zone.today.to_s(:db)}")
  end

  def formatted_result(import = true)
    Rails.logger.debug "--------------------------------------------------------------------------"
    Rails.logger.debug "#{imported.size} LicenceEditions#{(import ? '' : ' can be')} imported."
    unless existing.empty?
      existing.map! { |e| "#{e.slug} (#{e.licence_identifier})" }
      existing.uniq!
      Rails.logger.debug "#{existing.size} existing LicenceEditions:"
      Rails.logger.debug existing
    end
    unless failed.empty?
      Rails.logger.debug "#{failed.keys.size} failed imports:"
      failed.each_key do |k|
        Rails.logger.debug "#{k} : #{failed[k]}"
      end
    end
    Rails.logger.debug "--------------------------------------------------------------------------"
  end

  def slug_for(title)
    title.parameterize.gsub("-amp-", "-and-")
  end

  def marked_down(str, unescape_html = false)
    return str if str.nil?

    str = to_utf8(str)
    str = CGI.unescapeHTML(str) if unescape_html
    ReverseMarkdown.convert(str).strip
  end

  def to_utf8(str)
    (str.nil? ? nil : str.force_encoding("UTF-8"))
  end

  def csv_data(data_path)
    CSV.read "#{Rails.root}/#{data_path}", headers: true
  end
end
