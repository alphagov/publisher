class QuestionAndAnswerPresenter
  attr_reader :body, :path

  def initialize(body, path)
    @body = body
    @path = path
    parse
  end

  def parsed_body
    @parsed_body ||= body.dup
  end

  def pairs
    @pairs ||= []
  end

private

  ANSWER_REGEX = /{answer}\[(?<key>.+?)\](?<value>.+?){\/answer}?/m
  QUESTION_REGEX = /{question}\[(?<key>.+?)\](?<value>.+?){\/question}/

  def parse
    generate_pairs

    sanitize_body
  end

  def sanitize_body
    insert_anchors
    remove_closing_answer_tags
    remove_questions
  end

  def insert_anchors
    answers.each do |key, answer|
      parsed_body.gsub!("{answer}[#{key}]", "[](##{key})")
    end
  end

  def remove_closing_answer_tags
    parsed_body.gsub!("{/answer}", "")
  end

  def remove_questions
    parsed_body.gsub!(/^{question}.+$/, "")
    parsed_body.strip!
    parsed_body << "\n"
  end

  def generate_pairs
    answers.each do |key, answer|
      question = questions[key]
      if question.present?
        pairs << { question: question, answer: answer, link: "/#{path}##{key}" }
      end
    end
  end

  def answers
    @answer_matches ||= find_matches(ANSWER_REGEX)
  end

  def questions
    @question_matches ||= find_matches(QUESTION_REGEX)
  end

  def find_matches(regex)
    matches = []
    body.scan(regex) { matches << $LAST_MATCH_INFO }

    matches.reduce({}) do |result, current|
      result.merge!(current[:key].to_sym => current[:value])
    end
  end
end
