namespace :editors do
  desc "Generate editors work report"
  task :work_report => :environment do
    puts "Format type,Publication name,Slug,Editor name"

    Publication.all.each do |publication|
      latest_edition = publication.latest_edition
      edition_actions = latest_edition.actions.sort_by(&:created_at).reverse
      assign_for_review_action = edition_actions.find { |a| a.request_type == 'review_requested' || a.request_type == 'request_review'}

      if (assign_for_review_action.nil?)
        puts %Q^"#{publication.format_type}","#{publication.name}","#{publication.slug}",unassigned^
      else
        editor_who_sent_for_review = User.find(assign_for_review_action.requester_id)
        puts %Q^"#{publication.format_type}","#{publication.name}","#{publication.slug}","#{editor_who_sent_for_review.name}"^
      end
    end
  end
end