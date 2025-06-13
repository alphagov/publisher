module MongoMigrationHelper
  def create_editionable(object)
    case @content_type
    when "GuideEdition"
      create_guide_edition(object)
    when "LocalTransactionEdition"
      create_local_transaction_edition(object)
    when "SimpleSmartAnswerEdition"
      create_simple_smart_answer_edition(object)
    else
      [PlaceEdition, TransactionEdition, AnswerEdition, HelpPageEdition].each do |content_type|
        create_content_type(object, content_type)
      end
    end
  end

  def create_content_type(object, class_name)
    mapper = MongoFieldMapper.new(class_name)
    attrs = mapper.active_record_attributes(object)
    guide_edition = class_name.insert(attrs)
    @editionable_id = guide_edition.to_a[0]['id']
  end

  def create_guide_edition(object)
    mapper = MongoFieldMapper.new(GuideEdition)
    attrs = mapper.active_record_attributes(object)
    guide_edition = GuideEdition.insert(attrs)
    @editionable_id = guide_edition.to_a[0]['id']
    create_parts_for_guide_edition(object["parts"])

    guide_edition
  end

  def create_parts_for_guide_edition(object)
    mapper = MongoFieldMapper.new(Part)
    object.each do |obj|
      attrs = mapper.active_record_attributes(obj)
      attrs["guide_edition_id"] = @editionable_id
      Part.insert(attrs)
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
