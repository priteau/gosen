require 'helper'

class TestGosen < Test::Unit::TestCase
  context 'A valid list of nodes' do
    setup do
      @nodes = [
        'grelon-1.nancy.grid5000.fr',
        'grelon-2.nancy.grid5000.fr',
        'paramount-1.rennes.grid5000.fr',
        'paramount-2.rennes.grid5000.fr'
      ]
    end

    should 'be indexable by their site name' do
      result = {
        'nancy' => [ 'grelon-1.nancy.grid5000.fr', 'grelon-2.nancy.grid5000.fr' ],
        'rennes' => [ 'paramount-1.rennes.grid5000.fr', 'paramount-2.rennes.grid5000.fr' ]
      }
      assert_equal(result, Gosen.index_nodes_by_site(@nodes))
    end
  end

  context 'An invalid list of nodes' do
    setup do
      @nodes_lists = [
        [ 'grelon' ],
        [ 'grelon.' ],
        [ 'grelon..grid5000.fr' ],
        [ 'grelon.abc123.grid5000.fr' ],
        [ 'grelon.nancy.grid50001.fr' ],
        [ 'grelon.nancy.grid5000.de' ]
      ]
    end

    should 'throw an error' do
      @nodes_lists.each do |nodes|
        assert_raise(Gosen::Error) { Gosen.index_nodes_by_site(nodes) }
      end
    end
  end
end
