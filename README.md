# ExperienceReportViewer Build Project

## Project file structure
* `lib` plugins and external sources
* `src` source files
  * `app` app source files
    * `coffee` application code modules
    * `html` view templates
  * `server` server source files
    * `coffee` simple http test server
* `test` statement test data

## Requirements

* [node.js](http://nodejs.org)
* [npm.js](http://npmjs.org)
* [grunt.js](http://gruntjs.com)

## Installation

install required packages:
* `$ npm install `

build app:
* `$ grunt deploy`

## Run

web Browser:
* open build/app.html (recommended: chrome / firefox)

simple HTTP server:
* `$ node ./build/server.js`
* open [http://localhost:8080/app.html](http://localhost:8080/app.html)



