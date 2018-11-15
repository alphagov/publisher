require 'test_helper'

class QuestionAndAnswerPresenterTest < ActiveSupport::TestCase
  def subject
    QuestionAndAnswerPresenter
  end

  context "Body parsing" do
    should "not modify the body if no questions and answers" do
      body = <<~BODY
        #This is a title

        ##Subtitle

        Text with a [link](in/it)

        Other text
      BODY

      q_and_a = subject.new(body, "bear-advice")

      assert_empty(q_and_a.pairs)
      assert_equal(body, q_and_a.parsed_body)
    end

    should "extract a question and answer if one is specified" do
      body = <<~BODY
        #This is a title

        ##Subtitle

        {answer}[best-bear]The best kind of bear is a polar bear{/answer}

        Text with a [link](in/it)

        {answer}[nice-porridge]Around a third of bears are excellent porridge makers{/answer}

        {question}[nice-porridge]Are bears good at cooking?{/question}
        {question}[best-bear]What is the best sort of bear?{/question}
      BODY

      expected_body = <<~EXPECT_BODY
        #This is a title

        ##Subtitle

        [](#best-bear)The best kind of bear is a polar bear

        Text with a [link](in/it)

        [](#nice-porridge)Around a third of bears are excellent porridge makers
      EXPECT_BODY

      expected_pairs = [
        {
          question: "What is the best sort of bear?",
          answer: "The best kind of bear is a polar bear",
          link: "/bear-advice#best-bear"
        },
        {
          question: "Are bears good at cooking?",
          answer: "Around a third of bears are excellent porridge makers",
          link: "/bear-advice#nice-porridge"
        }
      ]

      q_and_a = subject.new(body, "bear-advice")

      assert_equal(expected_pairs, q_and_a.pairs)
      assert_equal(expected_body, q_and_a.parsed_body)
    end

    should "cope with multiline answers" do
      body = <<~BODY
        #This is a title

        ##Subtitle

        {answer}[best-bear]The best kind of bear is a polar bear{/answer}

        Text with a [link](in/it)

        {answer}[comfy-bed]Bears are renowned for sleeping on beds.

        It should be noted that what is comfortable for a bear is not necessarily
        so for a human.{/answer}

        {question}[comfy-bed]What do bears sleep on?{/question}
        {question}[best-bear]What is the best sort of bear?{/question}
      BODY

      expected_body = <<~EXPECT_BODY
        #This is a title

        ##Subtitle

        [](#best-bear)The best kind of bear is a polar bear

        Text with a [link](in/it)

        [](#comfy-bed)Bears are renowned for sleeping on beds.

        It should be noted that what is comfortable for a bear is not necessarily
        so for a human.
      EXPECT_BODY

      expected_pairs = [
        {
          question: "What is the best sort of bear?",
          answer: "The best kind of bear is a polar bear",
          link: "/bear-advice#best-bear"
        },
        {
          question: "What do bears sleep on?",
          answer: "Bears are renowned for sleeping on beds.\n\nIt should be noted that what is comfortable for a bear is not necessarily\nso for a human.",
          link: "/bear-advice#comfy-bed"
        }
      ]

      q_and_a = subject.new(body, "bear-advice")

      assert_equal(expected_pairs, q_and_a.pairs)
      assert_equal(expected_body, q_and_a.parsed_body)
    end
  end
end
