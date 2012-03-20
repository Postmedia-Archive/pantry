url = require 'url'
querystring = require 'querystring'
request = require 'request'
xml2js = require 'xml2js'

EventEmitter = require('events').EventEmitter

MemoryStorage = require './pantry-memory'
Log = require 'coloured-log'

config = { shelfLife: 60, maxLife: 300, caseSensitive: true, verbosity: 'ERROR', xmlOptions: {}}
log = new Log(config.verbosity)

inProgress = {}
@storage = null

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
	
	# use memory storage if not specified
	@storage ?= new MemoryStorage(config)

	# create new resource
	@storage.get options.key, (error, resource) =>
		resource ?= {}
		resource.options = options
		
		if not @hasSpoiled(resource)
			log.info "using cached data: #{resource.options.key}"
			callback null, resource.results
		
		if @hasExpired(resource)
			stock = inProgress[options.key]
			if stock?
				log.error "waiting for new data: #{resource.options.key}"
				stock.once 'done', callback
			else
				log.warning "requesting new data: #{resource.options.key}"
				stock = new EventEmitter()
				inProgress[options.key] = stock
				stock.resource = resource
				stock.once 'done', callback
			
				#setup options for request
				resource.options.headers ?= {}
				resource.options.headers['if-none-match'] = resource.etag if resource.etag?
				resource.options.headers['if-modified-since'] = resource.lastModified if resource.lastModified?
		
				request options, (error, response, body) =>
					if error?
						@done error, stock
					else
						switch response.statusCode
							when 304 # cached data is still good.  keep using it
								log.info "cached data still good: #{resource.options.key}"
								@done null, stock
							
							when 200 # new data available
								log.info "new data available: #{options.key}"
								contentType = response.headers["content-type"]

								#store cache meta-data
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
								else 
									try
										resource.results = JSON.parse(body)
										@done null, stock
									catch err
										@done err, stock

							else
								# something wrong with the server or the request
								@done "Invalid Response Code (#{response.statusCode})"

@done = (err, stock) ->

	delete inProgress[stock.resource.options.key]
	
	if err?
		log.error "#{err}"
		stock.emit 'done', err
	else
		resource = stock.resource
		resource.lastPurchased = new Date()
		resource.firstPurchased ?= resource.lastPurchased
	
		resource.bestBefore = new Date(resource.lastPurchased)
		resource.bestBefore.setSeconds resource.bestBefore.getSeconds() + resource.options.shelfLife
	
		resource.spoilsOn = new Date(resource.lastPurchased)
		resource.spoilsOn.setSeconds resource.spoilsOn.getSeconds() + resource.options.maxLife
	
		@storage.put resource, (error) ->
			stock.emit 'done', error, resource.results
	
@generateKey = (options) ->
	uri = url.parse options.uri, true

	keys = []
	for k of uri.query
		keys.push k
	keys.sort()

	query = {}
	for k in keys
		if uri.query.hasOwnProperty(k)
			query[if options.caseSensitive then k else k.toLowerCase()] = uri.query[k]

	uri.search = querystring.stringify(query)
	uri.pathname = uri.pathname.toLowerCase() unless options.caseSensitive

	url.format uri
	
@hasSpoiled = (resource) ->
	not resource.results? or (new Date()) > resource.spoilsOn

@hasExpired = (resource) ->
	@hasSpoiled(resource) or (new Date()) > resource.bestBefore
