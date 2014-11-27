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
                  (args.push(injectee) if args.indexOf(injectee) is - 1) for injectee in [(@$inject ? [])...]
                  @$inject = args
                  @
            """
            explanation: """
              The inject class - method provides for angular - DI.
              Invoke it at the top of your child - class, passing in the dependencies as strings.
              Each Injectee will become available as a member var, accessible via <code> @Injectee</code>, eg. <code>@$scope</code> !
              Please remark that some extended base classes, like the Widget - Class for example, do host certain Injectees by default.
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
              The basic Controller vs. Service Registration class - methods. They enable auto - registration of classes as Angular - Instances.
              If used by your child - class, you can directly access such an instance in a directive via its string - name.
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
              The implements class - method allows for Java - like notation. Applying it on a base class kind of forces, but really advises, the extending logic to (re - ) implement the function.
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
                        for el, i in (t[0] and $(t[0], @element?.context ? document.body) or [@$element?.context])
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
              The Controller - Base - Class's constructor initializes and hooks into angular to realize the actual Dependency Injection.
              Furthermore it provides for can.js like jQuery - selector controller - based eventing and also provides an scoped index - var <code> @$scope.n</code> .
              (Due to this mechanism full - blown jQuery is a hard dependency of the plugin. The author dislikes the fact, but thinks it's worth it.)
              Prototype methods are available not only directly, but also are attached to <code> @$scope</code> , should they not be prefixed with an _underscrode.
              This way, you can, should you really want to, always use angular's intrinsic system of html - attribute eventing.
              Finally it invokes, should it exist, your class's pseudo constructor: initialize.
            """
          }
          {
            injectable: """
              class OO.DataService extends OO.Service
                  @inject "$resource", "$interval", "$q"
                  _db: (api, { @name, @persistant, @oneshot, @interval} ) ->
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
                                if (i = @db.store.indexOf(@db.store.filter (el) -> el.id is o.id)) isnt - 1
                                    (@db.store[i][k] = o[k]) for own k, v of o
                                    @db.store[i].deleted = false
                                else
                                    @db.store.push o
                                    @db.store[@db.store.length - 1].deleted = false
            """
            explanation: """
              The Service - Base - Class is to be used by extension asusual, invoking solely the _db method with it's params due.
              Once initiated, everything should be automated. Long - Polling, oneshot api calls, persistance via (angular - ) pouchdb or fast in - memory ...
              You will be able to react to new data via it's (the _db methods) returned promise.
            """
          }
          {
            injectable: """
              class OO.Widget extends OO.Ctrl
                @inject "$element"
            """
            explanation: """
              Lastly, I provide for an extra Widget - Base - Class. It solely provides for the $element injectable. Please do use
              this base class for your UI - Controllers and the Ctrl - Base - Class for any Rounting - Controllers, which are because of it's config - block early - stages initialization
              not able to receive the <code>$element</code> injectable.
              The $element injectable is needed for a certain mechanism in the eventing functionality. Basically it stops watching events further up the line as the container tag.
            """
          }
        ]
        $scope.action = [
            {
                injectable: """
                    Clazz = angular.injector(['angular-clazz'])?.get? 'Clazz'
                """
                explanation: """
                    Now let's see the plugin in action.
                    I for one tend to organize my different classes in separate files - separation of concern-like.
                    <ul>
                        <li>There's a lib coffee that might backfeed my personal library at some point. It serves for my base functionality/classes.</li>
                        <li>There's a services coffee.</li>
                        <li>There's a main coffee for the routing controllers</li>
                        <li>And there's a ui coffee for the regular controllers</li>
                    </ul>
                    Now there rises a question as how to start. Where will I inject the plugin and what about a module dependency?
                    Easy come, easy go. You could inject the plugin as a module dependency, but then, where would you inject it?
                    I just boasted that the module is capable of registering the class as a services/controller all by itself by a class-method <code>@register</code> ...
                    Gladly, there is the <code>angular.injector([String, String2, ...])</code> method. We'll use it like so:
                """
            }
            {
                explanation: """
                    So let's start by adding an evil<sup>tm</sup> Main-Controller. Basically I'm talking Routing-Controllers here, so not a directive's controller, but a Ctrl you'd use for a <code>$routeProvider.when(...)</code>-block.
                    Since it is not a Widget and shall-not-manipulate-the-DOM<sup>tm</sup>, but rather ... ok, what exactly are those kind of controllers for anyway?!?
                    Maybe we'll handle Credentials/Server-side-login here. So let's assume we're basically checking authentication during initialization ... maybe it looks like:
                """
                injectable: """
                    class Main extends Clazz.Ctrl

                        @inject "MyConfigValue", "$location", "$http"
                        @register "myAppMod", "Main"

                        initialize: () ->
                            @$http.get('/path/to/auth-check').success (response) =>
                                if response.yourJsonFormat is "yourBool"
                                    @MyConfigValue.importantSetting = true
                                    @$location.url "my/new/path/to/my/secure/page"
                """
            }
            {
                explanation: """
                    OK, but this might be not the best of use cases. Let's move on.
                    So, in fact, I think it best to organize all pattern-triples into widgets - kinda resembling the upcoming web-components.
                    <em>Don't forget, for data communication we gotta use Services!</em>
                    So, let's build a Widget/Directive!
                    We'll inject a custom Service I'll show you later how to create/use, we'll use behaviours and we'll properly use functional inheritance.
                    <br><br>
                    To use behaviours, the annotation style is as following: <code>"CssSelection::jQueryEvent": foo</code><br>
                    To use the same behaviour in a dynamically created element we can use delegates like:<br><code>[optional, defaults to $element]parentElCssSelection::jQueryEvent::triggerElCssSelection[optional: >parentSiblingElCssSelection]</code><br>
                    So, you could write: <code>"::click::i.fa.fa-home>li.navitem"</code> to cover the case of a dynamically created Nav which is only triggered by a part of the `sub-component/partial` that might be the nav-el.<br>
                    <em>Why?</em> Usually you'll want to identify the sibling clicked by a counter, which will be auto-available (and auto-updated on event) as <code>@$scope.n</code>. To give me a chance to identify which element I'm to calculate
                    the sibling-count of, we might need to add the <code>&gt;parentSiblingElCssSelection</code>-symbol. If you trigger via a valid sibling itself, there's no such need.
                """
                injectable: """
                    class MyWidget extends Clazz.Widget
                    .mixin MyClazzyLib.StandardBehaviours, MyClazzyLib.HelperFoos

                        @inject "MyConfigValuesPseudoGlobal", "MyDataService", "$interval", "$timeout"
                        @register "myAppMod", "MyWidget"

                        initialize: () =>
                            @_api = {
                                module: @MyConfigValuesPseudoGlobal.modules.specificModuleType.path
                                sub: @MyConfigValuesPseudoGlobal.modules.specificModuleType.sub.specificWidgetInterest.path
                            }

                            initInterval = @$interval () =>
                                promise = MyDataService.get @_api
                                promise.then (response) =>
                                    @$interval.cancel initInterval
                                    MyDataService.digestAndTriggerListeners?()
                                promise.catch () => console.warn "Having trouble initializing the Widget ... retrying to fetch base data"

                            super

                        ".logout.button::click": () =>
                            @_doSomethingSpecific() #underscore prefixed class methods are kinda ng-private, they don't make a copy of themselves in @$scope
                            @_behaviours "logout" #say we inherited that foo from MyClayyzLib.StandardBehaviours - and it seems to be a factory too :)

                        "::sortstop::.sortable": () =>
                            return false #TODO: implement behaviour on jQueryUI sorting :)

                        mutation: (service) =>
                            #You might want to create an extended BaseDataService that implements Listener mechanisms and triggers this method on change
                            switch service
                                when "MyDataService"
                                    @$scope.data.widgetSpecific = @MyDataService.db.store.widgetSpecificData
                                    #trigger digest cycle or something ...
                                when "SomeOtherDataService"
                                    @$scope.data.widgetSpecific2 #TODO hook it up
                """
            }
        ]
