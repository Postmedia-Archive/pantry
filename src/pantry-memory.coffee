Log = require 'coloured-log'

module.exports = class MemoryStorage
	
	constructor: (options = {}, verbosity = Log.NOTICE) ->
		# default configuration
		@config = {capacity: 1000}
		
		# update configuration and defaults
		@config[k] = v for k, v of options
	
		#configure the log
		@log = new Log(verbosity)
				
		# recalculate new ideal capacity (unless alternate and valid ideal has been specified)
		@config.ideal = (@config.capacity * 0.9) unless options.ideal and @config.ideal <= (@config.capacity * 0.9)
		@config.ideal = (@config.capacity * 0.1) if @config.ideal < (@config.capacity * 0.1)
		
		# init stock
		@clear()

		@log.notice "New memory storage created"
		@log.info "Configuration: capacity=#{@config.capacity}, ideal=#{@config.ideal}"
	
	#remove all cached resources
	clear: ->
		@currentStock = {}
		@stockCount = 0
	
	# retrieve a specific resource
	get: (key, callback) ->
		callback null, @currentStock[key]
		return

	# save a specific resource
	put: (resource, callback) ->
		if not @currentStock[resource.options.key]?
			@stockCount++
			@cleanUp()
		@currentStock[resource.options.key] = resource
		
		#support for callback
		callback(null, resource) if callback?
		
		#allow chaining, mostly for testing
		return @
	
	# you guessed it!  removed a specific item
	remove: (key) ->
		if @currentStock[key]
			delete @currentStock[key]
			@stockCount--
	
	# removes items from storage if over capacity
	cleanUp: () ->
		if @stockCount > @config.capacity 
		
			@log.warning "We're over capacity #{@stockCount} / #{@config.ideal}.  Time to clean up the pantry memory storage"
			
			now = new Date()
			expired = [] # used for efficiency to prevent possibly looping through a second time
		
			# remove spoiled items
			for key, resource of @currentStock
				if resource.spoilsOn < now
					@log.info "Spoiled #{key}"
					@remove key
				else if resource.bestBefore < now
					expired.push key
		
			if @stockCount > @config.capacity 
				# still over capacity.  let's toss out some expired times to make room
				for key in expired
					@log.notice "Expired #{key}"
					@remove key
					break if @stockCount <= @config.ideal

			if @stockCount > @config.capacity
				# we have more stuff than we can handle.  time to toss some good stuff out
				# TODO: likely want to be smarter about which good items we toss
				# but without significant overhead
				for key, resource of @currentStock
					@log.warning "Tossed #{key}"
					@remove key
					break if @stockCount <= @config.ideal

			@log.notice "Cleanup complete.  Currently have #{@stockCount} items in stock"