class BenefitsLinksMigrator

  REGEXP = /#(overview|what-youll-get|eligibility|how-to-claim)/

  def report
    matching_editions = match_editions
    modified_latest_editions = 0

    matching_editions.each do |e|
      if e.latest_edition?
        report_edition(e)
        if e.respond_to?("body")
          m = REGEXP.match(e.body)
          if m
            report_match(m, e.body)
          end
        end
        if e.respond_to?("parts")
          e.parts.each do |p|
            if p.body =~ REGEXP
              m = REGEXP.match(p.body)
              report_match(m, p.body)
            end
          end
        end
        modified_latest_editions += 1
      end
    end
    puts "#{modified_latest_editions} editions would be modified."
  end

  def report_edition(e)
    puts [e._id, e._type, e.title, e.slug, e.state].join(", ")
  end

  def report_match(match, str)
    puts "---------------------------------------------------------------------"
    puts "Anchor match : '#{match}' would be replaced with '/#{match[1]}'"
    puts "---------------------------------------------------------------------"
    puts "Original content is:"
    puts "---------------------------------------------------------------------"
    puts str
    puts "---------------------------------------------------------------------"
    puts "Modified content would be:"
    puts "---------------------------------------------------------------------"
    puts replace_matching_anchors(str)
    puts "---------------------------------------------------------------------\n\n"
  end

  def replace_anchors(user_name)
    u = User.where(name: user_name).first

    match_editions.each do |e|
      if e.latest_edition?
        if e.respond_to?("body")
          e.body = replace_matching_anchors(e.body)
        end
        if e.respond_to?("parts")
          e.parts.each do |p|
            if p.body =~ REGEXP
              p.body = replace_matching_anchors(p.body)
            end
          end
        end
        update_msg = "Updated by development task. Benefits link anchors changed to paths."
        if e.state == 'published'
          clone = e.build_clone
          clone.save
          clone.new_action(u, Action::REQUEST_REVIEW, {})
          u.record_note(clone, update_msg)
          updated = clone.request_review!
        else
          u.record_note(e, update_msg)
          updated = e.save
        end
        puts "#{e._id} (#{e.slug}) #{(updated ? '' : 'was not')} modified."
      end
    end
  end

  def replace_matching_anchors(str)
    str.gsub(REGEXP) { |m|
      "/#{$1}"
    }
  end

  def match_editions
    matching_editions = []
    Edition.where(body: REGEXP).each { |e| matching_editions << e unless e.state == 'archived' }
    Edition.where('parts.body' => REGEXP).each { |e| matching_editions << e unless e.state == 'archived' }
    matching_editions
  end
end
