EventEmitter = require('events').EventEmitter
request = require 'request'
xml2js = require 'xml2js'

currentStock = {}	# key/value list of all current items in stock
stockCount = 0 # number of items currently in stock

config = { shelfLife: 60, maxLife: 300, capacity: 1000, ideal: 900}

# update configuration and defaults
@configure = (options) ->	
	config[k] = v for k, v of options
	
	# recalculate new ideal capacity (unless alternate and valid ideal has been specified)
	config.ideal = (config.capacity * 0.9) unless options.ideal and config.ideal <= (config.capacity * 0.9)
	console.log config

# retrieve a specific resource
@fetch = (options, callback) ->
	
	# if no key is specified then use the uri as the unique cache key
	options.key ?= options.uri
	options[k] ?= v for k, v of config
	
	# get/create new stocked item
	stockedItem = getItem(options)
	
	if stockedItem.hasSpoiled()
		# if the item has expired (or currently unavailable) then
		# the callback must wait until we have updated data
		stockedItem.once 'stocked', (error, results) =>
			callback(error, results)
	else
		callback(null, stockedItem.results)
	
	# request an update if expired (or spoiled)
	stockedItem.fetch(options) if stockedItem.hasExpired()
	


getItem = (options) ->
	if not currentStock[options.key]?
		currentStock[options.key] = new StockedItem(options)
		stockCount++
		cleanUp()
	return currentStock[options.key]
	
removeItem = (key) ->
	delete currentStock[key]
	stockCount--
	
cleanUp = () ->
	if stockCount > config.capacity 
		
		console.log "We're over capacity #{stockCount} / #{config.ideal}.  Time to clean up the pantry"
		
		expired = [] # used for efficient to prevent possibly looping through a second time
		
		# remove spoiled items
		for key, item of currentStock when item.results?
			if item.hasSpoiled()
				console.log "\tSpoiled: #{key}"
				removeItem key
			else if item.hasExpired()
				expired.push key
		
		if stockCount > config.capacity 
			# still over capacity.  let's toss out some expired times to make room
			for key in expired
				console.log "\tExpired: #{key}"
				removeItem key
				break if stockCount <= config.ideal

		if stockCount > config.capacity 
			# we have more stuff than we can handle.  time to toss some good stuff out
			# TODO: likely want to be smarter about which good items we toss
			# but without significant overhead
			for key, item of currentStock when item.results
				console.log "\tTossed: #{key}"
				removeItem key
				break if stockCount <= config.ideal

class StockedItem extends EventEmitter
	constructor: (@options) ->
		@loading = false
		
	hasExpired: ->
		@hasSpoiled() or (new Date()) > @bestBefore
		
	hasSpoiled: ->
		not @results? or (new Date()) > @spoilesOn
	
	fetch: (@options)->
		
		# the loading flag is used to ensure only one request for a resource is executed at a time
		return if @loading
		@loading = true
		
		# set headers for conditional GETs
		@options.headers ?= {}
		@options.headers['if-none-match'] = @eTag if @eTag
		@options.headers['if-modified-since'] = @lastModified if @lastModified

		request @options, (error, response, body) =>

			unless error?
				switch response.statusCode
					when 304 # cached data is still good.  keep using it
						console.log "Still Good: #{options.key}"
						@stock(response, null)

					when 200 # new data available
						console.log "Re-stocked: #{options.key}"

						contentType = response.headers["content-type"]
						
						# parse JSON
						if contentType.indexOf('application/json') is 0
							@stock(response, JSON.parse body)

						# parse XML
						else if contentType.search(/[\/\+]xml/) > 0
							parser = new xml2js.Parser()
							parser.on 'end', (results) =>
								@stock(response, results)
							parser.parseString body
						
						# that was unexpected
						else
							@oops("Invalid Response Type (#{contentType})")
							
					else
						# something wrong with the server or the request
						@oops("Invalid Response Code (#{response.statusCode})")
						
	stock: (response, results) ->
		@loading = false
		
		if @firstPurchased?
			@lastPurchased = new Date()
		else
			@firstPurchased = new Date()
			@lastPurchased = new Date(@firstPurchased)
		
		@lastUsed = new Date(@lastPurchased)
			
		@bestBefore = new Date(@lastPurchased)
		@bestBefore.setSeconds @bestBefore.getSeconds() + @options.shelfLife

		@spoilesOn = new Date(@lastPurchased)
		@spoilesOn.setSeconds @spoilesOn.getSeconds() + @options.maxLife
		
		@eTag = response.headers['etag']
		@lastModified = response.headers['last-modified']
		
		@results = results if results?
		@emit 'stocked', null, @results
		
	oops: (error) ->
		@loading = false
		@emit 'stocked', error