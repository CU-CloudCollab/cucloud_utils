require 'spec_helper'
require 'cucloud'

describe 'Account configuration ceck' do
    describe 'Check VPC configuration' do
        let(:vpc_utils) do
            Cucloud::VpcUtils.new
        end

        describe '#flow_logs?' do
            it 'should return true' do
                expect(vpc_utils.flow_logs?).to be true
            end
        end
    end
end
