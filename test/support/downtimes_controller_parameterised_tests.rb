module DowntimesControllerParameterisedTests
  def test_create_with_invalid_datetime_values
    [
      ["start_time", "1", "", "Start time format is invalid"],
      ["start_time", "2", "", "Start time format is invalid"],
      ["start_time", "3", "", "Start time format is invalid"],
      ["start_time", "4", "", "Start time format is invalid"],
      ["start_time", "5", "", "Start time format is invalid"],
      ["start_time", "1", "asdf", "Start time format is invalid"],
      ["start_time", "2", "a", "Start time format is invalid"],
      ["start_time", "3", "a", "Start time format is invalid"],
      ["start_time", "4", "a", "Start time format is invalid"],
      ["start_time", "5", "a", "Start time format is invalid"],
      ["start_time", "1", "-2024", "Start time format is invalid"],
      ["start_time", "2", "-1", "Start time format is invalid"],
      ["start_time", "3", "-1", "Start time format is invalid"],
      ["start_time", "4", "-1", "Start time format is invalid"],
      ["start_time", "5", "-1", "Start time format is invalid"],
      ["start_time", "2", "0", "Start time format is invalid"],
      ["start_time", "3", "0", "Start time format is invalid"],
      ["start_time", "1", "10000", "Start time format is invalid"],
      ["start_time", "2", "13", "Start time format is invalid"],
      ["start_time", "3", "32", "Start time format is invalid"],
      ["start_time", "4", "60", "Start time format is invalid"],
      ["start_time", "5", "60", "Start time format is invalid"],
      ["end_time", "1", "", "End time format is invalid"],
      ["end_time", "2", "", "End time format is invalid"],
      ["end_time", "3", "", "End time format is invalid"],
      ["end_time", "4", "", "End time format is invalid"],
      ["end_time", "5", "", "End time format is invalid"],
      ["end_time", "1", "asdf", "End time format is invalid"],
      ["end_time", "2", "a", "End time format is invalid"],
      ["end_time", "3", "a", "End time format is invalid"],
      ["end_time", "4", "a", "End time format is invalid"],
      ["end_time", "5", "a", "End time format is invalid"],
      ["end_time", "1", "-2024", "End time format is invalid"],
      ["end_time", "2", "-1", "End time format is invalid"],
      ["end_time", "3", "-1", "End time format is invalid"],
      ["end_time", "4", "-1", "End time format is invalid"],
      ["end_time", "5", "-1", "End time format is invalid"],
      ["end_time", "2", "0", "End time format is invalid"],
      ["end_time", "3", "0", "End time format is invalid"],
      ["end_time", "1", "10000", "End time format is invalid"],
      ["end_time", "2", "13", "End time format is invalid"],
      ["end_time", "3", "32", "End time format is invalid"],
      ["end_time", "4", "60", "End time format is invalid"],
      ["end_time", "5", "60", "End time format is invalid"],
    ].each do |param_base_name, param_sub_ordinal, param_value, expected_message|
      should "display a validation error when the '#{param_base_name}' sub-param '#{param_sub_ordinal}' is '#{param_value}'" do
        params = downtime_params.merge("#{param_base_name}(#{param_sub_ordinal}i)": param_value)

        post :create, params: { edition_id: edition.id, downtime: params }

        assert_select "div.govuk-error-summary" do
          assert_select "a", expected_message
        end
      end
    end
  end
end
