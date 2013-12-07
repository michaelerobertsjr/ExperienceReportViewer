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
      css:
        files: [ { src: "*", dest: "build/css", expand: true, cwd: "src/css/" } ]

    coffee:
      app:
        options:
          join: true
        files: { "build/js/app.js": ["src/coffee/modules.coffee", "src/coffee/main.coffee"] }

    bake:
      view:
        options:
          process: false
        files: { "build/app.html": "src/html/view.html" }

  # build tasks
  grunt.registerTask "deploy-fast", ["clean:fast", "coffee:app", "copy:css", "bake"]
  grunt.registerTask "deploy", ["clean:full", "copy", "coffee", "bake"]

  grunt.registerTask "default", ["deploy-fast"]