require 'spec_helper'
require 'cucloud'

PASSWORD_MINIMUM_LENGTH = 14
PASSWORD_MAXIMUM_AGE_DAYS = 90
PASSWORD_REUSE = 3
MAX_KEY_AGE = 90
HOURS_SINCE_LAST_RULE_EVALUATION = 24
IAM_KEY_WHITELIST = ENV["CUTILS_IAM_KEY_WHITELIST"].nil? ? \
  [] : \
  ENV["CUTILS_IAM_KEY_WHITELIST"].split(',').collect{|i| i.strip}

describe 'Account configuration check' do
  describe 'Check IAM Policies' do
    let(:iam_utils) do
      Cucloud::IamUtils.new
    end

    let(:account_alias) do
      iam_utils.get_account_alias
    end

    it 'should have an account alias' do
      puts "  #{account_alias}"
      expect(account_alias.length).to be > 1
    end

    it 'should have MFA enabled for the root user' do
      expect(iam_utils.root_user_mfa_enabled?).to be true
    end

    it 'should not have access keys for the root account' do
      expect(iam_utils.root_user_has_api_key?).to be false
    end

    it 'should have the Cornell Shibboleth provider' do
      expect(iam_utils.cornell_provider_configured?).to be true
    end

    it 'should not have IAM users with passwords defined' do
      expect(iam_utils.get_users.find { |x| x[:has_password] }).to be_nil
    end

    it "any access keys older than #{MAX_KEY_AGE} days should be whitelisted" do
      iam_utils.get_active_keys_older_than_n_days(MAX_KEY_AGE).each do |key|
        expect(IAM_KEY_WHITELIST).to include(key[:base_data].user_name)
      end
    end

    describe 'password policy' do
      let(:checks) do
        iam_utils.audit_password_policy(
          [
            { key: 'minimum_password_length', operator: 'GTE', value: PASSWORD_MINIMUM_LENGTH },
            { key: 'max_password_age', operator: 'LTE', value: PASSWORD_MAXIMUM_AGE_DAYS },
            { key: 'password_reuse_prevention', operator: 'LTE', value: PASSWORD_REUSE },
            { key: 'require_symbols', operator: 'EQ', value: true },
            { key: 'require_numbers', operator: 'EQ', value: true },
            { key: 'require_uppercase_characters', operator: 'EQ', value: true },
            { key: 'require_lowercase_characters', operator: 'EQ', value: true },
            { key: 'allow_users_to_change_password', operator: 'EQ', value: true },
            { key: 'hard_expiry', operator: 'EQ', value: false }
          ]
        )
      end

      it "should minimum password length of #{PASSWORD_MINIMUM_LENGTH}" do
        expect(checks.find { |x| x[:key] == 'minimum_password_length' }[:passes]).to be true
      end

      it "should have a maximum password age of #{PASSWORD_MAXIMUM_AGE_DAYS}" do
        expect(checks.find { |x| x[:key] == 'max_password_age' }[:passes]).to be true
      end

      it "should prevent password reuse of last #{PASSWORD_REUSE} passwords" do
        expect(checks.find { |x| x[:key] == 'password_reuse_prevention' }[:passes]).to be true
      end

      it 'should require symbols in the password' do
        expect(checks.find { |x| x[:key] == 'require_symbols' }[:passes]).to be true
      end

      it 'should require numbers in the password' do
        expect(checks.find { |x| x[:key] == 'require_numbers' }[:passes]).to be true
      end

      it 'should require uppercase characters in the password' do
        expect(checks.find { |x| x[:key] == 'require_uppercase_characters' }[:passes]).to be true
      end

      it 'should require lowercase characters in the password' do
        expect(checks.find { |x| x[:key] == 'require_lowercase_characters' }[:passes]).to be true
      end

      it 'should allow users to change their own password' do
        expect(checks.find { |x| x[:key] == 'allow_users_to_change_password' }[:passes]).to be true
      end

      it 'should allow users set new password after expiration ' do
        expect(checks.find { |x| x[:key] == 'hard_expiry' }[:passes]).to be true
      end
    end
  end

  describe 'Check AWS Config' do
    Cucloud::ConfigServiceUtils.get_available_regions.each do |region|
      describe "checking #{region}" do
        let(:cs_client) do
          Aws::ConfigService::Client.new(region: region)
        end

        let(:ct_client) do
          Aws::CloudTrail::Client.new(region: region)
        end

        let(:cs_util) do
          Cucloud::ConfigServiceUtils.new cs_client
        end

        let(:ct_util) do
          Cucloud::CloudTrailUtils.new(ct_client, cs_util)
        end

        let(:rule) do
          ct_util.get_config_rules.first
        end

        if region == 'us-east-1'
          describe 'CloudTrail rule' do
            it 'should have a rule enabled for CloudTrail' do
              expect(cs_util.rule_active?(rule)).to be true
            end

            it "should have run the CloudTrail trail rule in the last #{HOURS_SINCE_LAST_RULE_EVALUATION} hours" do
              expect(cs_util.hours_since_last_run(rule)).to be <= HOURS_SINCE_LAST_RULE_EVALUATION
            end

            it 'should be compliant' do
              expect(cs_util.rule_compliant?(rule)).to be true
            end
          end
        end

        it 'should have an active recorder' do
          expect(cs_util.recorder_active?).to be true
        end
      end
    end
  end

  describe 'Check CloudTrail configuration' do
    itso_trails = []
    global_trails = []
    ec2 = Aws::EC2::Client.new
    resp = ec2.describe_regions({})
    resp.regions.each do |region|
      describe "checking #{region.region_name}" do
        ct_client = Aws::CloudTrail::Client.new(region: region.region_name)
        ct_utils = Cucloud::CloudTrailUtils.new ct_client
        trails = ct_utils.get_cloud_trails

        itso_trails << trails.find { |x| ct_utils.cornell_itso_trail?(x) && ct_utils.trail_logging_active?(x) }
        global_trails << trails.find { |x| ct_utils.global_trail?(x) && ct_utils.trail_logging_active?(x) }
      end
    end

    it 'should have a global trail' do
      expect(global_trails.any?).to be true
    end

    it 'should have an ITSO trail' do
      expect(itso_trails.any?).to be true
    end
  end

  describe 'Check VPC configuration' do
    describe 'Verify that NACL rules are in place' do
      ec2 = Aws::EC2::Client.new
      resp = ec2.describe_regions({})
      resp.regions.each do |region|
        describe "checking #{region.region_name}" do
          let(:vpc_client) do
            Aws::EC2::Client.new(region: region.region_name)
          end

          let(:vpc_utils) do
            Cucloud::VpcUtils.new vpc_client
          end

          let(:comparison) do
            vpc_utils.compare_nacls(
              [
                { cidr: '0.0.0.0/0', egress: true, protocol: Cucloud::VpcUtils::PROTOCOL::TCP, from: 80, to: 80 },
                { cidr: '0.0.0.0/0', egress: true, protocol: Cucloud::VpcUtils::PROTOCOL::TCP, from: 443, to: 443 },
                { cidr: '0.0.0.0/0', egress: true, protocol: Cucloud::VpcUtils::PROTOCOL::TCP, from: 1024, to: 65_535 },
                { cidr: '10.0.0.0/8', egress: true, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '128.84.0.0/16', egress: true, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '128.253.0.0/16', egress: true, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '132.236.0.0/16', egress: true, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '192.35.82.0/24', egress: true, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '192.122.235.0/24', egress: true, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '192.122.236.0/24', egress: true, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '0.0.0.0/0', egress: false, protocol: Cucloud::VpcUtils::PROTOCOL::TCP, from: 80, to: 80 },
                { cidr: '0.0.0.0/0', egress: false, protocol: Cucloud::VpcUtils::PROTOCOL::TCP, from: 443, to: 443 },
                { cidr: '0.0.0.0/0', egress: false, protocol: Cucloud::VpcUtils::PROTOCOL::TCP, from: 1024, to: 65_535 },
                { cidr: '10.0.0.0/8', egress: false, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '128.84.0.0/16', egress: false, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '128.253.0.0/16', egress: false, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '132.236.0.0/16', egress: false, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '192.35.82.0/24', egress: false, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '192.122.235.0/24', egress: false, protocol: Cucloud::VpcUtils::PROTOCOL::ALL },
                { cidr: '192.122.236.0/24', egress: false, protocol: Cucloud::VpcUtils::PROTOCOL::ALL }
              ]
            )
          end

          it 'no VPCs should have any missing rules' do
            expect(comparison.find { |x| !x[:missing].empty? }).to be nil
          end
        end
      end
    end

    describe 'Verify that flow logs are enabled' do
      ec2 = Aws::EC2::Client.new
      resp = ec2.describe_regions({})
      resp.regions.each do |region|
        describe "checking #{region.region_name}" do
          let(:vpc_client) do
            Aws::EC2::Client.new(region: region.region_name)
          end

          let(:vpc_utils) do
            Cucloud::VpcUtils.new vpc_client
          end

          it 'all VPCs should have flow logs enabled' do
            expect(vpc_utils.flow_logs?).to be true
          end
        end
      end
    end
  end
end
