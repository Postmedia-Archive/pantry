Log = require 'coloured-log'
Memcached = require 'memcached'

module.exports = class MemcachedStorage
	constructor: (servers = "localhost:11211", options = {}, verbosity = Log.NOTICE) ->
		# configure the log
		@log = new Log(verbosity)
		
		# connect to redis server
		@client = new Memcached(servers, options)
				
		@client.on 'issue', (details) =>
			@log.warning details.toString()
		
		@client.on 'failure', (details) =>
			@log.error details.toString()
			
		@client.on 'reconnecting', (details) =>
			@log.notice details.toString()
			
		@client.on 'reconnected', (details) =>
			@log.info details.toString()
			
		@client.on 'remove', (details) =>
			@log.notice details.toString()

		@log.notice "New memcached storage created"
		@log.info "Servers: #{servers}"

	# retrieve a specific resource
	get: (key, callback) ->
		@client.get key, (err, results) ->
			if err then @log.error err
			callback err, if err or results is false then null else JSON.parse(results)

	# save a specific resource
	put: (resource, callback) ->
		@client.set resource.options.key, JSON.stringify(resource), resource.options.maxLife, (err, results) =>
			if err then @log.error err
			callback(err, results) if callback?
					
		#allow chaining, mostly for testing
		return @
