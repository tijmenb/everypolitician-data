# everypolitician-data

This repo contains the data that powers [EveryPolitician.org](http://everypolitician.org/), and other sites such as [Gender-Balance.org](gender-balance.org)

Information on how to _use_ the data can be found at http://everypolitician.org/technical.html, and high-level information about how to contribute is at http://everypolitician.org/contribute.html

This document is for developers actively working _on_ the project, rather than consuming data from it.

## Adding a new country

1. Make a new subdirectory in `data` named for the Country

    If this is for a legislature that does not map cleanly to an ISO 3166-1 country code (e.g. Wales, Kosovo), or you name the directly differently from what the Ruby [iso_country_codes gem understands](https://github.com/alexrabarts/iso_country_codes/blob/master/lib/iso_country_codes/iso_3166_1.rb) (e.g. Congo-Brazzaville), you will also need to supply a `meta.json` (see those examples for details)

2. Make a separate subdirectory within the Country for each distinct legislature or chamber

    i.e. both the upper and lower houses of a bicameral legislature should have separate directories, as should successor bodies (e.g. in Libya, the National Transitional Council, General National Congress, and Council of Deputies are all distinct).

3. Add a `meta.json` for the legislature. This *must* include fields for the legislature `name`, and how many `seats` it currently has. It *should* also contain a `wikidata` reference code. See, for example, [Poland](https://github.com/everypolitician/everypolitician-data/blob/master/data/Poland/Sejm/meta.json)

4. Provide a `Rakefile.rb` that knows how to build the data. Usually this is a matter of `include`-ing an existing Rakefile and supplying some configuration, but this process has evolved significantly over time and there are currently two main approaches. Both versions involve, at a minimum, generating/downloading a file of Membership information and a file of Legislative Period / Term information, and combining these into a standardised JSON format (based on Popolo), and then splitting it up in a series of period-based CSVs.

### The simple Morph.io version

(to come)

### The more flexible, but more convoluted new version

(to come)

## Building the data for a legislature

1. From within the directory for that legislature it should usually be enough to run `rake clean && bundle exec rake`. If you want to fetch fresh data from the source(s) (e.g. Morph.io), then use `rake clobber && bundle exec rake` instead.

2. Make sure that the changes look sensible, and then commit the new/refreshed data.

3. From the root directory of the project run `bundle exec rake` again. This updates the master `countries.json` map with this new information (and includes the sha of the commit, so needs to be run *after* step 2)



