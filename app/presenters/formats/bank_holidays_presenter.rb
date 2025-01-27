# frozen_string_literal: true

class BankHolidaysPresenter < EditionFormatPresenter

  def initialize(bank_holidays_edition)
    @bank_holidays_edition = bank_holidays_edition
  end

  private

  def schema_name
    "answer"
  end

  def document_type
    "answer"
  end

  def rendering_app
    "government-frontend"
  end
end
