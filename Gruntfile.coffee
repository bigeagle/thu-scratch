module.exports = (grunt) ->
  'use strict'


  ############
  # plugins

  [
    'grunt-iced-coffee'
    'grunt-contrib-copy'
    'grunt-contrib-concat'
    'grunt-contrib-clean'
    'grunt-contrib-uglify'
    'grunt-contrib-cssmin'
  ].map (x) -> grunt.loadNpmTasks(x)

  # text files -> JSON
  grunt.registerMultiTask 'pack', 'pack text files into JSONP', ->
    path = require 'path'
    for x in @files
      o = {}
      for f in x.src
        name = path.basename f
        cont = grunt.file.read f, encoding: 'utf-8'
        o[name] = cont
      ret = ";var #{x.name}=#{JSON.stringify(o)};\n"
      grunt.file.write x.dest, ret, encoding: 'utf-8'

  # template
  grunt.registerMultiTask 'template', ->
    for x in @files
      src = x.src[0] # FIXME: support one src only
      dest = x.dest
      cont = grunt.template.process grunt.file.read(src, encoding: 'utf-8')
      cont = cont.replace(/\r\n/g, '\n')
      grunt.file.write(dest, cont, encoding: 'utf-8')


  ############
  # config

  grunt.initConfig new ->
    @pkg = grunt.file.readJSON('package.json')

    # default
    @clean =
      build: ['build/*']
      dist: ['dist/*']
    @coffee =
      options:
        bare: true
    @uglify =
      options:
        preserveComments: 'some'
    @cssmin = {}
    @pack = {}
    @template = {}
    @copy = {}
    @concat = {}

    # minify and join libraries
    @uglify.lib =
      files: [
        {
          expand: true
          cwd: 'lib/'
          src: '*.js'
          dest: 'build/lib/'
          ext: '.min.js'
        }
      ]
    @concat.lib =
      src: 'build/lib/*.js'
      dest: 'build/lib.js'
    grunt.registerTask 'lib', [
      'uglify:lib'
      'concat:lib'
    ]

    # minify and pack CSS
    @cssmin.main =
      files: [
        {
          expand: true
          cwd: 'src/css/'
          src: '*.css'
          dest: 'build/css/'
        }
      ]
    @pack.css =
      name: 'PACKED_CSS'
      src: 'build/**/*.css'
      dest: 'build/packed/css.js'
    grunt.registerTask 'pack-css', [
      'cssmin:main'
      'pack:css'
    ]

    ## pack HTML
    #@pack.html =
      #name: 'PACKED_HTML'
      #src: 'src/**/*.html'
      #dest: 'build/packed/html.js'
    #grunt.registerTask 'pack-html', [
      #'pack:html'
    #]

    # join all packed files
    @concat.pack =
      src: 'build/packed/*.js'
      dest: 'build/packed.js'
    grunt.registerTask 'pack-all', [
      'pack-css'
      #'pack-html'
      'concat:pack'
    ]

    # main code
    @coffee.main =
      options:
        join: true
        runtime: 'window'
      files: [
        {src: 'src/*.{iced,coffee}', dest: 'build/main.js'}
      ]
    grunt.registerTask 'main', [
      'coffee:main'
    ]

    # make all-in-one script (lib + packed + main code + postproc)
    @concat.aio =
      files: [
        {
          src: [
            'build/lib.js'
            'build/packed.js'
            'build/main.js'
          ]
          dest: 'build/aio.js'
        }
      ]
    grunt.registerTask 'aio', [
      'concat:aio'
    ]

    # make userscript
    @template.gm =
      files: [
        {src: 'src/gm/metadata.js', dest: 'build/metadata.js'}
      ]
    @concat.gm =
      src: [
        'build/metadata.js'
        'build/aio.js'
      ]
      dest: "dist/gm/#{@pkg.name}.user.js"
    grunt.registerTask 'gm', [
      'template:gm'
      'concat:gm'
    ]

    @ # grunt.initConfig

  grunt.registerTask 'default', [
    'pack-all'
    'main'
    'aio'
    'gm'
  ]
