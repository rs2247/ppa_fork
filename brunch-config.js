exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      // To use a separate vendor.js bundle, specify two files path
      // https://github.com/brunch/brunch/blob/stable/docs/config.md#files
      joinTo: {
        "js/vendor.js": /^(web\/static\/vendor\/js)|(node_modules)/,
        "js/app.js": /^(web\/static\/js)|(web\/static\/templates)/,
        "js/sales-report.js": "web/static/js/sales-report.js",
      },

      order: {
        before: [
          "web/static/vendor/js/jquery-2.*.js",
          "web/static/vendor/js/jquery-ui.js",
          "web/static/vendor/js/datepicker-pt-BR.js",
          "web/static/vendor/js/jquery-ui-timepicker-addon.js",
          "web/static/vendor/js/FileSaver.min.js",
          "web/static/vendor/js/d3.v3.min.js",
          "web/static/vendor/js/c3.min.js",
          "web/static/vendor/js/select2.min.js",
          "web/static/vendor/js/bootstrap.js"
        ]
      }
    },
    stylesheets: {
      joinTo: "css/app.css"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/web/static/assets". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(web\/static\/assets)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "web/static",
      "test/static"
    ],

    // Where to compile files to
    public: "priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/web\/static\/vendor/]
    },
    sass: {
      options: {
        includePaths: ['web/static/vendor/css']
      }
    },
    vue: {
      extractCSS: true,
      out: 'priv/static/css/components.css'
    }

  },

  modules: {
    autoRequire: {
      "js/app.js": ["web/static/js/app"]
    }
  },

  npm: {
    enabled: true,
    globals: {
      Vue: 'vue/dist/vue.js'
    },
    // Whitelist the npm deps to be pulled in as front-end assets.
    // All other deps in package.json will be excluded from the bundle.
    whitelist: ["lodash", "phoenix", "phoenix_html"]
  }
};
