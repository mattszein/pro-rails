# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/library", under: "library"
pin_all_from "app/components", under: "controllers", to: ""
pin "el-transition", to: "https://ga.jspm.io/npm:el-transition@0.0.7/index.js"
pin "js-cookie", to: "https://ga.jspm.io/npm:js-cookie@3.0.5/dist/js.cookie.mjs"
pin "tom-select", to: "https://ga.jspm.io/npm:tom-select@2.4.3/dist/js/tom-select.complete.min.js"
pin "@anycable/turbo-stream", to: "@anycable--turbo-stream.js" # @0.8.1
pin "@anycable/web", to: "@anycable--web.js" # @1.1.0
pin "@anycable/core", to: "@anycable--core.js" # @1.1.4
pin "@hotwired/turbo", to: "@hotwired--turbo.js" # @8.0.21
pin "nanoevents" # @9.1.0

pin "air-datepicker", to: "https://esm.sh/air-datepicker@3.6.0"
pin "air-datepicker/locale/en", to: "https://esm.sh/air-datepicker@3.6.0/locale/en"
pin "@floating-ui/dom", to: "https://cdn.jsdelivr.net/npm/@floating-ui/dom@1.7.3/+esm"

pin "cable", to: "cable.js", preload: true
pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.13
