module Gosen
  class DeploymentRun
    # Time between two checks of the deployment run status
    POLLING_TIME = 10

    attr_reader :environment, :nodes, :site, :ssh_public_key

    # Launch a new deployment run
    # @param [Restfully:Resource] site the deployment site, as a restfully resource
    # @param [String] environment the name of the environment to deploy
    # @param [Enumerable] nodes the list of nodes to deploy to
    # @param [Hash] options options
    def initialize(site, environment, nodes, options = {})
      @site = site
      @environment = environment
      @nodes = nodes
      @good_nodes = []
      @bad_nodes = Array.new(@nodes)
      @api_options = {}

      if options[:ssh_public_key]
        @api_options[:key] = @ssh_public_key = options[:ssh_public_key]
      end
      submit_deployment
    end

    def terminated?
      @deployment_resource['status'] != 'processing'
    end

    def good_nodes
      raise Gosen::Error unless terminated?
      @good_nodes.sort
    end

    def bad_nodes
      raise Gosen::Error unless terminated?
      @bad_nodes.sort
    end

    def submit_deployment
      @deployment_resource = @site.deployments.submit({
        :environment => @environment,
        :nodes => @bad_nodes,
      }.merge(@api_options))
    end

    # Wait for a deployment to complete
    def join
      wait_for_completion
      update_nodes
    end

    # Wait for a single deployment run to complete
    def wait_for_completion
      until terminated? do
        Kernel.sleep(Gosen::DeploymentRun::POLLING_TIME)
        @deployment_resource.reload
      end
      raise Gosen::Error if @deployment_resource['status'] == 'error'
    end

    def update_nodes
      @deployment_resource['result'].each do |node, node_result|
        if node_result['state'] == 'OK'
          @good_nodes << node
          @bad_nodes.delete(node)
        end
      end
    end
  end
end
