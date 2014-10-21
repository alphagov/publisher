require 'test_helper'

describe EditionsHelper do
  include EditionsHelper

  describe '#browse_options_for_select' do
    it 'returns grouped options' do
      oil_and_gas_subtopics = [
        OpenStruct.new(slug: 'oil-and-gas/wells', title: 'Wells', parent_title: 'Oil and Gas', draft?: true),
        OpenStruct.new(slug: 'oil-and-gas/fields', title: 'Fields', parent_title: 'Oil and Gas', draft?: false)
      ]

      tax_subbrowse = [
        OpenStruct.new(slug: 'tax/income-tax', title: 'Income Tax', parent_title: 'Tax', draft?: false),
        OpenStruct.new(slug: 'tax/capital-gains-tax', title: 'Capital Gains Tax', parent_title: 'Tax', draft?: true)
      ]

      collections = {
        'Oil and Gas' => oil_and_gas_subtopics,
        'Tax' => tax_subbrowse
      }

      expected_options = [
        ['Oil and Gas', [['Oil and Gas: Wells (draft)', 'oil-and-gas/wells'],
                         ['Oil and Gas: Fields', 'oil-and-gas/fields']]],
        ['Tax', [['Tax: Income Tax', 'tax/income-tax'],
                 ['Tax: Capital Gains Tax (draft)', 'tax/capital-gains-tax']]]
      ]

      assert_equal expected_options, browse_options_for_select(collections)
    end
  end
end
