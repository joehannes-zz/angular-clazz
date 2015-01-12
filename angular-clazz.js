// Generated by CoffeeScript 1.8.0
(function() {
  var module,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module = angular.module("angular-clazz", []);

  module.provider("Clazz", function() {
    var OO, err, _DB, _ref;
    try {
      _DB = (_ref = angular.injector(['pouchdb'])) != null ? typeof _ref.get === "function" ? _ref.get('pouchdb') : void 0 : void 0;
    } catch (_error) {
      err = _error;
      console.info("Angular-PouchDB not available - you can't use local persistance, but volatile version is available");
    }
    OO = {};
    OO.Injectable = (function() {
      function Injectable() {}

      Injectable.inject = function() {
        var args, injectee, _i, _len, _ref1, _ref2;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref2 = __slice.call((_ref1 = this.$inject) != null ? _ref1 : []);
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          injectee = _ref2[_i];
          if (args.indexOf(injectee) === -1) {
            args.push(injectee);
          }
        }
        this.$inject = args;
        return this;
      };

      return Injectable;

    })();
    OO.Ctrl = (function(_super) {
      __extends(Ctrl, _super);

      Ctrl.inject("$scope");

      Ctrl.register = function(app, name) {
        var _ref1;
        if (name == null) {
          name = this.name || ((_ref1 = this.toString().match(/function\s*(.*?)\(/)) != null ? _ref1[1] : void 0);
        }
        if (typeof app === "string") {
          angular.module(app).controller(name, this);
        } else {
          app.controller(name, this);
        }
        return this;
      };

      Ctrl.mixin = function() {
        var Mixed, method, mixin, mixins, name, _fn, _i, _len, _ref1;
        mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        Mixed = (function(_super1) {
          __extends(Mixed, _super1);

          function Mixed() {
            return Mixed.__super__.constructor.apply(this, arguments);
          }

          return Mixed;

        })(this);
        for (_i = 0, _len = mixins.length; _i < _len; _i++) {
          mixin = mixins[_i];
          _ref1 = mixin.prototype;
          _fn = function() {
            var m, n, _m;
            m = method;
            _m = Mixed.prototype[name];
            n = name;
            if (name === "initialize" && (Mixed.prototype.initialize != null)) {
              return Mixed.prototype.initialize = function() {
                m.call(this);
                return _m.call(this);
              };
            } else if (name !== "constructor" && (Mixed.prototype[name] == null)) {
              return Mixed.prototype[name] = m;
            }
          };
          for (name in _ref1) {
            method = _ref1[name];
            _fn();
          }
          for (name in mixin) {
            if (!__hasProp.call(mixin, name)) continue;
            method = mixin[name];
            if (angular.isFunction(method)) {
              Mixed[name] = method;
            }
          }
          Mixed.inject.apply(Mixed, mixin.$inject);
        }
        return Mixed;
      };

      Ctrl["implements"] = function() {
        var Interface, Interfaced, interfaces, _fn, _i, _len;
        interfaces = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        Interfaced = (function(_super1) {
          __extends(Interfaced, _super1);

          function Interfaced() {
            return Interfaced.__super__.constructor.apply(this, arguments);
          }

          return Interfaced;

        })(this);
        _fn = function(Interface) {
          return Interfaced.prototype[Interface] = function() {
            throw {
              msg: "Looks like the interface _" + Interface + "_ hasn't been implemented! This will lead to unpredictable behaviour!"
            };
          };
        };
        for (_i = 0, _len = interfaces.length; _i < _len; _i++) {
          Interface = interfaces[_i];
          _fn(Interface);
        }
        return Interfaced;
      };

      function Ctrl() {
        var args, fn, index, key, _i, _len, _ref1, _ref2;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref1 = this.constructor.$inject;
        for (index = _i = 0, _len = _ref1.length; _i < _len; index = ++_i) {
          key = _ref1[index];
          this[key] = args[index];
        }
        _ref2 = this.constructor.prototype;
        for (key in _ref2) {
          fn = _ref2[key];
          if (typeof fn === "function" && ["constructor", "initialize"].indexOf(key) === -1 && key[0] !== "_") {
            (function(_this) {
              return (function(key, fn) {
                var el, i, t, _j, _len1, _ref3, _ref4, _ref5, _ref6, _results;
                if (key.match("::")) {
                  t = key.split("::");
                  if ((t[2] != null) && t[2].indexOf(">") !== -1) {
                    t = t.splice(0, 2).concat(t[0].split(">"));
                  }
                  _ref6 = t[0] && $(t[0], (_ref3 = (_ref4 = _this.element) != null ? _ref4.context : void 0) != null ? _ref3 : document.body) || [(_ref5 = _this.$element) != null ? _ref5.context : void 0];
                  _results = [];
                  for (i = _j = 0, _len1 = _ref6.length; _j < _len1; i = ++_j) {
                    el = _ref6[i];
                    _results.push((function(el, i) {
                      var listenerO;
                      listenerO = [t[1]];
                      if (t[2] != null) {
                        listenerO.push(t[2]);
                      }
                      listenerO.push(function() {
                        var args, ev, j, _k, _len2, _ref7;
                        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
                        if (t[2] != null) {
                          ev = args[0];
                          if (t[3] != null) {
                            _this.$scope.n = $(ev.currentTarget).closest(t[3]).index();
                          } else {
                            _ref7 = $(ev.currentTarget).parent().children().get();
                            for (j = _k = 0, _len2 = _ref7.length; _k < _len2; j = ++_k) {
                              el = _ref7[j];
                              if (el === ev.currentTarget) {
                                _this.$scope.n = j;
                              }
                            }
                          }
                        }
                        fn.apply(_this, args);
                        if (!_this.$scope.$$phase) {
                          return _this.$scope.$digest();
                        }
                      });
                      return angular.element(el).on.apply(angular.element(el), listenerO);
                    })(el, i));
                  }
                  return _results;
                } else {
                  return _this.$scope[key] = function() {
                    var args;
                    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
                    fn.apply(_this, args);
                    return _this;
                  };
                }
              });
            })(this)(key, fn);
          }
        }
        if (typeof this.initialize === "function") {
          this.initialize();
        }
      }

      return Ctrl;

    })(OO.Injectable);
    OO.Service = (function(_super) {
      __extends(Service, _super);

      Service.register = function(app, name) {
        var _ref1;
        if (name == null) {
          name = this.name || ((_ref1 = this.toString().match(/function\s*(.*?)\(/)) != null ? _ref1[1] : void 0);
        }
        if (typeof app === "string") {
          angular.module(app).service(name, this);
        } else {
          app.service(name, this);
        }
        return this;
      };

      function Service() {
        var args, index, key, _i, _len, _ref1;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref1 = this.constructor.$inject;
        for (index = _i = 0, _len = _ref1.length; _i < _len; index = ++_i) {
          key = _ref1[index];
          this[key] = args[index];
        }
        if (typeof this.initialize === "function") {
          this.initialize();
        }
      }

      return Service;

    })(OO.Injectable);
    OO.DataService = (function(_super) {
      __extends(DataService, _super);

      function DataService() {
        return DataService.__super__.constructor.apply(this, arguments);
      }

      DataService.inject("$resource", "$interval", "$q", "$timeout");

      DataService.prototype._db = function(api, _arg) {
        var _ref1;
        this.name = _arg.name, this.persistant = _arg.persistant, this.oneshot = _arg.oneshot, this.interval = _arg.interval;
        if (this.persistant == null) {
          this.persistant = false;
        }
        this.oneshot = this.oneshot === true || (this.interval == null);
        if (((_ref1 = this.db) != null ? _ref1.busy : void 0) === true) {
          this.$timeout((function(_this) {
            return function() {
              if (_this.oneshot === true) {
                return _this.q.reject();
              } else {
                return _this.q.notify(false);
              }
            };
          })(this), 0);
        }
        this.q = this.$q.defer();
        this.db = {
          busy: false,
          ready: false,
          handle: api != null ? this.$resource(api) : null,
          store: this.persistant && _DB.create(this.name) || []
        };
        this._api();
        if (this.oneshot === false) {
          this.$interval(this._api.bind(this), this.interval);
        }
        return this.q.promise;
      };

      DataService.prototype._api = function() {
        if (this.db.busy === true) {
          return;
        }
        this.db.busy = true;
        return this.db.handle.get().$promise.then((function(_this) {
          return function(data) {
            var _ref1, _ref2;
            console.info("success " + _this.name);
            _this._store((_ref1 = data[_this.name]) != null ? _ref1 : data);
            _this.db.busy = false;
            if (!_this.persistant) {
              if (_this.oneshot !== false) {
                if ((_ref2 = _this.q) != null) {
                  _ref2.resolve();
                }
                _this.q = null;
                _this.q = _this.$q.defer();
              } else {
                _this.q.notify(true);
              }
            }
            return _this.db.ready = true;
          };
        })(this))["catch"]((function(_this) {
          return function(err) {
            var _ref1;
            console.warn("err " + _this.name);
            if (_this.oneshot !== false) {
              if ((_ref1 = _this.q) != null) {
                _ref1.reject();
              }
              _this.q = null;
              return _this.q = _this.$q.defer();
            } else {
              return _this.q.notify(false);
            }
          };
        })(this));
      };

      DataService.prototype._store = function(data) {
        var o, _data, _i, _j, _k, _len, _len1, _len2, _ref1, _results, _results1;
        _data = Object.prototype.toString.call(data) === "[object Array]" ? data : [data];
        if (this.persistant) {
          _results = [];
          for (_i = 0, _len = _data.length; _i < _len; _i++) {
            o = _data[_i];
            _results.push((function(_this) {
              return function(o) {
                return _this.db.store.query(function(doc, emit) {
                  if (doc.id === o.id) {
                    return emit(doc);
                  }
                }).then(function(doc) {
                  console.info('#Data for id _#{o.id}_ will be updated now');
                  if (doc.error !== "not_found" && doc.total_rows === 1) {
                    o._id = doc.rows[0].key._id;
                    return o._rev = doc.rows[0].key._rev;
                  }
                })["catch"](function(err) {
                  console.warn("db error: couldn't query for " + o.id);
                  throw err.toString();
                })["finally"](function() {
                  var args;
                  args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
                  return _this.db.store.put(o, o.id, o._rev).then(function(response) {
                    if (_this.oneshot === true) {
                      _this.q.resolve();
                      return _this.q = null;
                    } else {
                      return _this.q.notify(true);
                    }
                  })["catch"](function(err) {
                    console.warn("db error: couldn't put " + (o.toString()));
                    if (_this.oneshot === true) {
                      _this.q.reject();
                      return _this.q = null;
                    } else {
                      return _this.q.notify(false);
                    }
                  });
                });
              };
            })(this)(o));
          }
          return _results;
        } else {
          _ref1 = this.db.store;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            o = _ref1[_j];
            o.deleted = true;
          }
          _results1 = [];
          for (_k = 0, _len2 = _data.length; _k < _len2; _k++) {
            o = _data[_k];
            _results1.push((function(_this) {
              return function(o) {
                var i, k, v;
                if ((i = _this.db.store.indexOf(_this.db.store.filter(function(el) {
                  return el.id === o.id;
                }))) !== -1) {
                  for (k in o) {
                    if (!__hasProp.call(o, k)) continue;
                    v = o[k];
                    _this.db.store[i][k] = o[k];
                  }
                  return _this.db.store[i].deleted = false;
                } else {
                  _this.db.store.push(o);
                  return _this.db.store[_this.db.store.length - 1].deleted = false;
                }
              };
            })(this)(o));
          }
          return _results1;
        }
      };

      return DataService;

    })(OO.Service);
    OO.Widget = (function(_super) {
      __extends(Widget, _super);

      function Widget() {
        return Widget.__super__.constructor.apply(this, arguments);
      }

      Widget.inject("$element");

      return Widget;

    })(OO.Ctrl);
    this.$get = function() {
      return OO;
    };
  });

}).call(this);
