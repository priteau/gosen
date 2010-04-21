# Gosen

Gosen is a Ruby library for the [Grid'5000 RESTful API](https://api.grid5000.fr/).
It relies on the [Restfully library](http://github.com/crohr/restfully) for interacting with the API.

## Features

Currently, it allows to submit deployments that retry automatically when too many nodes failed, similarly to [Katapult](http://www.loria.fr/~lnussbau/katapult.html).

## Installation

    $ gem install gosen

## Usage

The following example deploys the latest version of the Lenny-x64-big environment on the paramount-1 and paramount-2 nodes.
If both nodes are not successfully deployed, Gosen retries again (in this case, at most 5 deployment are submitted).

    #!/usr/bin/env ruby

    require 'gosen'
    require 'logger'
    require 'restfully'

    logger = Logger.new(STDOUT)

    Restfully::Session.new(:configuration_file => '~/.grid5000') do |grid, session|
      site = grid.sites[:rennes]
      nodes = [ 'paramount-1.rennes.grid5000.fr', 'paramount-2.rennes.grid5000.fr' ]
      deployment = Gosen::Deployment.new(site, 'lenny-x64-big', nodes,
      {
        :logger => logger,
        :max_deploy_runs => 5,
        :min_deployed_nodes => nodes.length,
        :ssh_public_key => File.read(File.expand_path('~/.ssh/authorized_keys'))
      })
      deployment.join
    end

The logger allows to print information about the deployment, in a style similar to Katapult:

    I, [2010-04-21T11:31:09.351803 #21673]  INFO -- : Kadeploy run 1 with 2 nodes (0 already deployed, need 2 more)
    I, [2010-04-21T11:37:11.817323 #21673]  INFO -- : Nodes deployed: paramount-1.rennes.grid5000.fr paramount-2.rennes.grid5000.fr
    I, [2010-04-21T11:37:11.817440 #21673]  INFO -- : Had to run 1 kadeploy runs, deployed 2 nodes

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Pierre Riteau. See LICENSE for details.
