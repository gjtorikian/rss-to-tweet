# rss-to-tweet

Given the path to an RSS file, this Sinatra server will automatically tweet the latest entry on a successful GitHub Pages build.

## Setup

You'll need to set up several environment variables for this app to work:

| Option | Description | Example
| :----- | :-----------| :----- |
| `SECRET_TOKEN` | This establishes a private token to secure your payloads. This token is used to [verify that the payload came from GitHub](https://developer.github.com/webhooks/securing/). | Random string.
| `RSS_PATH` | The path to your RSS or Atom file. | https://example.com/changes.atom
| `DATE_PATH` | The XPath to the latest date information in the `RSS_PATH`. | `feed/updated`
| `ENTRY_TITLE_PATH` | The XPath to the latest title in the `RSS_PATH`. | `//feed/entry[1]/title`
| `ENTRY_URL_PATH` | The XPath to the latest URL in the `RSS_PATH`. | `//feed/entry[1]/link/@href`
| `CONSUMER_KEY`, `CONSUMER_SECRET`, `ACCESS_TOKEN`, `ACCESS_TOKEN_SECRET` |  The access tokens obtained from a new Twitter OAuth app. | Varying random strings.
| `MACHINE_USER_TOKEN` | This is [the access token the server will act as](https://help.github.com/articles/creating-an-access-token-for-command-line-use) when syncing between the repositories. | Random string.
