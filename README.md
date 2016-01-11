# ruby_code_analytics

This is a Rails app which allows you to run some code which you can subsequently analyze.  The data is stored in a Neo4j database and displayed via the app's UI.

## Quick Setup

 * Checkout this repository
 * Run:
   * `bundle install`
   * `rake neo4j:install[community-latest]`
   * (optionally) `rake neo4j:config[development,<port>]` to change the port Neo4j runs on
   * `rake neo4j:start`
   * `rails runner run.rb` to analyze the code in run.rb (feel free to change the code within the `record_execution` block)
 * Start Rails (`rails server`)
 * Visit [http://localhost:3000](http://localhost:3000)

## Model

SCREENSHOTS HERE

See the [neolytics gem's README](https://github.com/neo4jrb/neolytics) for some example queries that you could run in your database.

`TODO: SHOW EXAMPLE OUTPUTS OF QUERIES BELOW`

