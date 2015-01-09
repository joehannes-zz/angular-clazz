'use strict'

###*
 # @ngdoc overview
 # @name App
 # @description
 # # App
 #
 # Main module of the application.
###
angular
  .module('App', [
    'ngRoute'
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

