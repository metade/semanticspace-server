require 'rubygems'                                                                             
require 'yaml'
require 'drb'
require 'daemons'

require 'semanticspace'
include SemanticSpace

class SemanticSpaceBackend
  attr_accessor :space, :docs, :terms
  def initialize(config)
    puts "loading space: #{config[:space]}"
    @space = SemanticSpace::read_semanticspace(config[:space])
    @docs = YAML.load_file(config[:docs])
    @terms = YAML.load_file(config[:terms])
  end
end

config = YAML.load_file('config/semanticspace.yml')
if config[:drb_uri].nil?
  STDERR.puts("You must specify a :drb_uri in the config.")
end

Daemons.run_proc('semanticspace_daemon.rb', :backtrace => true) do
  backend = SemanticSpaceBackend.new(config)  
  DRb.start_service config[:drb_uri], backend
  DRb.thread.join
end
