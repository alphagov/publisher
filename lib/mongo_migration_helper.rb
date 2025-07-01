module MongoMigrationHelper
  def create_editionable(object)
    case @content_type
    when "GuideEdition"
      create_guide_edition(object)
    when "LocalTransactionEdition"
      create_local_transaction_edition(object)
    when "SimpleSmartAnswerEdition"
      create_simple_smart_answer_edition(object)
    when "TransactionEdition"
      create_transaction_edition(object)
    when "ProgrammeEdition"
      create_programme_edition(object)
    else
      create_content_type(object, @content_type)
    end
  end

  def create_content_type(object, class_name)
    content_type = class_name.constantize
    mapper = MongoFieldMapper.new(content_type)
    attrs = mapper.active_record_attributes(object)
    edition = content_type.insert(attrs)
    @editionable_id = edition.to_a[0]['id']
  end

  def create_guide_edition(object)
    mapper = MongoFieldMapper.new(GuideEdition)
    attrs = mapper.active_record_attributes(object)
    guide_edition = GuideEdition.insert(attrs)
    @editionable_id = guide_edition.to_a[0]['id']
    create_parts(object["parts"])
  end

  def create_programme_edition(object)
    mapper = MongoFieldMapper.new(ProgrammeEdition)
    attrs = mapper.active_record_attributes(object)
    programme_edition = ProgrammeEdition.insert(attrs)
    @editionable_id = programme_edition.to_a[0]['id']
    create_parts(object["parts"])
  end

  def create_transaction_edition(object)
    mapper = MongoFieldMapper.new(TransactionEdition)
    attrs = mapper.active_record_attributes(object)
    transaction_edition = TransactionEdition.insert(attrs)
    @editionable_id = transaction_edition.to_a[0]['id']
    if object["variants"]
      create_variants_for_transaction_edition(object["variants"])
    end
  end

  def create_parts(object)
    unless object.nil? || object.empty?
      mapper = MongoFieldMapper.new(Part)
      object.each do |obj|
        attrs = mapper.active_record_attributes(obj)
        attrs["guide_edition_id"] = @editionable_id
        Part.insert(attrs)
      end
    end
  end

  def create_variants_for_transaction_edition(object)
    unless object.nil? || object.empty?
      mapper = MongoFieldMapper.new(Variant)
      object.each do |obj|
        attrs = mapper.active_record_attributes(obj)
        Variant.insert(attrs)
      end
    end
  end

  def create_local_transaction_edition(object)
    mapper = MongoFieldMapper.new(LocalTransactionEdition)
    attrs = mapper.active_record_attributes(object)
    local_transaction_edition = LocalTransactionEdition.insert(attrs)
    @editionable_id = local_transaction_edition.to_a[0]['id']
    num_records_before_adding = DevolvedAdministrationAvailability.count
    create_administration_for_local_transaction(object)
    if DevolvedAdministrationAvailability.count == num_records_before_adding
      LocalTransactionEdition.last
    end
  end

  def create_administration_for_local_transaction(object)
    mapper = MongoFieldMapper.new(DevolvedAdministrationAvailability)
    unless object["scotland_availability"].nil?
      attrs_scotland = mapper.active_record_attributes(object["scotland_availability"])
      attrs_scotland["type"] = "ScotlandAvailability"
      attrs_scotland["local_transaction_edition_id"] = @editionable_id
      DevolvedAdministrationAvailability.insert(attrs_scotland)
    end

    unless object["wales_availability"].nil?
      attrs_wales = mapper.active_record_attributes(object["wales_availability"])
      attrs_wales["type"] = "WalesAvailability"
      attrs_wales["local_transaction_edition_id"] = @editionable_id
      DevolvedAdministrationAvailability.insert(attrs_wales)
    end

    unless object["northern_ireland_availability"].nil?
      attrs_northern_ireland = mapper.active_record_attributes(object["northern_ireland_availability"])
      attrs_northern_ireland["type"] = "NorthernIrelandAvailability"
      attrs_northern_ireland["local_transaction_edition_id"] = @editionable_id
      DevolvedAdministrationAvailability.insert(attrs_northern_ireland)
    end
  end

  def create_simple_smart_answer_edition(object)
    mapper = MongoFieldMapper.new(SimpleSmartAnswerEdition)
    attrs = mapper.active_record_attributes(object)
    simple_smart_answer_edition = SimpleSmartAnswerEdition.insert(attrs)
    @editionable_id = simple_smart_answer_edition.to_a[0]['id']
    create_simple_smart_answer_edition_nodes(object["nodes"])
    simple_smart_answer_edition
  end

  def create_simple_smart_answer_edition_nodes(object)
    unless object.nil?
      mapper = MongoFieldMapper.new(SimpleSmartAnswerEdition::Node)
      object.each do |obj|
        attrs = mapper.active_record_attributes(obj)
        attrs["simple_smart_answer_edition_id"] = @editionable_id
        node = SimpleSmartAnswerEdition::Node.insert(attrs)
        node_id = node.to_a[0]['id']
        mapper_option = MongoFieldMapper.new(SimpleSmartAnswerEdition::Node::Option)
        unless obj["options"].nil?
          obj["options"].each do |obj_node|
            attrs_option = mapper_option.active_record_attributes(obj_node)
            attrs_option["node_id"] = node_id
            SimpleSmartAnswerEdition::Node::Option.insert(attrs_option)
          end
        end
      end
    end
  end

  def create_action_and_link_check_reports(id, object)
    unless object["actions"].nil?
      mapper = MongoFieldMapper.new(Action)
      object["actions"].each do |obj|
        attrs = mapper.active_record_attributes(obj)
        attrs["edition_id"] = id
        Action.insert(attrs)
      end
    end
    create_link_check_reports(id, object)
  end

  def create_link_check_reports(id, object)
    mapper = MongoFieldMapper.new(LinkCheckReport)
    unless object["link_check_reports"].nil?
      object["link_check_reports"].each do |obj|
        attrs = mapper.active_record_attributes(obj)
        attrs["edition_id"] = id
        link_check_report = LinkCheckReport.insert(attrs)
        link_check_report_id = link_check_report.to_a[0]['id']
        mapper = MongoFieldMapper.new(Link)
        obj["links"].each do |link_obj|
          attrs = mapper.active_record_attributes(link_obj)
          attrs["link_check_report_id"] = link_check_report_id
          Link.insert(attrs)
        end
      end
    end
  end

  def create_artefact_actions_and_external_links(id, object)
    unless object["actions"].nil?
      mapper = MongoFieldMapper.new(ArtefactAction)
      object["actions"].each do |obj|
        attrs = mapper.active_record_attributes(obj)
        attrs["artefact_id"] = id
        ArtefactAction.insert(attrs)
      end
    end

    unless object["external_links"].nil?
      mapper = MongoFieldMapper.new(ArtefactExternalLink)
      object["external_links"].each do |obj|
        attrs = mapper.active_record_attributes(obj)
        attrs["artefact_id"] = id
        ArtefactExternalLink.insert(attrs)
      end
    end
  end

  def create_link_check_report_links(id, object)
    mapper = MongoFieldMapper.new(Link)
    object["links"].each do |obj|
      attrs = mapper.active_record_attributes(obj)
      attrs["link_check_report_id"] = id
      Link.insert(attrs)
    end
  end
end