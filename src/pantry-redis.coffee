Log = require 'coloured-log'
redis = require 'redis'

module.exports = class RedisStorage
	constructor: (options = {}) ->
		# default configuration
		@config = {host: 'localhost', port: 6379, auth: null, verbosity: 'ERROR'} 
		
		# update configuration and defaults
		@config[k] = v for k, v of options
	
		# configure the log
		@log = new Log(@config.verbosity)
		
		# connect to redis server
		@client = redis.createClient(@config.port, @config.host)
				
		@client.on 'error', (err) =>
			@log.error err
			
		@client.on 'ready', =>
			@log.notice "New redis storage created"
			@log.info "Host: #{@config.host}, Port: #{@config.port}"
			
		# optionally send password
		@client.auth @config.auth if @config.auth?

	# retrieve a specific resource
	get: (key, callback) ->
		@client.get key, (err, results) ->
			callback err, if err then null else JSON.parse(results)

	# save a specific resource
	put: (resource, callback) ->
		@client.set resource.options.key, JSON.stringify(resource), (err, results) =>
			if err? or resource.options.maxLife is 0
				callback(err, results) if callback?
			else
				#expire item from cache when spoiled (no need to wait)
				@client.expire resource.options.key, resource.options.maxLife, ->
					# TODO: log error here
				callback(err, results) if callback?
					
		#allow chaining, mostly for testing
		return @
