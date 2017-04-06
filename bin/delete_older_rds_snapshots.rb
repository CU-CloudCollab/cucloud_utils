#!/usr/bin/env ruby

require 'cucloud'

num_days = ARGV[0] || 15

rds_client = Aws::RDS::Client.new
rds_utils = Cucloud::RdsUtils.new

stale_snap_shots = rds_utils.find_rds_snapshots({ days_old: num_days.to_i }, 'manual')

stale_snap_shots.each do |stale_snap_shot|
  puts "Deleting #{stale_snap_shot}"
  rds_client.delete_db_snapshot(db_snapshot_identifier: stale_snap_shot)
end
