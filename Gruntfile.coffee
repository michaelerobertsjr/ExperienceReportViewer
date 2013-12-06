module.exports = (grunt) ->

  # load npm tasks
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-bake"

  # task config
  grunt.initConfig
    pkg: grunt.file.readJSON "package.json"

    clean:
      full: ["build/*",]
      fast: ["build/js/*", "build/app.html"]

    copy:
      lib:
        files: [ { src: "lib/**", dest: "build/", expand: true } ]
      test:
        files: [ { src: "**", dest: "build/test/", expand: true, cwd: "test/data/1.0.0/" } ]

    coffee:
      app:
        options:
          join: true
        files: { "build/js/app.js": ["src/app/coffee/modules.coffee", "src/app/coffee/main.coffee"] }
      server:
        files: { "build/server.js": "src/server/coffee/server.coffee" }

    bake:
      view:
        options:
          process: false
        files: { "build/app.html": "src/app/html/view.html" }

  # build tasks
  grunt.registerTask "deploy-fast", ["clean:fast", "coffee:app", "bake"]
  grunt.registerTask "deploy", ["clean:full", "copy", "coffee", "bake"]

  grunt.registerTask "default", ["deploy-fast"]