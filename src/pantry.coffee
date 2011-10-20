url = require 'url'
querystring = require 'querystring'

MemoryStorage = require './pantry-memory'
StockedItem = require './stock'
Log = require 'coloured-log'

inProgress = {}
config = { caseSensitive: true, verbosity: 'ERROR', xmlOptions: {}}
log = new Log(config.verbosity)

@storage ?= new MemoryStorage(config)

# update configuration and defaults
@configure = (options) ->	
	config[k] = v for k, v of options
	log = new Log(config.verbosity)
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
	stockedItem = inProgress[options.key] or @storage.get(options.key) or new StockedItem(options)
	
	if stockedItem.hasSpoiled()
		# if the item has expired (or currently unavailable) then
		# the callback must wait until we have updated data
		log.warning "results unavailable or spoiled. need to wait: #{options.key}"
		stockedItem.once 'stocked', callback
	else
		log.info "results available: #{options.key}"
		callback(null, stockedItem.results)

	# request an update if expired (or spoiled)
	if stockedItem.hasExpired() and not inProgress[options.key]?
		log.debug "requesting new results: #{options.key}"
		inProgress[options.key] = stockedItem
		stockedItem.fetch (error, results) =>
			if not error
				log.notice "storing new results: #{options.key}"
				@storage.put stockedItem
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

