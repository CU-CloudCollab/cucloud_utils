#!/usr/bin/env ruby
require 'cucloud'
require 'table_print'

iam_utils = Cucloud::IamUtils.new
key_report = iam_utils.get_active_keys_older_than_n_days(-1).sort_by { |k| k[:days_old] }.map do |key|
  {
    user: key[:base_data].user_name,
    key_id: key[:base_data].access_key_id,
    key_age_days: key[:days_old]
  }
end

tp key_report
