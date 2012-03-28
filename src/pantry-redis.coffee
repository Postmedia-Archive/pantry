Log = require 'coloured-log'
redis = require 'redis'

module.exports = class RedisStorage
	constructor: (port = 6379, host = 'localhost', options = {}, verbosity = 'ERROR') ->	
		# configure the log
		@log = new Log(verbosity)
		@up = false # used to track status of connection
		
		# connect to redis server
		@client = redis.createClient(port, host)
				
		@client.on 'end', =>
			@log.warning "Disconnected from Host: #{host}, Port: #{port}"
			@up = false

		@client.on 'error', (err) =>
			@log.error err.toString()
			@up = false
			
		@client.on 'ready', =>
			@log.info "Connected to Host: #{host}, Port: #{port}"
			@up = true
			
		# optionally send password
		@client.auth options.auth if options.auth?

		@log.notice "New redis storage created"
		
	# retrieve a specific resource
	get: (key, callback) ->
		if @up
			@client.get key, (err, results) =>
				@log.error err if err
				callback err, if err then null else JSON.parse(results)
		else
			callback "Redis server currently unavailable"

	# save a specific resource
	put: (resource, callback) ->
		if @up
			@client.set resource.options.key, JSON.stringify(resource), (err, results) =>
				if err?
					@log.error err
					callback(err, results) if callback?
				else
					#expire item from cache when spoiled (no need to wait)
					@client.expire resource.options.key, resource.options.maxLife, ->
						# TODO: log error here
					callback(err, results) if callback?
		else
			callback "Redis server currently unavailable"
					
		#allow chaining, mostly for testing
		return @
