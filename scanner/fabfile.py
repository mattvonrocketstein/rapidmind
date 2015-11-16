from fabric import api

def build():
  api.local('mix escript.build')

def run():
  build()
  api.local('./scanner --reddit programming --rules rules.json')
