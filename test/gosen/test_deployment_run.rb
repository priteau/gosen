require 'helper'

class TestDeploymentRun < Test::Unit::TestCase
  context 'A new deployment run instance' do
    setup do
      @resource = {
        'status' => 'processing'
      }
      @deployments = mock()
      @deployments.expects(:submit).returns(@resource)
      @site = stub(:deployments => @deployments)
      @environment = 'lenny-x64-base'
      @nodes = [ 'paramount-1.rennes.grid5000.fr' ]
    end

    context 'without options' do
      setup do
        @deployment = Gosen::DeploymentRun.new(@site, @environment, @nodes)
      end

      should 'have a reader on site' do
        assert_equal(@site, @deployment.site)
      end

      should 'have a reader on environment' do
        assert_equal(@environment, @deployment.environment)
      end

      should 'have a reader on nodes' do
        assert_equal(@nodes, @deployment.nodes)
      end

      should 'return nil on ssh_public_key' do
        assert_equal(nil, @deployment.ssh_public_key)
      end

      should 'throw an error when accessing good_nodes' do
        assert_raise(Gosen::Error) {
          @deployment.good_nodes
        }
      end

      should 'throw an error when accessing bad_nodes' do
        assert_raise(Gosen::Error) {
          @deployment.bad_nodes
        }
      end
    end

    context 'with options' do
      should 'have a reader on ssh_public_key' do
        @ssh_public_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvwM1XBJCIMtAyQlweE7BVRtvgyKdwGTeYCI4AFlsTtti4y0Ipe5Hsygx3p7S0BHFiJsVZWDANMRwZ4tcjp8YnjnMkG2yp1jB1qgUf34t/MmEQL0KkoOk8tIIb28o7nTFYKO15mXJm9yBVS1JY8ozEfnA7s5hkrdnvM6h9Jv6VScp8C1XTKmpEy3sWOeUlmCkYftYSr1fLM/7qk9S2TnljA/CGiK9dq2mhJMjnDtulVrdpc1hbh+0oCzL6m2BfXX3v4q1ORml8o04oFeEYDN5qzZneL+FzK+YfJIidvsjZ9ziVTv+7Oy5ms4wvoKiUGNapP0v/meXXBU1KvFRof3VZQ== priteau@parallelogram.local'
        @deployment = Gosen::DeploymentRun.new(@site, @environment, @nodes, { :ssh_public_key => @ssh_public_key })
        assert_equal(@ssh_public_key, @deployment.ssh_public_key)
      end
    end
  end

  context 'A deployment run instance' do
    setup do
      @result = {
        'paramount-1.rennes.grid5000.fr' => {
          'last_cmd_stderr' => '',
          'ip' => '131.254.202.60',
          'last_cmd_exit_status' => 0,
          'state' => 'OK'
        }
      }
      @resource = mock()
      @resource.stubs(:[]).with('status').returns('processing', 'processing', 'terminated')
      @resource.expects(:[]).with('result').returns(@result)
      @resource.expects(:reload).twice
      Kernel.expects(:sleep).with(Gosen::DeploymentRun::POLLING_TIME).twice

      @deployments = mock()
      @deployments.expects(:submit).returns(@resource)
      @site = stub(:deployments => @deployments)
      @environment = 'lenny-x64-base'
      @nodes = [ 'paramount-1.rennes.grid5000.fr' ]
      @deployment = Gosen::DeploymentRun.new(@site, @environment, @nodes)
    end

    should 'wait for deployment completion and give access to the results' do
      assert_nothing_raised(Exception) {
        @deployment.join
      }
      assert_equal(@nodes, @deployment.good_nodes)
      assert_equal([], @deployment.bad_nodes)
    end
  end
end
