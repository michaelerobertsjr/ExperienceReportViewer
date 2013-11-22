module.exports = function(grunt) {

    grunt.initConfig({
        clean: {
            build: ['build/*']
        },
        copy: {
            lib: {
                files: [
                    { src: "lib/**", dest: "build/", expand: true }
                ]
            },
            js: {
                files: [
                    { src: "js/**", dest: "build/", expand: true, cwd: "src/" }
                ]
            }
        },
        bake: {
            view: {
                options: {},
                files: {
                    "build/app.html": "src/view/template.html"
                }
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-bake');

    grunt.registerTask('build', ['clean', 'copy', 'bake']);

    grunt.registerTask('default', ['build'])

}