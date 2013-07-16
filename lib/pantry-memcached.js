var Memcached = require('memcached')
  , winston = require('winston');

var MemcachedStorage = module.exports = function(servers, options, verbosity) {
  var _this = this;
  
  // default values
  servers = servers || "localhost:11211";
  options = options || {};
  verbosity = verbosity || 'info';
  
  // configure the log
  this.log = new (winston.Logger)({
    transports: [
      new (winston.transports.Console)({
        colorize: true,
        timestamp: true,
        level: verbosity
      })
    ]
  });
  
  // connect to redis server
  this.client = new Memcached(servers, options);
  
  this.client.on('issue', function(details) {
    return _this.log.warn(details.toString());
  });
  
  this.client.on('failure', function(details) {
    return _this.log.error(details.toString());
  });
  
  this.client.on('reconnecting', function(details) {
    return _this.log.info(details.toString());
  });
  
  this.client.on('reconnected', function(details) {
    return _this.log.info(details.toString());
  });
  
  this.client.on('remove', function(details) {
    return _this.log.info(details.toString());
  });
  
  this.log.info("New memcached storage created");
  this.log.info("Servers: " + servers);
};

// retrieve a specific resource
MemcachedStorage.prototype.get = function(key, callback) {
  return this.client.get(key, function(err, results) {
    if (err) {
      this.log.error(err);
    }
    callback(err, err || results === false ? null : JSON.parse(results));
  });
};

// save a specific resource
MemcachedStorage.prototype.put = function(resource, callback) {
  var _this = this;
  this.client.set(resource.options.key, JSON.stringify(resource), resource.options.maxLife, function(err, results) {
    if (err) {
      _this.log.error(err);
    }
    if (callback) {
      callback(err, results);
    }
  });
  return this;
};
