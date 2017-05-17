class ChangeOwningAppAndSlugForDrivingInstructor < Mongoid::Migration
  # select the slug to be changed
  SSA_SLUG = 'become-driving-instructor'
  SA_SLUG = 'become-a-driving-instructor'


  def self.up
    changeling = Artefact.find_by_slug(SA_SLUG)

    if changeling
      # change the kind and owning app
      puts "Updating owning app, kind and rendering app"
      changeling.update_attributes(kind: "simple_smart_answer", owning_app: "publisher", rendering_app: "frontend")

      # update the slug on all editions
      puts "Updating the slug on all editions"
      Edition.where(slug: SSA_SLUG).each do |e|
        e.slug = SA_SLUG
        e.panopticon_id = changeling._id
        e.save(validate: false)
      end

      # re-register with panopticon to recreate in search
      puts "Re-registering #{SA_SLUG} with panopticon to recreate in search"
      ed = Edition.published.where(slug: SA_SLUG).first
      ed.register_with_panopticon
    else
      puts "Can't find artefact for slug '#{SA_SLUG}"
    end
  end

  def self.down
    reverse_changeling = Artefact.find_by_slug(SA_SLUG)

    if reverse_changeling
      # change the kind and owning app

      reverse_changeling.update_attributes(kind: "smart-answer", owning_app: "smartanswers", rendering_app: nil)
      puts "Reverting owning app, kind and rendering app"

      # update the slug on all editions
      puts "Reverting the slug on all editions"
      artefact = Artefact.find_by_slug(SSA_SLUG)
      Edition.where(slug: SA_SLUG).each do |e|
        e.slug = SSA_SLUG
        e.panopticon_id = artefact._id
        e.save(validate: false)
      end

      # re-register with panopticon to recreate in search
      puts "Re-registering #{SSA_SLUG} with panopticon to recreate in search"
      ed = Edition.published.where(slug: SSA_SLUG).first
      ed.register_with_panopticon
    else
      puts "Can't find artefact with slug #{SA_SLUG}"
    end
  end
end
