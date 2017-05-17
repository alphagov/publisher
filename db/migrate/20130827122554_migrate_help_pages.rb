class MigrateHelpPages < Mongoid::Migration
  SLUGS = %w(
    about-govuk
    cookies
    browsers
    privacy-policy
    accessibility
    terms-and-conditions
  )

  def self.up
    SLUGS.each do |slug|
      puts "Converting #{slug} to HelpPageEdition"
      a = Artefact.where(slug: slug).first
      unless a
        puts "  artefact not found"
        next
      end
      eds = Edition.where(slug: slug)
      unless eds.count == 1
        puts "  multiple editions found, skipping..."
        next
      end
      ed = eds.first
      unless a.state == 'draft'
        puts "  artefact isn't draft, skipping..."
        next
      end
      if ed.state == "published"
        puts "  edition is published, skipping..."
        next
      end

      a.kind = "help_page"
      if slug == "terms-and-conditions"
        a.slug = "help/terms-conditions"
      else
        a.slug = "help/#{a.slug}"
      end
      a.save!

      ed.slug = a.slug
      ed._type = "HelpPageEdition"
      ed.save!
    end
  end

  def self.down
  end
end
