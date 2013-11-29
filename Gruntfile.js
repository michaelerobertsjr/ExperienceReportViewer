module.exports = function(grunt) {

    grunt.initConfig({
        clean: {
            full: ['build/*'],
            fast: ['build/js/*', 'build/app.html']
        },
        copy: {
            lib: {
                files: [ { src: "lib/**", dest: "build/", expand: true } ]
            },
            js: {
                files: [ { src: "js/**", dest: "build/", expand: true, cwd: "src/app" } ]
            },
            server: {
                files: [ { src: "server.js", dest: "build/", expand: true, cwd: "src/" } ]
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
    grunt.loadNpmTasks('grunt-bake');

    grunt.registerTask('deploy',      ['clean:full', 'copy',    'bake']);
    grunt.registerTask('deploy-fast', ['clean:fast', 'copy:js', 'bake']);

    grunt.registerTask('default',     ['deploy-fast']);

}