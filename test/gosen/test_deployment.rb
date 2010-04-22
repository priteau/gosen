require 'helper'

class TestDeployment < Test::Unit::TestCase
  context 'A deployment instance' do
    setup do
      @site = mock()
      @site_name = "Rennes"
      @site.stubs(:name).returns(@site_name)
      @environment = 'lenny-x64-base'
      @nodes = [ 'paramount-1.rennes.grid5000.fr', 'paramount-2.rennes.grid5000.fr' ]
      @null_logger = Gosen::NullLogger.new
      Gosen::NullLogger.stubs(:new).returns(@null_logger)
    end

    context 'without options' do
      setup do
        @deployment = Gosen::Deployment.new(@site, @environment, @nodes)
      end

      should 'have a reader on environment' do
        assert_equal(@environment, @deployment.environment)
      end

      should 'have a reader on nodes' do
        assert_equal(@nodes, @deployment.nodes)
      end

      should 'have a reader on site' do
        assert_equal(@site, @deployment.site)
      end

      should 'have a reader on ssh_public_key' do
        assert_equal(@ssh_public_key, @deployment.ssh_public_key)
      end

      should 'have a reader on logger defaulting to NullLogger' do
        assert_equal(@null_logger, @deployment.logger)
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

      should 'have a reader on min_deployed_nodes defaulting to 1' do
        assert_equal(1, @deployment.min_deployed_nodes)
      end

      should 'have a reader on max_deploy_runs defaulting to 1' do
        assert_equal(1, @deployment.max_deploy_runs)
      end
    end

    context 'with options' do
      should 'have a reader on ssh_public_key' do
        @ssh_public_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvwM1XBJCIMtAyQlweE7BVRtvgyKdwGTeYCI4AFlsTtti4y0Ipe5Hsygx3p7S0BHFiJsVZWDANMRwZ4tcjp8YnjnMkG2yp1jB1qgUf34t/MmEQL0KkoOk8tIIb28o7nTFYKO15mXJm9yBVS1JY8ozEfnA7s5hkrdnvM6h9Jv6VScp8C1XTKmpEy3sWOeUlmCkYftYSr1fLM/7qk9S2TnljA/CGiK9dq2mhJMjnDtulVrdpc1hbh+0oCzL6m2BfXX3v4q1ORml8o04oFeEYDN5qzZneL+FzK+YfJIidvsjZ9ziVTv+7Oy5ms4wvoKiUGNapP0v/meXXBU1KvFRof3VZQ== priteau@parallelogram.local'
        @deployment = Gosen::Deployment.new(@site, @environment, @nodes, { :ssh_public_key => @ssh_public_key })
        assert_equal(@ssh_public_key, @deployment.ssh_public_key)
      end

      should 'have a reader on min_deployed_nodes' do
        @min_deployed_nodes = @nodes.length
        @deployment = Gosen::Deployment.new(@site, @environment, @nodes, { :min_deployed_nodes => @min_deployed_nodes })
        assert_equal(@min_deployed_nodes, @deployment.min_deployed_nodes)
      end

      should 'have a reader on logger' do
        logger = mock()
        @deployment = Gosen::Deployment.new(@site, @environment, @nodes, { :logger => logger })
        assert_equal(logger, @deployment.logger)
      end

      should 'throw an error if not enough nodes are available from the start' do
        assert_raise(Gosen::Error) {
          Gosen::Deployment.new(@site, @environment, @nodes, { :min_deployed_nodes => @nodes.length + 1 })
        }
      end

      should 'throw an error if min_deployed_nodes is negative' do
        assert_raise(Gosen::Error) {
          Gosen::Deployment.new(@site, @environment, @nodes, { :min_deployed_nodes => -1 })
        }
      end

      should 'have a reader on max_deploy_runs' do
        @max_deploy_runs = 42
        @deployment = Gosen::Deployment.new(@site, @environment, @nodes, { :max_deploy_runs => @max_deploy_runs })
        assert_equal(@max_deploy_runs, @deployment.max_deploy_runs)
      end

      should 'throw an error if max_deploy_runs is less than 1' do
        assert_raise(Gosen::Error) {
          Gosen::Deployment.new(@site, @environment, @nodes, { :max_deploy_runs => -1 })
        }
        assert_raise(Gosen::Error) {
          Gosen::Deployment.new(@site, @environment, @nodes, { :max_deploy_runs => 0 })
        }
        assert_nothing_raised(Gosen::Error) {
          Gosen::Deployment.new(@site, @environment, @nodes, { :max_deploy_runs => 1 })
        }
      end
    end

    context 'that is in progress' do
      setup do
        Kernel.stubs(:sleep).with(Gosen::DeploymentRun::POLLING_TIME)
        @site_deployments = mock()
        @site.stubs(:deployments).returns(@site_deployments)
        @logger = mock()

        @deployment_resource = mock()
        @deployment_resource.stubs(:reload)
        @deployment_resource.stubs(:[]).with('status').returns('processing', 'processing', 'terminated')
      end

      should 'submit a deployment run and wait for the result' do
        @deployment_result = {
          'paramount-1.rennes.grid5000.fr' => { 'state' => 'OK' },
          'paramount-2.rennes.grid5000.fr' => { 'state' => 'OK' }
        }
        @deployment_resource.expects(:[]).with('result').returns(@deployment_result)
        @site_deployments.expects(:submit).with({ :environment => @environment, :nodes => @nodes }).returns(@deployment_resource)
        @min_deployed_nodes = 2
        @logger.expects(:info).with("Kadeploy run 1 with #{@nodes.length} nodes (0 already deployed, need #{@min_deployed_nodes} more)")
          @logger.expects(:info).with("Nodes deployed: paramount-1.rennes.grid5000.fr paramount-2.rennes.grid5000.fr")
        @logger.expects(:info).with("Had to run 1 kadeploy runs, deployed #{@deployment_result.length} nodes")

        @deployment = Gosen::Deployment.new(@site, @environment, @nodes, { :logger => @logger, :min_deployed_nodes => @min_deployed_nodes })
        @deployment.join
        assert_equal(@nodes, @deployment.good_nodes)
        assert_equal([], @deployment.bad_nodes)
      end

      should 'throw an error when not enough nodes are available after all runs are completed' do
        @deployment_result = {
          'paramount-1.rennes.grid5000.fr' => { 'state' => 'OK' },
          'paramount-2.rennes.grid5000.fr' => { 'state' => 'KO' }
        }
        @deployment_resource.expects(:[]).with('result').returns(@deployment_result)
        @site_deployments.expects(:submit).with({ :environment => @environment, :nodes => @nodes }).returns(@deployment_resource)

        @deployment = Gosen::Deployment.new(@site, @environment, @nodes, { :min_deployed_nodes => 2 })
        assert_raise(Gosen::Error) {
          @deployment.join
        }
      end

      should 'submit new deployment runs when needed' do
        @ssh_public_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvwM1XBJCIMtAyQlweE7BVRtvgyKdwGTeYCI4AFlsTtti4y0Ipe5Hsygx3p7S0BHFiJsVZWDANMRwZ4tcjp8YnjnMkG2yp1jB1qgUf34t/MmEQL0KkoOk8tIIb28o7nTFYKO15mXJm9yBVS1JY8ozEfnA7s5hkrdnvM6h9Jv6VScp8C1XTKmpEy3sWOeUlmCkYftYSr1fLM/7qk9S2TnljA/CGiK9dq2mhJMjnDtulVrdpc1hbh+0oCzL6m2BfXX3v4q1ORml8o04oFeEYDN5qzZneL+FzK+YfJIidvsjZ9ziVTv+7Oy5ms4wvoKiUGNapP0v/meXXBU1KvFRof3VZQ== priteau@parallelogram.local'
        @deployment_resource1 = mock()
        @deployment_resource2 = mock()
        @deployment_resource1.stubs(:reload)
        @deployment_resource2.stubs(:reload)

        @deployment_result1 = {
          'paramount-1.rennes.grid5000.fr' => { 'state' => 'OK' },
          'paramount-2.rennes.grid5000.fr' => { 'state' => 'KO' }
        }
        @deployment_result2 = {
          'paramount-2.rennes.grid5000.fr' => { 'state' => 'OK' }
        }
        @deployment_resource1.stubs(:[]).with('status').returns('processing', 'processing', 'terminated')
        @deployment_resource2.stubs(:[]).with('status').returns('processing', 'processing', 'terminated')
        @deployment_resource1.expects(:[]).with('result').returns(@deployment_result1)
        @deployment_resource2.expects(:[]).with('result').returns(@deployment_result2)
        @min_deployed_nodes = 2
        @site_deployments.expects(:submit).with({ :environment => @environment, :nodes => @nodes, :key => @ssh_public_key }).returns(@deployment_resource1)
        @site_deployments.expects(:submit).with({ :environment => @environment, :nodes => [ 'paramount-2.rennes.grid5000.fr'], :key => @ssh_public_key }).returns(@deployment_resource2)
        @logger.expects(:info).with("Kadeploy run 1 with 2 nodes (0 already deployed, need 2 more)")
        @logger.expects(:info).with("Nodes deployed: paramount-1.rennes.grid5000.fr")
        @logger.expects(:info).with("Nodes which failed: paramount-2.rennes.grid5000.fr")
        @logger.expects(:info).with("Kadeploy run 2 with 1 nodes (1 already deployed, need 1 more)")
        @logger.expects(:info).with("Nodes deployed: paramount-2.rennes.grid5000.fr")
        @logger.expects(:info).with("Had to run 2 kadeploy runs, deployed 2 nodes")

        @deployment = Gosen::Deployment.new(@site, @environment, @nodes, { :logger => @logger, :min_deployed_nodes => @min_deployed_nodes, :max_deploy_runs => 2, :ssh_public_key => @ssh_public_key })
        @deployment.join
        assert_equal(@nodes, @deployment.good_nodes)
        assert_equal([], @deployment.bad_nodes)
      end
    end
  end
end
