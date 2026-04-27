# Hacking ani-cli-mx

`ani-cli-mx` is a shell-based scraper/player wrapper. The project already supports multiple sources, but you can still extend or modify it if you need to adjust an existing source or experiment with a new one.

## Prerequisites

This guide assumes you are comfortable with:

- basic shell scripting
- HTTP(S) requests and `curl`
- reading HTML and JavaScript
- searching large text responses efficiently
- writing and debugging regular expressions

You will also need:

- a web browser with developer tools
- an environment that can run `ani-cli-mx`
- a text editor that can inspect raw responses comfortably

## The scraping process

The following flowchart demonstrates the general scraping flow used by the project:

![image](.assets/ani-cli-scraping-flow.png)

At a high level, the flow is:

1. search a source for a title
2. extract source-specific identifiers
3. list the episodes for the selected title
4. request the player or embed data for a selected episode
5. extract playable media links
6. select a quality and hand the link to the configured player

If you are adapting another source, steps 1 through 5 are where you will spend most of your time.

## Reverse engineering

Many streaming sites have protections against inspection or scraping.

The `webapi-blocker` browser extension can help when you need the debugger without background noise from aggressive client-side code, but you still need to verify what the site is actually returning over the network.

An ad blocker can reduce noise, but extensions that rewrite page styling or structure can make analysis harder. Prefer looking at raw responses.

Once you identify the relevant URLs, it is usually easier to inspect the responses in a real editor or pager than directly in the browser.

## Core concepts

The current implementation lives in [ani-cli-mx-core](./ani-cli-mx-core), while [ani-cli-mx](./ani-cli-mx) is the launcher.

Most source integrations follow the same broad pattern:

- a search function returns source-specific identifiers plus display titles
- an episode-list function turns an identifier into a selectable episode list
- a link-resolution path turns a selected episode into one or more playable URLs

In the script, the series identifier is usually stored in `id`, and the chosen episode number is stored in `ep_no`.

## Searching

Search pages are usually the easiest entry point.

Some sites use a plain GET request with a query parameter. Others POST form data or call a JSON endpoint. Inspect a few searches in the browser and reproduce the request with `curl`.

Once you understand the request shape, replicate it in the relevant source-specific search function. The response then needs to be transformed into lines that the selector code can consume, usually in a tab-separated identifier/title format.

If you get this part right, you should be able to run:

```sh
./ani-cli-mx
```

select a title, and then fail later in the flow rather than at search time.

If search still returns nothing, run the script with shell tracing:

```sh
sh -x ./ani-cli-mx
```

## Episode selection

After selecting a title, the next step is to identify where the site exposes its episode list.

That might be:

- a title overview page
- an AJAX endpoint
- a JSON blob embedded in HTML
- links listed on the episode page itself

The goal is to produce a newline-separated list of episode numbers that the selector can present to the user.

If this part is correct, you should be able to search, select a title, list episodes, and then fail later when resolving the player data.

## Getting player or embed data

Once an episode is selected, the script needs to retrieve the site-specific player or embed information for that episode.

Some sources expose this directly. Others require:

- loading the episode page first
- extracting one or more embed URLs
- decoding or transforming an intermediate value

In the current codebase, the exact function names vary by source, so the practical approach is to inspect the existing source handlers in [ani-cli-mx-core](./ani-cli-mx-core) and mirror the nearest one.

## Extracting media links

After you have the player or embed data, the next step is to extract the actual playable media URLs.

The target output format is effectively:

```text
quality >url
```

where `quality` is usually a numeric resolution label such as `720` or `1080`.

If the player does not expose a clean resolution label, use the most stable identifier available and keep the output format consistent.

Once those links are produced, the rest of the playback path can usually stay unchanged.

## Other functionality

If the source works for:

- searching
- episode enumeration
- link extraction
- quality selection

then the rest of the project usually continues to work with minimal changes, including history and player selection.

There will still be site-specific edge cases. The easiest way to debug them is to compare the failing source path with an existing working source in [ani-cli-mx-core](./ani-cli-mx-core).

## UX Spec

If you want to replicate the terminal interaction style in another implementation, this UX spec can still be useful:

![image](.assets/ani-cli-ux-spec.png)
