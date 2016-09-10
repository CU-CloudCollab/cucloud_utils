#!/usr/bin/env ruby

require 'cucloud'
require 'optparse'

OPTIONS = {}

OptionParser.new do |opt|
  opt.on('--t tag_name') { |o| OPTIONS[:tag_name] = o }
  opt.on('--v tag_value') { |o| OPTIONS[:tag_value] = o }
  opt.on('--a action (start,stop)') { |o| OPTIONS[:action] = o }
end.parse!

tag_name = OPTIONS[:tag_name] || 'environment'
tag_value = OPTIONS[:tag_value] || 'development'
action = OPTIONS[:action] || ''
ec2 = Cucloud::Ec2Utils.new

if (["start","stop"].include? action)
  holder = ec2.get_instances_by_tag(tag_name, [tag_value])
  if holder.reservations.count > 0
    holder.reservations[0].instances.each do |i|
      if action == "stop"
        ec2.stop_instance(i.instance_id)
        puts "Instance #{action} @ " + Time.now.strftime("%m/%d/%Y %H:%M") + ": "+ i.instance_id
      end
      if action == "start"
        ec2.start_instance(i.instance_id)
        puts "Instance #{action} @ " + Time.now.strftime("%m/%d/%Y %H:%M") + ": "+ i.instance_id
      end
    end
  else
    puts "No instances match your tag name and value"
  end
else
  puts "Need to specify 'start' or 'stop' for scheduling of starting/stopping instances using --ad"
end
