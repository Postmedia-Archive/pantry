var redis = require('redis')
  , winston = require('winston');

var RedisStorage = module.exports = function(port, host, options, verbosity) {
  var _this = this;
  
  // default values
  port = port || 6379;
  host = host || 'localhost';
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
  
  this.up = false; // used to track status of connection
  
  // connect to redis server
  this.client = redis.createClient(port, host);
  this.client.on('end', function() {
    _this.log.warn("Disconnected from Host: " + host + ", Port: " + port);
    _this.up = false;
  });
  this.client.on('error', function(err) {
    _this.log.error(err.toString());
    _this.up = false;
  });
  this.client.on('ready', function() {
    _this.log.info("Connected to Host: " + host + ", Port: " + port);
    _this.up = true;
  });
  if (options.auth) {
    this.client.auth(options.auth);
  }
  this.log.info("New redis storage created");
};

// retrieve a specific resourc
RedisStorage.prototype.get = function(key, callback) {
  var _this = this;
  if (this.up) {
    this.client.get(key, function(err, results) {
      if (err) {
        _this.log.error(err);
      }
      callback(err, err ? null : JSON.parse(results));
    });
  } else {
    callback("Redis server currently unavailable");
  }
};

// save a specific resource
RedisStorage.prototype.put = function(resource, callback) {
  var _this = this;
  if (this.up) {
    this.client.set(resource.options.key, JSON.stringify(resource), function(err, results) {
      if (err != null) {
        _this.log.error(err);
        if (callback) {
          callback(err, results);
        }
      } else {
        // expire item from cache when spoiled (no need to wait)
        _this.client.expire(resource.options.key, resource.options.maxLife, function() {});
        if (callback) {
          callback(err, results);
        }
      }
    });
  } else {
    callback("Redis server currently unavailable");
  }
  return this;
};