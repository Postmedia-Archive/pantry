request = require 'request'

stock = {}
count = 0
config = { shelfLife: 60, maxLife: 300, capacity: 1000, ideal: 900}

@configure = (options) ->	
	config[k] = v for k, v of options
		
	config.ideal = (config.capacity * 0.9) unless options.ideal and config.ideal <= (config.capacity * 0.9)
	console.log config
	
@fetch = (options, callback) ->
	
	delivered = false
	options.key ?= options.uri
	options[k] ?= v for k, v of config
	
	stockedItem = stock[options.key]
	if stockedItem and not stockedItem.hasSpoiled()
		callback(null, stockedItem.item)
		delivered = true
		
	return if stockedItem and not stockedItem.hasExpired()
	
	request options, (error, response, body) =>
		item = JSON.parse body
		if stockedItem
			stockedItem.reStock item
			console.log "Re-Stocked (#{count}): #{options.key}"
		else
			addItem item, options
			console.log "New Stock (#{count}): #{options.key}"
		
		callback(error, item) unless delivered
	
addItem = (item, options) ->
	stock[options.key] = new StockedItem(item, options)
	count++
	cleanUp()
	
removeItem = (key) ->
	delete stock[key]
	count--
	
cleanUp = () ->
	if count > config.capacity 
		
		console.log "We're over capacity #{count} / #{config.ideal}.  Time to clean up the pantry"
		
		expired = []
		for key, item of stock
			if item.hasSpoiled()
				console.log "\tSpoiled: #{key}"
				removeItem key
			else if item.hasExpired()
				expired.push key
		
		if count > config.capacity 
			# still over capacity.  let's toss out some expired times to make room
			for key in expired
				console.log "\tExpired: #{key}"
				removeItem key
				break if count <= config.ideal

		if count > config.capacity 
			# we have more stuff than we can handle.  time to toss some good stuff out
			# TODO: likely want to be smarter about which good items we toss
			# but without significant overhead
			for key, item of stock
				console.log "\tTossed: #{key}"
				removeItem key
				break if count <= config.ideal

class StockedItem
	constructor: (item, @options) ->
		@firstPurshased = new Date()
		@lastPurchased = new Date(@firstPurchased)
		@reStock(item)
		
	hasExpired: ->
		@hasSpoiled() || (new Date()) > @bestBefore
		
	hasSpoiled: ->
		(new Date()) > @spoilesOn
	
	reStock: (@item) ->
		if @lastPurchased
			@lastPurchased = new Date()
		else
			@lastPurchased = new Date(@firstPurchased)
		
		@lastUsed = new Date(@lastPurchased)
			
		@bestBefore = new Date(@lastPurchased)
		@bestBefore.setSeconds @bestBefore.getSeconds() + @options.shelfLife

		@spoilesOn = new Date(@lastPurchased)
		@spoilesOn.setSeconds @spoilesOn.getSeconds() + @options.maxLife
