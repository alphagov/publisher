require_relative '../../test_helper'

class LocalServiceCleanerTest < ActiveSupport::TestCase
  context "removing services we don't need anymore" do
    setup do
      data = "LGSL,Description,Providing Tier\n"
      data += "1234,Finding Joy,all\n"
      data += "5678,Escaping Sadness,county/unitary\n"
      @input = StringIO.new(data)
    end

    context 'when lgsl of service present in input' do
      setup do
        @service = LocalService.create(lgsl_code: 1234, description: 'Escaping Joy', providing_tier: %w{district unitary county})
      end

      should 'not destroy service' do
        LocalServiceCleaner.new(@input).run
        assert LocalService.where(id: @service.id).any?
      end
    end

    context 'when lgsl of service not present in input' do
      setup do
        @service = LocalService.create(lgsl_code: 9012, description: 'Whatever', providing_tier: %w{district unitary county})
      end

      context 'and lgsl not used by local transaction edition' do
        should 'destroy service' do
          LocalServiceCleaner.new(@input).run
          refute LocalService.where(id: @service.id).any?
        end
      end

      context 'but lgsl used by local transaction edition' do
        setup do
          @edition = FactoryBot.create(
            :local_transaction_edition,
            lgsl_code: 9012,
            lgil_code: 1
          )
        end

        should 'not destroy service' do
          LocalServiceCleaner.new(@input).run
          assert LocalService.where(id: @service.id).any?
        end
      end
    end
  end
end
