require 'rubygems'
require 'rack'
require 'camping'

require 'semanticspace_server.rb'
run Rack::Adapter::Camping.new( SemanticspaceServer )

