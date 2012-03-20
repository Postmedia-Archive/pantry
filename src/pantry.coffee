url = require 'url'
querystring = require 'querystring'
request = require 'request'
xml2js = require 'xml2js'

MemoryStorage = require './pantry-memory'
Log = require 'coloured-log'

config = { shelfLife: 60, maxLife: 300, caseSensitive: true, verbosity: 'ERROR', xmlOptions: {}}
log = new Log(config.verbosity)
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

	# if no key is specified then use the uri as the unique cache key
	options.key ?= @generateKey(options)
	
	# simple prevention of caching for non-GET methods.  Needs improvement
	options.maxLife = 0 if options.method? and options.method isnt 'GET'

	# use memory storage if not specified
	@storage ?= new MemoryStorage(config)
	
	# create new resource
	@storage.get options.key, (error, resource) =>
		resource ?= {}
		resource.options = options
		
		if not @hasSpoiled(resource)
			log.info "using cached data: #{resource.options.key}"
			callback null, resource.results
			callback = null #prevent calling again if expired but not spoiled
		
		if @hasExpired(resource)
			#setup options for request
			resource.options.headers ?= {}
			resource.options.headers['if-none-match'] = resource.etag if resource.etag?
			resource.options.headers['if-modified-since'] = resource.lastModified if resource.lastModified?
		
			request options, (error, response, body) =>
				if error?
					@oops error, resource, callback
				else
					switch response.statusCode
						when 304 # cached data is still good.  keep using it
							log.info "cached data still good: #{resource.options.key}"
							@store resource, callback
							
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
									@store resource, callback
								parser.parseString body

							# parse JSON
							else 
								try
									resource.results = JSON.parse(body)
									@store resource, callback
								catch err
									@oops err, resource, callback

						else
							# something wrong with the server or the request
							callback "Invalid Response Code (#{response.statusCode})"

@store = (resource, callback) ->

	resource.lastPurchased = new Date()
	resource.firstPurchased ?= resource.lastPurchased
	
	resource.bestBefore = new Date(resource.lastPurchased)
	resource.bestBefore.setSeconds resource.bestBefore.getSeconds() + resource.options.shelfLife
	
	resource.spoilsOn = new Date(resource.lastPurchased)
	resource.spoilsOn.setSeconds resource.spoilsOn.getSeconds() + resource.options.maxLife
	
	@storage.put resource, (error) ->
		callback error, resource.results if callback

@oops = (err, resource, callback) ->
	log.error "#{err}"
	#delete inProgress[resource.options.key]
	callback err, resource if callback
	
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
