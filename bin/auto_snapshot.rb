#!/usr/bin/env ruby

require 'cucloud'
require 'optparse'

DEFAULT_DAYS = '5'.freeze

options = {
  add_tags: [],
  num_days: DEFAULT_DAYS,
  preserve_tags: []
}

OptionParser.new do |opts|
  opts.on('--apply-tag Key=Foo,Value=Bar',
          String,
          'Appy tag to snapshots created.') do |item|
    match = /^Key=([^,]+),Value=(.+)$/.match(item)
    unless match && match[1] && match[2] && !match[3]
      raise "Argument to --add-tag should be the string 'Key=<key>,Value=<value>'"
    end
    options[:add_tags] << { key: match[1], value: match[2] }
  end
  opts.on('--num-days N',
          Integer,
          "Snapshot volumes without snapshot in past N days (default #{DEFAULT_DAYS}).") do |item|
    options[:num_days] = item
  end
  opts.on('--preserve-tags x,y,z',
          Array,
          'Array of tag keys to preserve from volume.') do |item|
    item.each do |listitm|
      options[:preserve_tags] << listitm
    end
  end
  opts.on_tail('-h',
               '--help',
               'Command help') do
    puts opts
    exit
  end
end.parse!

# Restore prior version behavior where you could simply provide the number of days
# as the sole/first argument.
options[:num_days] = ARGV[0] if ARGV.length == 1

ec2_utils = Cucloud::Ec2Utils.new
snapshots_created = ec2_utils.backup_volumes_unless_recent_backup(options[:num_days].to_i,
                                                                  options[:preserve_tags],
                                                                  options[:add_tags])

snapshots_created.each do |snapshot_created|
  print "#{snapshot_created[:snapshot_id]} was created for volume #{snapshot_created[:volume]}"
  print " attached to instance #{snapshot_created[:instance_name]}" unless snapshot_created[:instance_name].empty?
  puts
end
