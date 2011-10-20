url = require 'url'
querystring = require 'querystring'
stock = require './stock'

inProgress = {}

config = { caseSensitive: true, verbosity: "INFO", xmlOptions: {}}

# update configuration and defaults
@configure = (options) ->	
	config[k] = v for k, v of options
	return config

# retrieve a specific resource
@fetch = (options, callback) ->

	# support the ability to pass in just a URI string
	options = {uri: options} if typeof options is 'string'
	
	# apply default options
	options[k] ?= v for k, v of config

	# if no key is specified then use the uri as the unique cache key
	options.key ?= normalizeURL(options.uri, options.caseSensitive)

	# simple prevention of caching for non-GET methods.  Needs improvement
	options.maxLife = 0 if options.method? and options.method isnt 'GET'
	
	# get/create new stocked item
	stockedItem = getItem(options)

	if stockedItem.hasSpoiled()
		# if the item has expired (or currently unavailable) then
		# the callback must wait until we have updated data
		stockedItem.once 'stocked', callback
	else
		callback(null, stockedItem.results)

	# request an update if expired (or spoiled)
	if stockedItem.hasExpired() and not inProgress[options.key]?
		inProgress[options.key] = stockedItem
		stockedItem.fetch (error, results) =>
			config.storage.put stockedItem if not error
			delete inProgress[options.key]

normalizeURL = (value, caseSensitive = false) ->
	uri = url.parse value, true
	
	keys = []
	for k of uri.query
		keys.push k
	keys.sort()
	
	query = {}
	for k in keys
		if uri.query.hasOwnProperty(k)
			query[if caseSensitive then k else k.toLowerCase()] = uri.query[k]
			
	uri.search = querystring.stringify(query)
	uri.pathname = uri.pathname.toLowerCase() unless caseSensitive
	
	url.format uri

getItem = (options) ->
	#use memory storage by default if nothing has been set up
	if not config.storage?
		memory = require './pantry-memory'
		config.storage ?= new memory.create()
	
	item = inProgress[options.key] or config.storage.get(options.key) or new stock.StockedItem(options)

