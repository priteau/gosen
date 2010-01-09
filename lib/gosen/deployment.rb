require 'thread'

module Gosen
  class Deployment
    attr_reader :environment, :max_deploy_runs, :min_deployed_nodes, :nodes, :site, :ssh_public_key

    # Launch a new deployment
    # @param [Restfully::Resource] site the deployment site, as a restfully resource
    # @param [String] environment the name of the environment to deploy
    # @param [Enumerable] nodes the list of nodes to deploy to
    # @param [Hash] options options
    def initialize(site, environment, nodes, options = {})
      @site = site
      @environment = environment
      @nodes = Array.new(nodes)
      @good_nodes = []
      @bad_nodes = Array.new(nodes)
      @all_runs_done = false
      @api_options = {}

      @min_deployed_nodes = options[:min_deployed_nodes] || 1
      raise Gosen::Error if @min_deployed_nodes > @nodes.length || @min_deployed_nodes < 0

      @max_deploy_runs = options[:max_deploy_runs] || 1
      raise Gosen::Error if @max_deploy_runs < 1

      if options[:ssh_public_key]
        @api_options[:key] = @ssh_public_key = options[:ssh_public_key]
      end
    end

    def good_nodes
      raise Gosen::Error unless @all_runs_done
      @good_nodes
    end

    def bad_nodes
      raise Gosen::Error unless @all_runs_done
      @bad_nodes
    end

    def join
      @max_deploy_runs.times do |i|
        @deployment_resource = Gosen::DeploymentRun.new(@site, @environment, @bad_nodes)
        @deployment_resource.wait_for_completion
        @deployment_resource.update_nodes
        @bad_nodes = @deployment_resource.bad_nodes
        @good_nodes |= @deployment_resource.good_nodes
        if no_more_required?
          @all_runs_done = true
          return
        end
      end
      raise Gosen::Error.new('Not enough nodes')
    end

    def no_more_required?
      @good_nodes.length >= @min_deployed_nodes
    end
  end
end
