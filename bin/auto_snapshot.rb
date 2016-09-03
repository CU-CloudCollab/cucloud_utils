#!/usr/bin/env ruby

require 'cucloud'

num_days = ARGV[0] || 5

ec2_utils = Cucloud::Ec2Utils.new
snapshots_created = ec2_utils.backup_volumes_unless_recent_backup(num_days.to_i)

snapshots_created.each do |snapshot_created|
  print "#{snapshot_created[:snapshot_id]} was created for volume #{snapshot_created[:volume]}"
  print " attached to instance #{snapshot_created[:instance_name]}" unless snapshot_created[:instance_name].empty?
  puts
end
