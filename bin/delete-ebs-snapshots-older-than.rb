#!/usr/bin/env ruby

require 'cucloud'
require 'aws-sdk'

num_days = ARGV[0] || 15

ec2_utils = Cucloud::Ec2Utils.new
ec2 = Aws::EC2::Client.new

stale_snap_shots = ec2_utils.find_ebs_snapshots(days_old: num_days.to_i)

stale_snap_shots.each do |stale_snap_shot|
    puts "processig snapshot #{stale_snap_shot}"

    begin
      ec2.delete_snapshot(snapshot_id: stale_snap_shot)
    rescue Exception => e
      puts e.message
    end
end
