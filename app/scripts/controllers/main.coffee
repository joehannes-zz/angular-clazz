'use strict'

###*
 # @ngdoc function
 # @name angularClazzApp.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the angularClazzApp
###
angular.module('angularClazzApp')
  .controller 'MainCtrl', ($scope) ->
    $scope.prelude = [
      {
        injectable: """
          class OO.Injectable
            @inject: (args...) ->
              (args.push(injectee) if args.indexOf(injectee) is -1) for injectee in [(@$inject ? [])...]
              @$inject = args
              @
        """
        explanation: """
          The inject class-method provides for angular-DI.
          Invoke it at the top of your child-class, passing in the dependencies as strings.
          Each Injectee will become available as a member var, accessible via <code>@Injectee</code>, eg. <code>@$scope</code>!
          Please remark that some extended base classes, like the Widget-Class for example, do host certain Injectees by default.
        """
      }
      {
        injectable: """
          class OO.Ctrl extends OO.Injectable
            @register: (app, name) ->
              name ?= @name or @toString().match(/function\s*(.*?)\(/)?[1]
              if typeof app is "string" then angular.module(app).controller name, @
              else app.controller name, @
              @
          class OO.Service extends OO.Injectable
            @register: (app, name) ->
              name ?= @name or @toString().match(/function\s*(.*?)\(/)?[1]
              if typeof app is "string" then angular.module(app).service name, @
              else app.service name, @
              @
        """
        explanation: """
          The basic Controller vs. Service Registration class-methods. They enable auto-registration of classes as Angular-Instances.
          If used by your child-class, you can directly access such an instance in a directive via its string-name.
        """
      }
      {
        injectable: """
          class OO.Ctrl #continued
            @mixin: (mixins...) ->
              class Mixed extends @
              for mixin in mixins
                  for name, method of mixin.prototype
                      (() ->
                          m = method
                          _m = Mixed::[name]
                          n = name
                          if name is "initialize" and Mixed::initialize?
                              Mixed::initialize = () ->
                                  m.call @
                                  _m.call @
                          else if name isnt "constructor" and not Mixed::[name]? then Mixed::[name] = m
                      )()
                  (Mixed[name] = method) for own name, method of mixin when angular.isFunction method
                  Mixed.inject.apply Mixed, mixin.$inject
              Mixed
        """
        explanation: """
          Controllers allow for smart multiple inheritance. If a method already exists down the prototype chain,
          the current method is merged and appended after the 'older' method in a new prototypal function.
        """
      }
      {
        injectable: """
          class Ctrl #...again continued
            @implements: (interfaces...) ->
              class Interfaced extends @
              for Interface in interfaces
                  do (Interface) ->
                      Interfaced::[Interface] = () -> throw {
                          msg: "Looks like the interface _{Interface}_ hasn't been implemented! This will lead to unpredictable behaviour!"
                      }
              Interfaced
        """
        explanation: """
          The implements class-method allows for Java-like notation. Applying it on a base class kind of forces, but really advises, the extending logic to (re-)implement the function.
        """
      }
      {
        injectable: """
          class Ctrl #...still continued
            constructor: (args...) ->
              (@[key] = args[index]) for key, index in @constructor.$inject
              for key, fn of @constructor.prototype when typeof fn is "function" and ["constructor", "initialize"].indexOf(key) is -1 and key[0] isnt "_"
                do (key, fn) =>
                  if key.match "::"
                    t = key.split "::"
                    if t[2]? and t[2].indexOf(">") isnt -1 then t = t.splice(0, 2).concat t[0].split ">"
                    for el, i in (t[0] and Sizzle(t[0], @element?.context ? document.body) or [@$element?.context])
                      do (el, i) =>
                          listenerO = [t[1]]
                          listenerO.push(t[2]) if t[2]?
                          listenerO.push (args...) =>
                            if t[2]?
                                ev = args[0]
                                if t[3]? then @$scope.n = $(ev.currentTarget).closest(t[3]).index()
                                else (@$scope.n = j) for el, j in $(ev.currentTarget).parent().children().get() when el is ev.currentTarget
                            fn.apply @, args
                            if not @$scope.$$phase then @$scope.$digest()

                          angular.element(el).on.apply angular.element(el), listenerO
                  else
                      @$scope[key] = (args...) =>
                          fn.apply @, args
                          @
              @initialize?()
        """
        explanation: """
          The Controller-Base-Class's constructor initializes and hooks into angular to realize the actual Dependency Injection.
          Furthermore it provides for can.js like jQuery-selector controller-based eventing and also provides an scoped index-var <code>@$scope.n</code>.
          (Due to this mechanism full-blown jQuery is a hard dependency of the plugin. The author dislikes the fact, but thinks it's worth it.)
          Prototype methods are available not only directly, but also are attached to <code>@$scope</code>, should they not be prefixed with an _underscrode.
          This way, you can, should you really want to, always use angular's intrinsic system of html-attribute eventing.
          Finally it invokes, should it exist, your class's pseudo constructor: initialize.
        """
      }
      {
        injectable: """
          class OO.DataService extends OO.Service
              @inject "$resource", "$interval", "$q"
              _db: (api, { @name, @persistant, @oneshot, @interval}) ->
                @persistant ?= false
                @oneshot = not @interval?
                @q ?= @$q.defer()
                @db =
                    busy: false
                    ready: false
                    handle: if api? then @$resource(api) else null
                    store: @persistant and _DB.create(@name) or []

                @_api()
                @oneshot or @$interval @_api.bind(@), @interval
                @q.promise
              _api: () ->
                if @db.busy is true then return
                @db.busy = true
                @db.handle.get().$promise
                    .then (data) =>
                        console.info "success {@name}"
                        @_store(data[@name] ? data)
                        @db.busy = false
                        if not @persistant
                            if @oneshot is true
                                @q.resolve()
                                @q = null
                            else @q.notify(true)
                        @db.ready = true
                    .catch (err) =>
                        console.warn "err {@name}"
                        if @oneshot is true
                            @q.reject()
                            @q = null
                        else
                            @q.notify(false)
              _store: (data) ->
                if @persistant
                    for o in data
                        do (o) =>
                            @db.store.query((doc, emit) -> if doc.id is o.id then emit doc)
                                .then (doc) =>
                                    console.info '#Data for id _{o.id}_ will be updated now'
                                    if doc.error isnt "not_found" and doc.total_rows is 1
                                        o._id = doc.rows[0].key._id
                                        o._rev = doc.rows[0].key._rev
                                .catch (err) =>
                                    console.warn "db error: couldn't query for {o.id}"
                                    throw err.toString()
                                .finally (args...) =>
                                    @db.store.put(o, o.id, o._rev)
                                        .then (response) =>
                                            if @oneshot is true
                                                @q.resolve()
                                                @q = null
                                            else @q.notify(true)
                                        .catch (err) =>
                                            console.warn "db error: couldn't put {o.toString()}"
                                            if @oneshot is true
                                                @q.reject()
                                                @q = null
                                            else
                                                @q.notify(false)
                else
                    (o.deleted = true) for o in @db.store
                    for o in data
                        do (o) =>
                            if (i = @db.store.indexOf(@db.store.filter (el) -> el.id is o.id)) isnt -1
                                (@db.store[i][k] = o[k]) for own k, v of o
                                @db.store[i].deleted = false
                            else
                                @db.store.push o
                                @db.store[@db.store.length - 1].deleted = false
        """
        explanation: """
          The Service-Base-Class is to be used by extension asusual, invoking solely the _db method with it's params due.
          Once initiated, everything should be automated. Long-Polling, oneshot api calls, persistance via (angular-)pouchdb or fast in-memory ...
          You will be able to react to new data via it's (the _db methods) returned promise.
        """
      }
      {
        injectable: """
          class OO.Widget extends OO.Ctrl
            @inject "$element"
        """
        explanation: """
          Lastly, I provide for an extra Widget-Base-Class. It solely provides for the $element injectable. Please do use
          this base class for your UI-Controllers and the Ctrl-Base-Class for any Rounting-Controllers, which are because of it's config-block early-stages initialization
          not able to receive the $element injectable.
          The $element injectable is needed for a certain mechanism in the eventing functionality. Basically it stops watching events further up the line as the container tag.
        """
      }
    ]
