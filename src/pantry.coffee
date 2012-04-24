url = require 'url'
querystring = require 'querystring'
request = require 'request'
xml2js = require 'xml2js'

EventEmitter = require('events').EventEmitter

MemoryStorage = require './pantry-memory'
Log = require 'coloured-log'

# default configuration
config = { shelfLife: 60, maxLife: 300, caseSensitive: true, verbosity: 'ERROR', xmlOptions: {}}
log = new Log(config.verbosity)

inProgress = {}	# holds requests in progress
@storage = null	# cache storage container
@backup = new MemoryStorage(config)	# backup memory storage container (if primary storage isn't available)

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

	# simple prevention of caching for non-GET methods.  Needs improvement
	options.maxLife = 0 if options.method? and options.method isnt 'GET'

	# if no key is specified then use the uri as the unique cache key
	options.key ?= @generateKey(options)
	
	# attempt to retrieve resource from cache
	@fromCache options.key, (error, resource) =>
		
		# create new resource if not availabe in cache
		resource ?= {}
		
		# always update the request options regardless of cache
		resource.options = options
		
		if not @hasSpoiled(resource)
			# the resource hasn't spoiled, so return results immediatly
			log.info "using cached data: #{resource.options.key}"
			callback null, resource.results
			
			# dispose of callback to avoid calling it twice if expired
			callback = null
		
		if @hasExpired(resource)
			# check if resource request already in progrss
			stock = inProgress[options.key]
			if stock?
				# already in progress, just wait for it to complete
				log.info "waiting for new data: #{resource.options.key}"
				stock.once 'done', callback if callback
			else
				# first request for new/updated data.  mark it as in progress
				log.info "requesting new data: #{resource.options.key}"
				stock = new EventEmitter()
				inProgress[options.key] = stock
				stock.resource = resource
				stock.once 'done', callback if callback
			
				# setup conditional request reheaders if supported by previous request
				resource.options.headers ?= {}
				resource.options.headers['if-none-match'] = resource.etag if resource.etag?
				resource.options.headers['if-modified-since'] = resource.lastModified if resource.lastModified?
		
				# time to execute the actual request
				try
					request options, (error, response, body) =>
						if error?
							@done error, stock
						else
							switch response.statusCode
								# cached data is still good.  keep using it
								when 304 
									log.info "cached data still good: #{resource.options.key}"
									@done null, stock
								
								# new data available
								when 200 
									log.info "new data available: #{options.key}"
									contentType = response.headers["content-type"]

									# store http caching meta-data for future conditional requests
									resource.etag = response.headers['etag'] if response.headers['etag']?
									resource.lastModified = response.headers['last-modified'] if response.headers['last-modified']?

									# parse XML
									if options.parser is 'xml' or contentType.search(/[\/\+]xml/) > 0
										# some xml is 'bad' but can be fixed, so let's try
										start = body.indexOf('<')
										body = body[start...body.length] if start

										# now we can parse
										parser = new xml2js.Parser(options.xmlOptions)
										parser.on 'end', (results) =>
											resource.results = results
											@done null, stock
										parser.parseString body

									# parse JSON
									else if typeof body is 'string'
										try
											resource.results = JSON.parse(body)
											@done null, stock
										catch err
											@done err, stock
									
									# return object
									else
										resource.results = body
										@done null, stock

								else
									# something wrong with the server or the request
									@done "Invalid Response Code (#{response.statusCode})", stock
				catch err
					@done err, stock

# retrieve from cache storage
@fromCache = (key, callback) ->
	
	# init and use memory storage if nothing specified
	@storage ?= @backup

	# attempt to retrieve resource from primary storage first
	@storage.get key, (error, resource) =>
		if not error?
			callback error, resource
		else
			# attempt to retrieve resource from backup storage
			log.error "Problems with primary storage #{key}"
			@backup.get key, (error, resource) ->
				callback error, resource
						
# request has completed, for better or worse
@done = (err, stock) ->

	# remove from list of requests in progress
	delete inProgress[stock.resource.options.key]
	
	if err?
		# that didn't go well.
		log.error "#{err}"
		# execute the registered callbacks
		stock.emit 'done', err
	else
		# update all the dates
		resource = stock.resource
		resource.lastPurchased = new Date()
		resource.firstPurchased ?= resource.lastPurchased
	
		resource.bestBefore = new Date(resource.lastPurchased)
		resource.bestBefore.setSeconds resource.bestBefore.getSeconds() + resource.options.shelfLife
	
		resource.spoilsOn = new Date(resource.lastPurchased)
		resource.spoilsOn.setSeconds resource.spoilsOn.getSeconds() + resource.options.maxLife
	
		# cache the results in storage for future use
		if resource.options.maxLife is 0
			# this resource should not be cached
			stock.emit 'done', error, resource.results
		else
			# sends back results first, as there is no need to wait for caching to complete
			stock.emit 'done', null, resource.results # app should not fail if cache isn't available
			
			# now try to cache results
			@storage.put resource, (error) =>
				# execute the registered callbacks
				if error?
					log.error "Could not cache resource #{resource.options.key}: #{error}"
					@backup.put resource

# creates a unique and predicable key based on the requested uri
@generateKey = (options) ->
	uri = url.parse options.uri, true

	# sort the query string parameters
	keys = []
	for k of uri.query
		keys.push k
	keys.sort()

	# recreate the query string
	query = {}
	for k in keys
		if uri.query.hasOwnProperty(k)
			query[if options.caseSensitive then k else k.toLowerCase()] = uri.query[k]

	# update the uri
	uri.search = querystring.stringify(query)
	uri.pathname = uri.pathname.toLowerCase() unless options.caseSensitive

	# return the updated uri as a string key
	url.format uri
	
# determine if a resource is empty or too old for use
@hasSpoiled = (resource) ->
	not resource.results? or (new Date()) > resource.spoilsOn

# determine if the resource should be updated/re-requested
@hasExpired = (resource) ->
	@hasSpoiled(resource) or (new Date()) > resource.bestBefore
