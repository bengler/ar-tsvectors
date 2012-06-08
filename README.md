# ActiveRecord support for ts_vectors

This small library extends ActiveRecord to support PostgreSQL's `tsvector` type. PostgreSQL's `tsvector` stores an array of keywords that can be efficiently queried. The `tsvector` type is therefore particularly suitable for storing tags, since it's possible to store all tags in a single column instead of a table.

## Requirements

* ActiveRecord
* PostgreSQL with `tsvector` support. (This has been included out of the box since 8.3.)

## Usage

Add gem to your `Gemfile`:

    gem 'ar-tsvectors', :require => 'activerecord_tsvectors'

To test, add a `text` column to your table in a migration:

    add_column :posts, :tags, :text

Then extend your ActiveRecord model with a declaration:

    class Post < ActiveRecord::Base
      ts_vector :tags
    end

Now you can assign tags:

    post = Post.new
    post.tags = ['pizza', 'pepperoni', 'Italian', 'mushrooms']
    post.save

You can now query based on the tags:

    Post.with_all_tags('pizza')
    Post.with_all_tags(['pizza', 'pepperoni'])

For queries to perform well, you must add an index on the column. This is slightly more complicated; again, in a migration:

    execute("create index index_posts_on_tags on posts using gin(to_tsvector('simple', tags))")

## Options

The `ts_vector` mixin takes the following options:

* `:configuation` - the name of the PostgreSQL text configuration to use. Defaults to `simple`, which is appropriate for keyword-type indexing.
* `:format` - the format of the column, must be either `:text` (the default) or `:tsvector`.
* `:normalize` - a proc that overrides the default normalization. It must take a single string and return a normalized copy of the string.

## Methods

Declaring a `tsvector` column `tags` will dynamically add the following methods:

* `with_all_tags(t)` - returns a scope that searches for `t`, which may be either a single value or an array of values. Only rows matching _all_ values will be returned.
* `without_all_tags(t)` - returns a scope that excludes `t`, which may be either a single value or an array of values. Only rows matching _all_ values will be excluded.
* `with_any_tags(t)` - returns a scope that searches for `t`, which may be either a single value or an array of values. Rows matching at least one of the provided values will be returned.
* `without_any_tags(t)` - returns a scope that excludes `t`, which may be either a single value or an array of values. Rows matching at least one of the provided values will be excluded.
* `order_by_tags_rank(t, direction = 'DESC')` - returns a scope that orders the rows by the rank, ie. a score computed based on the overlap of `t` and the row's value. See below for an example.

## Ranking

It's trivial to rank results according to how many values match a given row:

    @posts = Post.with_any_tags(["pizza", "pepperoni"]).
      order_by_tags_rank(["pizza", "pepperoni"])

This orders the rows such that rows matching _both_ `pizza` and `pepperoni` will be ordered above rows matching _either_ `pizza` or `pepperoni` but not both.

## Normalization

The default behaviour is to downcase and strip leading and trailing spaces from assigned values. By default, matches are case-sensitive; so something tagged with `PIZZA` will not match a search for `pizza`. To ensure case insensitivity, you can provide a normalization function, like so:

    class Post < ActiveRecord::Base
      ts_vector :tags, :normalize => lambda { |v| v.downcase }
    end

You can also use this to strip unwanted characters:

    class Post < ActiveRecord::Base
      ts_vector :tags, :normalize => lambda { |v| v.downcase.gsub(/[^\w]/, '') }
    end

The values are normalized both when performing queries, and when assigning new values:

    post.tags = ['  WTF#$%^   &*??!']
    post.tags
    => ['wtf']

## Using ts_vector directly

It's possible to use the `tsvector` type for the column directly. In other words, in your migration would have something like:

    add_column :posts, :tags, :tsvector

This is supported by supplying a format option to the `ts_vector` declaration in your model:

    class Post < ActiveRecord::Base
      ts_vector :tags, :format => :tsvector
    end

When you do this, the way you define a table index is slightly different:

    execute("create index index_posts_on_tags on posts using gin(tags)")

While using a `tsvector` column works, it has some drawbacks:

* The `tsvector` type is lossy. When you assign values to a `tsvector`, the text will be tokenized by PostgreSQL's text parser, which will remove all punctuation and quotes from the text. In this system, a quoted tag such as `"New York"` will be split into two different tags `New` and `York`, and it's no longer possible to search for `New York` as a distinct tag.

* Due to a limitation in ActiveRecord, stored column values (on `INSERT` and `UPDATE`) are passed to PostgreSQL as strings, and are therefore *not* normalized using the text configuration's rules. This means that if you override the normalization function, you must make sure you always strip and downcase in addition to whatever other normalization you do, otherwise queries will potentially *not* match all rows. A forthcoming version of ActiveRecord will provide the plumbing that will allow us to solve this issue.
