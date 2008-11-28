require 'rubygems'
require 'yaml'
require 'json'
require 'camping'
require 'mime/types'

require 'camping_goodies'
require 'semanticspace'
include SemanticSpace

Camping.goes :SemanticspaceServer
module SemanticspaceServer
  include CampingGoodies
  
  if $space.nil?
    config = YAML.load_file('config/semanticspace.yml')
    puts "loading space: #{config[:space]}"
    $space = SemanticSpace::read_semanticspace(config[:space])
    $docs = YAML.load_file(config[:docs])
    $terms = YAML.load_file(config[:terms])
  end
  
  def space
    $space
  end
end

class Item
  attr_accessor :name, :ident, :similarity
  def initialize(type, struct)
    self.ident = struct.ident
    self.similarity = struct.similarity
    self.name = case type
      when :docs then doc_name(ident)
      when :terms then term_name(ident)
    end
  end
  
  protected
  
  def doc_name(id)
    $docs[id]
  end
  
  def term_name(id)
    $terms[id]
  end
end

module SemanticspaceServer::Controllers
  class Index < R '/'
    def get
      @title = 'Semantic Space Server'
      render :index
    end
  end
  
  class About < R '/about'
    def get
      render :about
    end
  end
  
  class Docs < R '/docs', '/docs\.(.*)'
    def get(format=nil)
      @docs = space.list_docs(true)
      respond_to(format, @docs) or render(:docs)
    end
  end
  
  class Doc < R '/docs/(.*?)', '/docs/(.*?)\.(.*)'
    def get(doc, format=nil)
      return not_found('doc', doc) unless space.list_docs(TRAINING_DOCUMENT_SPACE).include?(doc)
      @docs = munge(:docs, space.search_with_doc(doc, true, TRAINING_DOCUMENT_SPACE, dimensions, 10))
      @terms = munge(:terms, space.search_with_doc(doc, true, TERM_SPACE, dimensions, 10).map)
      obj = { :docs => @docs, :terms => @terms }
      respond_to(format, obj) or render(:doc)
    end
  end
  
  class Terms < R '/terms', '/terms\.(.*)'
    def get(format=nil)
      @terms = space.list_terms
      respond_to(format, @terms) or render(:terms)
    end
  end
  
  class Term < R '/terms/(.*?)', '/terms/(.*?)\.(.*)'
    def get(term, format=nil)
      return not_found('term', term) unless space.list_terms.include?(term)
      @docs = munge(:docs, space.search_with_term(term, TRAINING_DOCUMENT_SPACE, dimensions)[0,limit])
      @terms = munge(:terms, space.search_with_term(term, TERM_SPACE, dimensions)[0,limit])
      obj = { :docs => @docs, :terms => @terms }
      respond_to(format, obj) or render(:term)
    end
  end
  
  protected
  
  def munge(type, array)
    array.map { |i| Item.new(type, i) }
  end
  
  def dimensions
    44
  end
  
  def limit
    10
  end
end

# this madness allows you to call R() from the ERB
module CampingGoodies
  include SemanticspaceServer::Controllers
end
