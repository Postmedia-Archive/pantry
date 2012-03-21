Log = require 'coloured-log'
redis = require 'redis'

module.exports = class RedisStorage
	constructor: (port = 6379, host = 'localhost', options = {}, verbosity = 'ERROR') ->	
		# configure the log
		@log = new Log(verbosity)
		
		# connect to redis server
		@client = redis.createClient(port, host)
				
		@client.on 'error', (err) =>
			@log.error err
			
		@client.on 'ready', =>
			@log.info "Connected to Host: #{host}, Port: #{port}"
			
		# optionally send password
		@client.auth options.auth if options.auth?

		@log.notice "New redis storage created"
		
	# retrieve a specific resource
	get: (key, callback) ->
		@client.get key, (err, results) ->
			@log.error err if err
			callback err, if err then null else JSON.parse(results)

	# save a specific resource
	put: (resource, callback) ->
		@client.set resource.options.key, JSON.stringify(resource), (err, results) =>
			if err?
				@log.error err
				callback(err, results) if callback?
			else
				#expire item from cache when spoiled (no need to wait)
				@client.expire resource.options.key, resource.options.maxLife, ->
					# TODO: log error here
				callback(err, results) if callback?
					
		#allow chaining, mostly for testing
		return @
