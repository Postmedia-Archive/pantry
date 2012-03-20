Log = require 'coloured-log'
redis = require 'redis'

module.exports = class RedisStorage
	constructor: (options = {}, callback) ->
		@config = {verbosity: 'DEBUG'} # default configuration
		
		# update configuration and defaults
		@config[k] = v for k, v of options
	
		#configure the log
		@log = new Log(@config.verbosity)
		
		#connect to redis server
		@client = redis.createClient()
		
		@client.on 'error', (err) =>
			@log.error err
			callback err, null
			
		@client.on 'ready', =>
			@log.notice "New redis storage created"
			callback null, @

	# retrieve a specific resource
	get: (key, callback) ->
		@client.get key, (err, results) ->
			callback err, if err then null else JSON.parse(results)

	put: (resource, callback) ->
		#allow chaining, mostly for testing
		@client.set resource.options.key, JSON.stringify(resource), (err, results) =>
			if err? or resource.options.maxLife is 0
				callback(err, results) if callback?
			else
				#expire item from cache when spoiled
				@client.expire resource.options.key, resource.options.maxLife, (err, results) =>
					callback(err, results) if callback?
		return @
