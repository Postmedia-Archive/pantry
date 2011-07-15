request = require 'request'
async = require 'async'

stock = {}

@shelfLife = 10
@maxLife = 60

get = (options, callback) ->
	
	delivered = false
	key = options.uri
	
	stockedItem = stock[key]
	if stockedItem and not stockedItem.hasSpoiled()
		console.log "#{if stockedItem.hasExpired() then 'Expired' else 'In Stock'}: #{key}"
		callback(stockedItem.item)
		delivered = true
		
	return if stockedItem and not stockedItem.hasExpired()
	
	request options, (error, response, body) =>
		item = JSON.parse body
		if stockedItem
			console.log "Re-Stocked: #{key}"
			stockedItem.reStock item
		else
			console.log "Stocked: #{key}"
			stock[key] = new StockedItem(key, item, @shelfLife, @maxLife)
		
		callback(item) unless delivered
		
@get = get

@getMulti = (resources..., callback) ->
	
	requests = []
	for resource in resources
		console.log resource
		requests.push (cb) =>
			get resource.clone, (item) =>
				cb(null, item)
				
	console.log requests
	requests[0]()
	#async.parallel requests, callback

class StockedItem
	constructor: (@uri, item, @shelfLife, @maxLife) ->
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
			
		@bestBefore = new Date(@lastPurchased)
		@bestBefore.setSeconds @bestBefore.getSeconds() + @shelfLife
		
		@spoilesOn = new Date(@lastPurchased)
		@spoilesOn.setSeconds @spoilesOn.getSeconds() + @maxLife
