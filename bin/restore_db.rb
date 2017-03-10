#!/usr/bin/env ruby

require 'cucloud'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: restore-db.rb [options]'

  opts.on('-d', '--db_name SID', 'Database name') { |v| options[:db_name] = v }
  opts.on('-i', '--db_id RDS_ID', 'Database name in RDS') { |v| options[:db_instance_identifier] = v }
  opts.on('-c', '--size INSTANCE_CLASS', 'RDS Instance Class') { |v| options[:db_instance_class] = v }
  opts.on('-t', '--db_snapshot SNAPSHOT_ID', 'snapshot identifier') { |v| options[:db_snapshot_identifier] = v }
  opts.on('-r', '--restore_from RESTORE_DB_ID', 'DB to restore from') { |v| options[:restore_from] = v }
  opts.on('-n', '--db_subnet_group_name NAME', 'db_subnet_group_name') { |v| options[:db_subnet_group_name] = v }
  opts.on('-o', '--option_group_name NAME', 'option_group_name') { |v| options[:option_group_name] = v }
  opts.on('-s', '--security-group NAME', 'security-group-id') { |v| options[:security_group_id] = v }

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

db_id = options.delete(:db_instance_identifier)
restore_from = options.delete(:restore_from)
security_group_id = options.delete(:security_group_id)

rds_utils = Cucloud::RdsUtils.new

rds_utils.restore_db(db_id, restore_from, options)
rds_utils.modify_security_group(db_id, [security_group_id]) unless security_group_id.nil?
