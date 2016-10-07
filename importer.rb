require 'net/http'
require 'jsonmodel'

def show_usage
  raise "Usage: #{$0} <backend URL> <repo id> <username> <password> <import file>"
end

$backend_url = ARGV.fetch(0) { show_usage }
$repo_id = ARGV.fetch(1) { show_usage }
$user = ARGV.fetch(2) { show_usage }
$password = ARGV.fetch(3) { show_usage }
$import_file = ARGV.fetch(4) { show_usage }

$basedir = File.expand_path(File.join(File.dirname(__FILE__)))

include JSONModel

class PermissiveValidator
  def method_missing(*)
    true
  end
end

JSONModel::init(:client_mode => true,
                :url => $backend_url,
                :enum_source => PermissiveValidator.new)

def self.login!(username, password)
  uri = JSONModel(:user).uri_for("#{username}/login?expiring=false")

  response = JSONModel::HTTP.post_form(uri, 'password' => password)

  if response.code == '200'
    Thread.current[:backend_session] = JSON.parse(response.body)['session']
  else
    raise "ArchivesSpace Login failed: #{response.body}"
  end
end


def batch_import(file)
  JSONModel::HTTP.post_json_file(URI.join(JSONModel::HTTP.backend_url, "/repositories/#{$repo_id}/batch_imports?skip_results=true&migration=true"),
                                 file) do |response|
    response.read_body do |chunk|
      p chunk
    end
  end
end


p "-- Importing: #{$import_file}"
login!($user, $password)
batch_import($import_file)
p "-- DONE"