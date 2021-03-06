module Gosen
  class NullLogger
    def method_missing(method, *args)
      nil
    end
  end

  class Deployment
    attr_reader :environment, :logger, :max_deploy_runs, :min_deployed_nodes, :nodes, :site, :ssh_public_key

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
      @logger = options.delete(:logger) || NullLogger.new

      user_agent = @site.session.default_headers['User-Agent']
      @site.session.default_headers['User-Agent'] = "Gosen/#{Gosen::VERSION} #{user_agent}" unless user_agent =~ /^Gosen\/#{Gosen::VERSION}/

      @min_deployed_nodes = options.delete(:min_deployed_nodes) || 1
      raise Gosen::Error.new("Invalid minimal number of deployed nodes, should be between 0 and #{@nodes.length}") if @min_deployed_nodes > @nodes.length || @min_deployed_nodes < 0

      @max_deploy_runs = options.delete(:max_deploy_runs) || 1
      raise Gosen::Error.new("Invalid maximal number of deployments, should be greater than or equal to 1") if @max_deploy_runs < 1

      @continue_if_error = options.delete(:continue_if_error) || false

      if options[:ssh_public_key]
        @ssh_public_key = options[:ssh_public_key]
      end

      @api_options = options
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
        @deployment_run = Gosen::DeploymentRun.new(@site, @environment, @bad_nodes, @api_options)
        @logger.info("Kadeploy run #{i + 1} with #{@bad_nodes.length} nodes (#{@good_nodes.length} already deployed, need #{@min_deployed_nodes - @good_nodes.length} more)")
        begin
          @deployment_run.wait_for_completion
        rescue Gosen::Error => e
          if e.message =~ /^Deployment error/ && @continue_if_error
            @logger.warn("Deployment error: #{@deployment_run.deployment_resource['output']}")
            @logger.warn("Continuing because continue_if_error is set")
            next
          else
            raise e
          end
        end
        @deployment_run.update_nodes
        @bad_nodes = @deployment_run.bad_nodes
        @good_nodes |= @deployment_run.good_nodes
        @logger.info("Nodes deployed: #{@deployment_run.good_nodes.join(' ')}") unless @deployment_run.good_nodes.empty?
        @logger.info("Nodes which failed: #{@deployment_run.bad_nodes.join(' ')}") unless @deployment_run.bad_nodes.empty?
        if no_more_required?
          @all_runs_done = true
          @logger.info("Had to run #{i + 1} kadeploy runs, deployed #{@good_nodes.length} nodes")
          return
        end
      end
      raise Gosen::Error.new("Not enough nodes deployed after #{@max_deploy_runs} deployment(s): needed #{@min_deployed_nodes} nodes, got only #{@good_nodes.length}")
    end

    def deployment_resource
      @deployment_run.deployment_resource rescue nil
    end

    def no_more_required?
      @good_nodes.length >= @min_deployed_nodes
    end
  end
end
