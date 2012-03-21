exec = require('child_process').exec

task 'build', ->
  exec 'coffee -o lib -c src/*.coffee', (err) ->
    console.log err if err

task 'test', ->
  exec './node_modules/.bin/mocha', (err) ->
    console.log err if err