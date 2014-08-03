// Generated by CoffeeScript 1.7.1
(function() {
  var module,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module = angular.module("angular-clazz", ['pouchdb']);

  module.provider("Clazz", function() {
    var OO, _DB;
    _DB = angular.injector(['pouchdb']).get('pouchdb');
    OO = {};
    OO.Injectable = (function() {
      function Injectable() {}

      Injectable.inject = function() {
        var args, injectee, _i, _len, _ref, _ref1;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref1 = __slice.call((_ref = this.$inject) != null ? _ref : []).concat(["$scope"]);
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          injectee = _ref1[_i];
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

      Ctrl.register = function(app, name) {
        var _ref;
        if (name == null) {
          name = this.name || ((_ref = this.toString().match(/function\s*(.*?)\(/)) != null ? _ref[1] : void 0);
        }
        if (typeof app === "string") {
          angular.module(app).controller(name, this);
        } else {
          app.controller(name, this);
        }
        return this;
      };

      Ctrl.mixin = function() {
        var Mixed, method, mixin, mixins, name, _fn, _i, _len, _ref;
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
          _ref = mixin.prototype;
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
          for (name in _ref) {
            method = _ref[name];
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
        var args, el, fn, i, index, key, t, _fn, _i, _j, _len, _len1, _ref, _ref1, _ref2;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        _ref = this.constructor.$inject;
        for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
          key = _ref[index];
          this[key] = args[index];
        }
        _ref1 = this.constructor.prototype;
        for (key in _ref1) {
          fn = _ref1[key];
          if (typeof fn === "function" && ["constructor", "initialize"].indexOf(key) === -1 && key[0] !== "_") {
            if (key.match("::")) {
              t = key.split("::");
              _ref2 = Sizzle(t[0], document.body);
              _fn = (function(_this) {
                return function(el, i) {
                  return angular.element(el).on(t[1], function() {
                    var args;
                    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
                    _this.$scope.n = i;
                    fn.apply(_this, args);
                    return _this.$scope.$apply();
                  });
                };
              })(this);
              for (i = _j = 0, _len1 = _ref2.length; _j < _len1; i = ++_j) {
                el = _ref2[i];
                _fn(el, i);
              }
            } else {
              this.$scope[key] = (function(_this) {
                return function() {
                  var args;
                  args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
                  fn.apply(_this, args);
                  return _this;
                };
              })(this);
            }
          }
        }
        if (typeof this.initialize === "function") {
          this.initialize();
        }
      }

      return Ctrl;

    })(OO.Injectable);
    OO.DB = (function(_super) {
      __extends(DB, _super);

      function DB() {
        return DB.__super__.constructor.apply(this, arguments);
      }

      DB.inject("$resource", "$interval");

      DB.prototype._createDB = function(api, name) {
        var _base;
        if ((_base = this.$scope).db == null) {
          _base.db = {};
        }
        if (this.api == null) {
          this.api = {};
        }
        this.$scope.db[name] = {
          busy: false,
          handle: api != null ? this.$resource(api) : null,
          raw: [],
          store: _DB.create(this.name)
        };
        if (this instanceof OO.View) {
          return this.$interval(((function(_this) {
            return function() {
              return _this._api(name);
            };
          })(this)), 15000);
        } else if (this instanceof OO.Widget) {
          this._listen(name);
          return this.$scope.db[name].store.info().then((function(_this) {
            return function(info) {
              if (parseInt(info.doc_count) === 0) {
                return _this._api(name);
              } else {
                return _this._broadcast(name, {
                  db: _this.$scope.db[name].store,
                  doc: null,
                  count: parseInt(info.doc_count)
                });
              }
            };
          })(this))["catch"](function(err) {
            console.log("error in db " + name + " while trying to see if it existed already ...");
            throw err.toString();
          });
        }
      };

      DB.prototype._api = function(name) {
        if (this.$scope.db[name].busy === true) {
          return;
        }
        this.$scope.db[name].busy = true;
        return this.$scope.db[name].handle.get().$promise.then((function(_this) {
          return function(data) {
            _this._store(name, data);
            return _this.$scope.db[name].busy = false;
          };
        })(this));
      };

      DB.prototype._store = function(name, data) {
        var o, _i, _len, _results;
        console.log("Schreibe das jetzt in die Datenbank");
        console.log(data);
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          o = data[_i];
          _results.push((function(_this) {
            return function(o) {
              return _this.scope.db[name].store.query(function(doc) {
                if (doc.id === o.id) {
                  return emit(doc);
                }
              }).then(function(doc) {
                if (doc.error !== "not_found") {
                  o._rev = doc._rev;
                  o._id = doc._id;
                }
                return _this.$scope.db[name].store.put(o).then(function(response) {
                  return _this._broadcast(name, {
                    db: _this.$scope.db[name].store,
                    doc: o,
                    count: 1
                  });
                })["catch"](function(err) {
                  console.log("db error: couldn't put " + (o.toString()));
                  throw err.toString();
                });
              })["catch"](function(err) {
                console.log("db error: couldn't query for " + (o.toString()));
                throw err.toString();
              });
            };
          })(this)(o));
        }
        return _results;
      };

      DB.prototype._broadcast = function(name) {
        return this.$scope.$broadcast("db.changed." + name, this.$scope.db[name].store);
      };

      DB.prototype._listen = function(name) {
        return this.$scope.$on("db.changed." + name, (function(_this) {
          return function() {
            var args, ev;
            ev = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
            args.unshift(name);
            return _this._transform.apply(_this, args);
          };
        })(this));
      };

      return DB;

    })(OO.Injectable);
    OO.View = (function(_super) {
      __extends(View, _super);

      function View() {
        return View.__super__.constructor.apply(this, arguments);
      }

      View.inject();

      return View;

    })(OO.Ctrl);
    OO.DynamicView = (function(_super) {
      __extends(DynamicView, _super);

      function DynamicView() {
        return DynamicView.__super__.constructor.apply(this, arguments);
      }

      return DynamicView;

    })(OO.View.mixin(OO.DB));
    OO.Widget = (function(_super) {
      __extends(Widget, _super);

      function Widget() {
        return Widget.__super__.constructor.apply(this, arguments);
      }

      Widget.inject();

      return Widget;

    })(OO.Ctrl);
    OO.DynamicWidget = (function(_super) {
      __extends(DynamicWidget, _super);

      function DynamicWidget() {
        return DynamicWidget.__super__.constructor.apply(this, arguments);
      }

      return DynamicWidget;

    })(OO.Ctrl.mixin(OO.DB)["implements"]("_transform"));
    this.$get = function() {
      return OO;
    };
  });

}).call(this);
