require 'restfully'
require 'gosen/deployment_run'
require 'gosen/deployment'
require 'gosen/error'

module Gosen
  VERSION = "0.2.1"

  # Extracts the site part of a Grid'5000 node hostname, and returns a hash indexing the nodes by their site
  # Example:
  #
  #   Input is:
  #   [
  #     'paramount-1.rennes.grid5000.fr',
  #     'paramount-2.rennes.grid5000.fr',
  #     'grelon-1.nancy.grid5000.fr',
  #     'grelon-2.nancy.grid5000.fr'
  #   ]
  #
  #   Result is:
  #   {
  #     'rennes' => [ 'paramount-1.rennes.grid5000.fr', 'paramount-2.rennes.grid5000.fr' ],
  #     'nancy' => [ 'grelon-1.nancy.grid5000.fr', 'grelon-2.nancy.grid5000.fr' ]
  #   }
  def self.index_nodes_by_site(nodes)
    result = Hash.new { |hash, key| hash[key] = Array.new }
    nodes.each do |node|
      if node =~ /^[a-z]+-[0-9]+\.([a-z]+)\.grid5000\.fr$/
        site = $1
        result[site] << node
      else
        raise Gosen::Error
      end
    end
    return result
  end
end
