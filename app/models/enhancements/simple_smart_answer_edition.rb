require "simple_smart_answer_edition"
require "json"

class SimpleSmartAnswerEdition
  def nodes_as_json
    self.nodes.to_json
  end

  def nodes_as_json=(json)
    self.nodes = JSON.parse(json)
  end
end
