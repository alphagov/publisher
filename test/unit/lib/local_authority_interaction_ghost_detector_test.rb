require_relative '../../test_helper'

class LocalAuthorityInteractionGhostDetectorTest < ActiveSupport::TestCase

  context "detecting ghosts" do
    setup do
      data = "Authority Name,SNAC,LAid,Service Name,LGSL,LGIL,Service URL,Last Updated\n"
      data += "Happyland Council,1234,5678,Finding Joy,901,234,http://happyland-council.example.com/901/234,\n"
      data += "Happyland Council,1234,5678,Finding Joy,901,235,X,\n"
      @input = StringIO.new(data)
    end

    context 'snac not present in input' do
      setup do
        @la = LocalAuthority.create(snac: '2345', name: 'Sadland Council', local_directgov_id: '6790', tier: 'district')
        @lai = @la.local_interactions.create(lgsl_code: '901', lgil_code: '234', url: 'http://example.com/hats')
      end

      should 'detect status as authority_not_in_input' do
        collected = []
        LocalAuthorityInteractionGhostDetector.new(@input).detect_ghosts do |la, lai, ghost_status|
          collected << [la, lai, ghost_status]
        end

        assert_equal 1, collected.size
        detected = collected.first
        assert_equal @la, detected[0]
        assert_equal @lai, detected[1]
        assert_equal :authority_not_in_input, detected[2]
      end
    end

    context 'snac present, but lsgl / lgil combination not present' do
      setup do
        @la = LocalAuthority.create(snac: '1234', name: 'Happyland Council', local_directgov_id: '5679', tier: 'district')
        @lai = @la.local_interactions.create(lgsl_code: '902', lgil_code: '234', url: 'http://example.com/hats')
      end

      should 'detect a interaction as interaction_not_in_input if snac present, but lgsl/lgil combination not present in input' do
        collected = []
        LocalAuthorityInteractionGhostDetector.new(@input).detect_ghosts do |la, lai, ghost_status|
          collected << [la, lai, ghost_status]
        end

        assert_equal 1, collected.size
        detected = collected.first
        assert_equal @la, detected[0]
        assert_equal @lai, detected[1]
        assert_equal :interaction_not_in_input, detected[2]
      end
    end

    context 'snac / lsgl / lgil combination present' do
      context 'with full url' do
        setup do
          @la = LocalAuthority.create(snac: '1234', name: 'Happyland Council', local_directgov_id: '5679', tier: 'district')
          @lai = @la.local_interactions.create(lgsl_code: '901', lgil_code: '234', url: 'http://example.com/hats')
        end

        should 'detect a interaction as interaction_in_input' do
          collected = []
          LocalAuthorityInteractionGhostDetector.new(@input).detect_ghosts do |la, lai, ghost_status|
            collected << [la, lai, ghost_status]
          end

          assert_equal 1, collected.size
          detected = collected.first
          assert_equal @la, detected[0]
          assert_equal @lai, detected[1]
          assert_equal :interaction_in_input, detected[2]
        end
      end

      context 'with "X" url' do
        setup do
          @la = LocalAuthority.create(snac: '1234', name: 'Happyland Council', local_directgov_id: '5679', tier: 'district')
          @lai = @la.local_interactions.create(lgsl_code: '901', lgil_code: '235', url: 'http://example.com/hats')
        end

        should 'detect a interaction as interaction_in_input' do
          collected = []

          LocalAuthorityInteractionGhostDetector.new(@input).detect_ghosts do |la, lai, ghost_status|
            collected << [la, lai, ghost_status]
          end

          assert_equal 1, collected.size
          detected = collected.first
          assert_equal @la, detected[0]
          assert_equal @lai, detected[1]
          assert_equal :interaction_in_input_to_be_deleted, detected[2]
        end
      end
    end
  end

end
