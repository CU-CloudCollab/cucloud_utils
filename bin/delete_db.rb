#!/usr/bin/env ruby

require 'cucloud'

db_id = ARGV[0]

rds_utils = Cucloud::RdsUtils.new
snapshot_name = "#{db_id}-#{Time.now.strftime('%Y-%m-%d-%H-%M-%S')}"

begin
  rds_utils.delete_db_instance(db_id, snapshot_name)
  puts "Completed deletion of #{db_id} creating snapshot #{snapshot_name}"
rescue Aws::RDS::Errors::DBInstanceNotFound
  puts "#{db_id} was not found"
end
