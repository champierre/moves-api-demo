[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

### About this app

This app counts how many days in a month you went to the place you specify, using [Moves](https://moves-app.com) API.
For example, a freelance can easily counts working days and charges the fee to the client.
It is based on the [sample app](https://github.com/movesapp/moves-api-demo) that Moves provides.

### How to setup

If you have an account, you can easily run this app on Heroku.

1. Click the "Deploy to Heroku" button at the top of this README.

2. Set the following config variables. You need to create a developer account at https://dev.moves-app.com/ to get Moves client id and client secret.

```
$ heroku config:set MOVES_CLIENT_ID=<your client id>
$ heroku config:set MOVES_CLIENT_SECRET=<your client secret>
$ heroku config:set WORKING_PLACE_NAME=<place name that you want to count how many days you went there>
```

### How to use

After authorizing by clicking "Authorize Moves API Demo" button, select "Workdays" at the top of the menu.
You get how many days you visited the place you specified in the previous month.

![moves api sample](https://dl.dropboxusercontent.com/u/385564/blog/20160116/1.png)
