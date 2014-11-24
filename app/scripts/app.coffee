'use strict'

###*
 # @ngdoc overview
 # @name angularClazzApp
 # @description
 # # angularClazzApp
 #
 # Main module of the application.
###
angular
  .module('angularClazzApp', [
    'ngAnimate',
    'ngRoute',
    'ngTouch',
    'ui.ace'
  ])
  .config ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
      .when '/about',
        templateUrl: 'views/about.html'
        controller: 'AboutCtrl'
      .otherwise
        redirectTo: '/'
