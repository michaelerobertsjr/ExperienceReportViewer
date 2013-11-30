module.exports = function(grunt) {

    grunt.initConfig({
        clean: {
            full: ['build/*'],
            fast: ['build/js/*', 'build/app.html']
        },
        copy: {
            lib: {
                files: [ { src: "lib/**", dest: "build/", expand: true } ]
            }
        },
        coffee: {
            app: {
                files: {
                    "build/js/app.js": "src/app/coffee/app.coffee"
                }
            },
            server: {
                files: {
                    "build/server.js": "src/server/coffee/server.coffee"
                }
            }
        },
        bake: {
            view: {
                options: {
                    process: false
                },
                files: {
                    "build/app.html": "src/app/view/template.html"
                }
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-bake');

    grunt.registerTask('deploy-fast', ['clean:fast', 'coffee:app', 'bake']);
    grunt.registerTask('deploy',      ['clean:full', 'copy', 'coffee', 'bake']);

    grunt.registerTask('default',     ['deploy-fast']);

}