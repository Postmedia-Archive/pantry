Log = require 'coloured-log'


log = new Log()
@create = (options) ->
	new MemoryStorage(options)

class MemoryStorage
	
	constructor: (options = {}) ->
		@config = {capacity: 1000} # default configuration
		@currentStock = {}	# key/value list of all current items in stock
		@stockCount = 0 # number of items currently in stock

		# update configuration and defaults
		@config[k] = v for k, v of options
	
		# recalculate new ideal capacity (unless alternate and valid ideal has been specified)
		@config.ideal = (@config.capacity * 0.9) unless options.ideal and @config.ideal <= (@config.capacity * 0.9)
		@config.ideal = (@config.capacity * 0.1) if @config.ideal < (@config.capacity * 0.1)
		
		#log.notice "Updated configuration"
		#log.info "Configuration: capacity=#{@config.capacity}, ideal=#{@config.ideal}"
	
	# retrieve a specific resource
	get: (key) ->
		return @currentStock[key]

	put: (item) ->
		if not @currentStock[item.options.key]?
			@stockCount++
			@cleanUp()
		@currentStock[item.options.key] = item
		
		#allow chaining, mostly for testing
		return @
	
	remove: (key) ->
		delete @currentStock[key]
		@stockCount--
	
	cleanUp: () ->
		if @stockCount > @config.capacity 
		
			log.warning "We're over capacity #{@stockCount} / #{@config.ideal}.  Time to clean up the pantry memory storage"
		
			expired = [] # used for efficient to prevent possibly looping through a second time
		
			# remove spoiled items
			for key, item of @currentStock
				if item.hasSpoiled()
					log.info "Spoiled #{key}"
					@remove key
				else if item.hasExpired()
					expired.push key
		
			if @stockCount > @config.capacity 
				# still over capacity.  let's toss out some expired times to make room
				for key in expired
					log.warning "Expired #{key}"
					@remove key
					break if @stockCount <= @config.ideal

			if @stockCount > @config.capacity
				# we have more stuff than we can handle.  time to toss some good stuff out
				# TODO: likely want to be smarter about which good items we toss
				# but without significant overhead
				for key, item of @currentStock
					log.alert "Tossed #{key}"
					@remove key
					break if @stockCount <= @config.ideal

			log.notice "Cleanup complete.  Currently have #{@stockCount} items in stock"