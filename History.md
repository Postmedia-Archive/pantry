0.5.1 / 2013-07-16
===================
  * Experimental support for SOAP requests

0.5.0 / 2013-07-16
===================
  * Converted from CoffeeScript to JavaScript
  * Now uses winston instead of coloured-log for logging

0.4.1 / 2012-10-11
===================
  * Update default logging with optional env setting

0.4.0 / 2012-10-05
===================
  * Upgraded dependencies
  * Requires Node v0.8.x
  * Default XML parsing has changed with xml2js v0.2

0.3.4 / 2012-10-04
===================

  * Fixing a bug in dependencies, xml2js version set to 0.1.14 as newer versions use incompatible versions of coffee-script.

0.3.3 / 2012-04-24
==================

  * Handle request library returning an object (no parsing needed)

0.3.2 / 2012-03-29
==================

  * Better handling of offline storage

0.3.1 / 2012-03-28
==================

  * Use MemoryStorage as backup if primary storage is unavailable

0.3.0 / 2012-03-21
==================

  * Unstable experimental release
  * Code has been completely refactored
  * Supports plugins for cache storage (defaults to MemoryStorage)
  * Added RedisStorage plugin
  * Added MemcachedStorage plugin
  * Switched to mocha testing framework

0.2.0 / 2011-10-03
==================

  * Stable production release
  * Reversed sort order within History.md

0.2.0beta2 / 2011-09-15
=======================

  * xml2js parsing options can now be passed in via xmlOptions
  * parsed xml no longer provides explicit arrays for child elements by default (but you can enable via xmlOptions)

0.2.0beta / 2011-09-14
======================

  * Now respects cache-control header
  * non-GET requests are not cached
  * parsed xml now uses explicit arrays for child elements
  * ability to utilize loose parsing when dealing with inexplicit or incorrect content-types

0.1.2 / 2011-09-06
===================

  * Bug Fix - Removed config = config
  * Convert from styout to coloured-log

0.1.1 / 2011-08-18
===================

  * Slight mod to node version requirements

0.1.0 / 2011-08-09
===================

  * Added return value to configuration method containing the actual config values.
  * Added getStock method that builds a data structure containing the stock count and current stock items
  * implemented test cases using kitkat

0.0.3 / 2011-08-03
==================

  * Normalizes URI to create consistent cache keys
  * Utilizes for styout for console messages (debug, info, errors etc.)

0.0.2 / 2011-07-28
==================

  * Major refactoring
  * Supports XML resources
  * Conditional GETs (ETag and/or Last-Modified)
  * Efficient handling of parallel requests for the same resource
  * Some error handling

0.0.1 / 2011-07-18
==================

  * Initial release














