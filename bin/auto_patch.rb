#!/usr/bin/env ruby

require 'cucloud'

tag_name = ARGV[0] || 'auto_patch'
tag_value = ARGV[0] || '1'

ec2_utils = Cucloud::Ec2Utils.new
ec2_utils.instances_to_patch_by_tag(tag_name, [tag_value])
