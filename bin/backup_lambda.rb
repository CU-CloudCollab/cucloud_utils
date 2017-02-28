#!/usr/bin/env ruby

require 'cucloud'
require 'aws-sdk'

BACKUP_TIME = Time.new.strftime('%Y-%m-%d-%H:%M:%S')

s3_bucket_name = ARGV[0] || ENV['LAMBDA_S3_BUCKET']
backup_all_versions = ARGV[1] || 'YES'

def backup_lambda_function(function_name, version, lambda_utils, s3_bucket_name)
  file_path = lambda_utils.download_source_for_function(function_name, '/tmp', version)

  s3 = Aws::S3::Resource.new
  s3_key = function_name + '/' +
           BACKUP_TIME + '/' +
           function_name + '_' + version + '.zip'

  s3_obj = s3.bucket(s3_bucket_name).object(s3_key)
  s3_obj.upload_file(file_path)
  puts "backup complete for #{function_name}:#{version}"
end

lambda_utils = Cucloud::LambdaUtils.new
lambda_utils.get_all_function_names_for_account_region.each do |function_name|
  if backup_all_versions.eql?('YES')
    lambda_utils.get_all_versions_for_function(function_name).each do |version|
      backup_lambda_function(function_name, version, lambda_utils, s3_bucket_name)
    end
  else
    backup_lambda_function(function_name, '$LATEST', lambda_utils, s3_bucket_name)
  end
end
