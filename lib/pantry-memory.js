var winston = require('winston');

var MemoryStorage = module.exports = function(options, verbosity) {
      
  // default configuration
  options = options || {};
  verbosity = verbosity || 'info';
  this.config = {capacity: 1000};
  
  // update configuration and defaults
  for (var k in options) {
    this.config[k] = options[k];
  }
  
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
  
  // recalculate new ideal capacity (unless alternate and valid ideal has been specified)
  if (!(options.ideal && this.config.ideal <= (this.config.capacity * 0.9))) {
    this.config.ideal = this.config.capacity * 0.9;
  }
  if (this.config.ideal < (this.config.capacity * 0.1)) {
    this.config.ideal = this.config.capacity * 0.1;
  }
  
  // init stock
  this.clear();
  
  this.log.info("New memory storage created");
  this.log.info("Configuration: capacity=" + this.config.capacity + ", ideal=" + this.config.ideal);
}

// remove all cached resources
MemoryStorage.prototype.clear = function() {
  this.currentStock = {};
  return this.stockCount = 0;
};

// retrieve a specific resource
MemoryStorage.prototype.get = function(key, callback) {
  callback(null, this.currentStock[key]);
};

// save a specific resource
MemoryStorage.prototype.put = function(resource, callback) {
  if (!(this.currentStock[resource.options.key] != null)) {
    this.stockCount++;
    this.cleanUp();
  }
  this.currentStock[resource.options.key] = resource;
  
  // support for optional callback
  if (callback) {
    callback(null, resource);
  }
  
  // allow chaining, mostly for testing
  return this;
};

// you guessed it!  removed a specific item
MemoryStorage.prototype.remove = function(key) {
  if (this.currentStock[key]) {
    delete this.currentStock[key];
    return this.stockCount--;
  }
};

// removes items from storage if over capacity
MemoryStorage.prototype.cleanUp = function() {
  
  // check if we are over capacity
  if (this.stockCount > this.config.capacity) {
    this.log.warn("We're over capacity " + this.stockCount + " / " + this.config.ideal + ".  Time to clean up the pantry memory storage");
    
    var now = new Date()
      , expired = []; // used for efficiency to prevent possibly looping through a second time

    // remove spoiled items
    for (var key in this.currentStock) {
      resource = this.currentStock[key];
      if (resource.spoilsOn < now) {
        this.log.verbose("Spoiled " + key);
        this.remove(key);
      } else if (resource.bestBefore < now) {
        expired.push(key);
      }
    }
    
    if (this.stockCount > this.config.capacity) {
      // still over capacity.  let's toss out some expired times to make room
      for (var i = 0, len = expired.length; i < len; i++) {
        key = expired[i];
        this.log.info("Expired " + key);
        this.remove(key);
        if (this.stockCount <= this.config.ideal) {
          break;
        }
      }
    }
    
    if (this.stockCount > this.config.capacity) {
      // we have more stuff than we can handle.  time to toss some good stuff out
      // TODO: likely want to be smarter about which good items we toss
      // but without significant overhead

      for (key in this.currentStock) {
        resource = this.currentStock[key];
        this.log.warn("Tossed " + key);
        this.remove(key);
        if (this.stockCount <= this.config.ideal) {
          break;
        }
      }
    }
    
    this.log.info("Cleanup complete.  Currently have " + this.stockCount + " items in stock");
  }
};
