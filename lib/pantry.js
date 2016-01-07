var url = require('url')
  , querystring = require('querystring')
  , request = require('request')
  , xml2js = require('xml2js')
  , EventEmitter = require('events').EventEmitter
  , MemoryStorage = require('./pantry-memory')
  , soap = require('soap')
  , winston = require('winston')
  , inProgress = {}
  , soapClients = {};


function getLogLevel() {
  switch (process.env.NODE_ENV) {
    case 'production':
      return 'info';
    case 'test':
      return 'error';
    default:
      return 'silly';
  }
}

config = {
  shelfLife: 60,
  maxLife: 300,
  caseSensitive: true,
  ignoreCacheControl: false,
  cacheBuster: null,
  verbosity: process.env.PANTRY_VERBOSITY || getLogLevel(),
  xmlOptions: {
    explicitRoot: false
  }
};

var log = new (winston.Logger)({
  transports: [
    new (winston.transports.Console)({
      colorize: true,
      timestamp: true,
      level: config.verbosity
    })
  ]
});

var Pantry = module.exports = {
  storage: null,
  backup: new MemoryStorage(config, config.verbosity)
};

Pantry.configure = function(options) {
  for (var k in options) {
    config[k] = options[k];
  }
  //log = new Log(config.verbosity);
  return config;
};

Pantry.initSoap = function(name, url, callback) {
  if (soapClients[name]) {
    log.warn('service already defined for ' + name);
    callback();
  } else {
    soap.createClient(url, function(err, client) {
      soapClients[name] = client;
      callback(err, client);
    });
  }
};

Pantry.fetch = function(options, callback) { 
  if (typeof options === 'string') {
    options = {
      uri: options
    };
  }
  
  for (var k in config) {
    if (options[k] == null)
      options[k] = config[k];
  }
  
  if (options.method != null && options.method !== 'GET') {
    options.maxLife = 0;
  }
  
  if (options.key == null)
    options.key = Pantry.generateKey(options);

  // These two lines solve the problem that a user may have submitted the values as strings, which affects cache lifetime
  options.maxLife = parseInt(options.maxLife);
  options.shelfLife = parseInt(options.shelfLife);

  Pantry.fromCache(options.key, function(error, resource) {
    resource = resource || {};
    resource.options = options;
    
    if (!Pantry.hasSpoiled(resource)) {
      log.info("using cached data: " + resource.options.key);
      callback(null, resource.results, resource.contentType);
      callback = null;
    }
    
    if (Pantry.hasExpired(resource)) {
      var stock = inProgress[options.key];
      if (stock != null) {
        log.info("waiting for new data: " + resource.options.key);
        if (callback)
          return stock.once('done', callback);
      } else {
        log.info("requesting new data: " + resource.options.key);
        stock = new EventEmitter();
        inProgress[options.key] = stock;
        stock.resource = resource;
        
        if (callback)
          stock.once('done', callback);
          
        resource.options.headers = resource.options.headers || {};
        
        if (!resource.options.ignoreCacheControl && resource.etag != null)
          resource.options.headers['if-none-match'] = resource.etag;
          
        if (!resource.options.ignoreCacheControl && resource.lastModified != null) 
          resource.options.headers['if-modified-since'] = resource.lastModified;
        
        try {
          
          var uri = url.parse(options.uri, true);
          if (uri.protocol === 'soap:') {
            // handle soap requests differently
            var client = soapClients[uri.hostname];
            var method = client[uri.pathname.substring(1)];
            
            // combine querystring and args into one
            var args = options.args || {};
            for(var k in uri.query) {
              args[k] = uri.query[k];
            }
            
            // execute the SOAP request
            method(args, function(error, result) {
              if (error) {
                return Pantry.done(error, stock);
              } else {
                log.info("new data available: " + options.key);
                resource.results = result;
                Pantry.done(null, stock);
              }
            });
          } else {
            
            // apply cache buster if configured
            if (options.cacheBuster) {
              var ts = new Date();
              uri.query[options.cacheBuster] = ts.getTime();
              delete uri.search;
              options.uri = url.format(uri);
            }
            
            request(options, function(error, response, body) {
            
              if (error) {
                return Pantry.done(error, stock);
              } else {
                switch (response.statusCode) {
                  case 304:
                    log.info("cached data still good: " + resource.options.key);
                    Pantry.done(null, stock);
                    break;
                  
                  case 200:
                    log.info("new data available: " + options.key);
                    resource.contentType = response.headers["content-type"];
                  
                    if (response.headers['etag'] != null)
                      resource.etag = response.headers['etag'];
                  
                    if (response.headers['last-modified'] != null)
                      resource.lastModified = response.headers['last-modified'];
                  
                    if (options.parser === 'xml' || resource.contentType.search(/[\/\+]xml/) > 0) {
                      var start = body.indexOf('<');
                      if (start)
                        body = body.slice(start, body.length);
                    
                      var parser = new xml2js.Parser(options.xmlOptions);
                      parser.on('end', function(results) {
                        resource.results = results;
                        Pantry.done(null, stock);
                      });
                      parser.parseString(body);
                    
                    } else if (typeof body === 'string' && options.parser !== 'raw') {
                      try {
                        resource.results = JSON.parse(body);
                        Pantry.done(null, stock);
                      } catch (err) {
                        Pantry.done(err, stock);
                      }
                    } else {
                      resource.results = body;
                      Pantry.done(null, stock);
                    }
                    break;
                  
                  default:
                    return Pantry.done("Invalid Response Code (" + response.statusCode + ")", stock);
                }
              }
            });
          }
        } catch (err) {
          return Pantry.done(err, stock);
        }
      }
    }
  });
};

Pantry.remove = function(options) {
  if (typeof options === 'string') {
    options = {
      uri: options
    };
  }

  if (options.key == null) {
    options.key = Pantry.generateKey(options);
  }

  if (Pantry.storage == null) {
    Pantry.storage = Pantry.backup;
  }

  return Pantry.storage.remove(options.key);
};

Pantry.fromCache = function(key, callback) {
  if (Pantry.storage == null)
    Pantry.storage = Pantry.backup;
  
  Pantry.storage.get(key, function(error, resource) {
    if (error) {
      log.error("Problems with primary storage " + key);
      log.error(error);
      Pantry.backup.get(key, function(error, resource) {
        callback(error, resource);
      });
    } else {
      callback(error, resource);
    }
  });
};

Pantry.done = function(err, stock) {
  delete inProgress[stock.resource.options.key];
  
  if (err) {
    log.error("" + err);
    stock.emit('done', err);
  } else {
    var resource = stock.resource;
    resource.lastPurchased = new Date();
    resource.firstPurchased = resource.firstPurchased || resource.lastPurchased;
    resource.bestBefore = new Date(resource.lastPurchased);
    resource.bestBefore.setSeconds(resource.bestBefore.getSeconds() + resource.options.shelfLife);
    resource.spoilsOn = new Date(resource.lastPurchased);
    resource.spoilsOn.setSeconds(resource.spoilsOn.getSeconds() + resource.options.maxLife);
    
    if (resource.options.maxLife === 0) {
      stock.emit('done', null, resource.results, resource.contentType);
    } else {
      stock.emit('done', null, resource.results, resource.contentType);
      Pantry.storage.put(resource, function(error) {
        if (error) {
          log.error("Could not cache resource " + resource.options.key + ": " + error);
          Pantry.backup.put(resource);
        }
      });
    }
  }
};

Pantry.generateKey = function(options) {
  var uri = url.parse(options.uri, true);
  var keys = [];
  
  for (var k in uri.query) {
    keys.push(k);
  }
  keys.sort();
  
  var query = {};
  keys.forEach(function(k) {
    if (uri.query.hasOwnProperty(k))
      query[options.caseSensitive ? k : k.toLowerCase()] = uri.query[k];    
  });
  
  uri.search = querystring.stringify(query);
  if (!options.caseSensitive) {
    uri.pathname = uri.pathname.toLowerCase();
  }
  
  return url.format(uri);
};

Pantry.hasSpoiled = function(resource) {
  return !(resource.results != null) || (new Date()) > new Date(resource.spoilsOn);
};

Pantry.hasExpired = function(resource) {
  return Pantry.hasSpoiled(resource) || (new Date()) > new Date(resource.bestBefore);
};
