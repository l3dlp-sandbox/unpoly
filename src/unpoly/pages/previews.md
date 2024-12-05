Previews
========

Previews are temporary page changes while waiting for a network request.
You can show arbitrary loading state (like spinners or placeholders) and even do optimistic rendering.

Because previews immediately appear after a user interaction, their use
increases the perceived responsiveness of your application.


## Overview {#overview}

Previews are small functions that can
be attached to a [link](/up-follow), [form](/up-submit) or any [programmatic render pass](/up.render).

When the user interacts with a link or form, its preview function is invoked immediately.
The function will usually [mutate the DOM](#dom-mutations) in a way the user gets
a preview of the interaction effect. For example, if the user is deleting an item from a list, the preview
function could hide that item visually.

When the request ends for *any* reason, all preview changes will be reverted before
the server response is processed (usually by updating a fragment).
This ensures a consistent state where we end up *not* updating the [targeted fragment](/targeting-fragments),
such as:

- when the server [renders an error code](/failed-responses#rendering-failed-responses-differently)
- when the request encounters a [fatal error](/failed-responses#handling-fatal-network-errors), like a timeout or loss of network connectivity.
- when the server [updates a different fragment](/X-Up-Target)
- when the request is [aborted](/aborting-requests), e.g. by a different link targeting the same fragment
- when an `up:fragment:loaded` listener chooses to open an overlay

Unpoly provides utility functions to [make temporary DOM mutations](#basic-mutations) that automatically revert
when the preview ends. For advanced cases you may also apply [arbitrary mutations](#advanced-mutations),
as long as you revert them cleanly when the preview ends.


## Mutating the DOM from a preview {#basic-mutations}

For a simple example, we want to show a simple spinner animation
within a button while it is loading:

<video src="images/button-spinner.mp4" controls loop width="350" aria-label="A button showing a spinning animation when pressed"></video>

To achieve this effect, we define a *preview* named `link-spinner`:

```js
up.preview('link-spinner', function(preview) {
  let link = preview.origin
  preview.insert(link, '<img src="spinner.gif">')
})
```

We can use this preview in any link or form by setting an `[up-preview]` attribute:

```html
<a href="/edit" up-follow up-preview="link-spinner">Edit page</a>
```

When the link is followed, the preview will append the spinner element to the link label.
When the server response is received, the spinner element will be removed automatically. 

The `preview` argument is an `up.Preview` instance that offers many utilities to make temporary changes:

| Method                         | Temporary effect                    |
|--------------------------------|-------------------------------------|
| `up.Preview#setAttrs()`        | Set attributes on an element        |
| `up.Preview#addClass()`        | Add a class to an element           |
| `up.Preview#removeClass()`     | Add a class to an element           |
| `up.Preview#setStyle()`        | Set inline styles on an element     |
| `up.Preview#disable()`         | Disable form controls               |
| `up.Preview#insert()`          | Append or prepend an element        |
| `up.Preview#hide()`            | Hide an element                     |
| `up.Preview#show()`            | Show a hidden element               |
| `up.Preview#hideContent()`     | Hide all children of an element     |
| `up.Preview#swapContent()`     | Replace the content of an element   |
| `up.Preview#openLayer()`       | Open an overlay                     |
| `up.Preview#showPlaceholder()` | Show a [placeholder](/placeholders) |

From JavaScript you can pass the preview name as a `{ preview }` option:

```js
up.navigate({ url: '/edit', preview: 'link-spinner' })
```


### Inspecting the preview context

The `up.Preview` object provides getters to learn more about the current render pass:

```js
up.preview('my-preview', function(preview) {
  preview.target         // The target selector
  preview.fragment       // The fragment being updated
  preview.layer          // The layer being updated
  preview.request        // The request we're waiting for
  preview.params         // Requested form params
  preview.renderOptions  // All options for this render pass
  preview.revalidating   // Whether we're previewing a cache revalidation
})
```


## Advanced mutations {#advanced-mutations}

Instead of using an `up.Preview` method you can use arbitrary changes to the DOM.

For example, this preview uses the native browser API to add a `.loading` class to the `<body>`
while a request is loading:

```js
up.preview('my-preview', function(preview) {
  // Only make a change when it is necessary. 
  if (document.body.classList.contains('loading')) return

  document.body.classList.add('loading')
  
  // Undo our change when the preview ends.
  return () => document.body.classList.remove('loading') 
})
```

In this manual approach we need to do additional work:

1. We must return a function that undoes our changes
2. We must only undo changes that we caused.
   We may have multiple concurrent previews racing for the same changes,
   and we must not undo a change done by another preview.

> [tip]
> All `up.Preview` methods automatically undo their changes and work concurrently.

Another way to register an undo action is to register a callback with `preview.undo()`.
This is especially useful when you're making multiple changes, and want to group each change and undo effect together:

```js
up.preview('my-preview', function(preview) {
  change1()
  preview.undo(() => undoChange1())

  change2()
  preview.undo(() => undoChange2())
})
```



### Prefer additive changes

While previews can change the DOM arbitrary, we recommend to not remove the targeted
fragment from the DOM. A detached fragment cannot be [aborted](/aborting-requests).

```js
up.preview('spinner', function(preview) {
  let spinner = up.element.createFromHTML('<img src="spinner.gif">')

  // ❌ Detached fragments cannot be aborted
  preview.fragment.replaceWith(spinner)

  return () => spinner.replaceWith(preview.fragment)
})
```

Instead of detaching a fragment, consider hiding it instead:

```js
up.preview('spinner', function(preview) {
  let spinner = up.element.createFromHTML('<img src="spinner.gif">')
  preview.fragment.insertAdjacentElement('beforebegin', spinner)

  // ✅ Hidden fragments can still be aborted
  up.element.hide(preview.fragment)

  return () => {
    spinner.remove()
    up.element.show()
  }
})
```

By using `up.Preview` methods (which undo automatically), we can shorten the example considerably:

```js
up.preview('spinner', function(preview) {
  preview.insert(preview.fragment, 'beforebegin', '<img src="spinner.gif">')
  preview.hide(preview.fragment)
})
```



## Preview parameters {#parameters}

Preview functions can accept an options object as a second argument.
This is useful to define multiple variations of a preview effect.

For example, the following preview accepts a `{ size }` option to show a spinner of varying size:

```js
up.preview('spinner', function(preview, { width = 50 }) {
  let spinner = up.element.createFromSelector('img', { src: 'spinner.gif', width })
  preview.insert(preview.fragment, spinner)
})
```

From HTML you can append the options to the `[up-preview]` argument, after the preview name:

```html
<a href="/edit" up-follow up-preview="spinner { size: 100 }">Edit page</a>
```

### Passing options from JavaScript

From JavaScript you can also pass the a string containing preview name and options:

```js
up.navigate({
  url: '/edit',
  preview: 'link-spinner { size: 100 }'
})
```

As an alternative, you can also pass a function that calls `preview.run()` with a preview name and options.
This makes it easier to pass option values that already exist in your scope:

```js
let size = 100

up.navigate({
  url: '/edit',
  preview: (preview) => preview.run('link-spinner', { size })
})
```



## Using previews with caching

Previews are *not* shown when rendering [cached content](/caching).
This avoids a flash when a preview is shown and immediately reverted.

After rendering cached content that is [expired](/caching#expiration),
Unpoly will usually [revalidate](/caching#revalidation) the fragment by reloading it.
To show a preview for the revalidating request, use the `[up-revalidate-preview]` attribute instead:

```html
<a href="/clients"
   up-follow
   up-preview="index-placeholder"
   up-revalidate-preview="spinner"> <!-- mark-phrase "up-revalidate-preview" -->
  Clients
</a>
```

The revalidation preview is run after the expired content has been rendered.
Hence the preview can modify a DOM tree showing the destination screen (albeit with stale data).

To use the `[up-preview]` attribute for both the initial render pass, and the revalidation request, set `[up-revalidate-preview]`
to a [true value](/attributes-and-options#boolean-attributes):


```html
<a href="/clients"
   up-follow
   up-preview="spinner"
   up-revalidate-preview="true"> <!-- mark-phrase "true" -->
  Clients
</a>
```


## Delaying previews

When your backend responds quickly, a preview will only be shown for a short time
before it is reverted. To avoid a flash of preview state, you may want to
run some previews for long-running requests only.

To do this, a preview function can set a timer using `setTimeout()` or `up.util.timer()`.
After the timer expires, the preview must check if it is still running before changing the page:

```js
up.preview('delayed-spinner', (preview) => {
  up.util.timer(1000, function() {
    if (!preview.ended) { // mark-phrase "ended"
      preview.insert('<img src="spinner.gif">')      
    }
  })
}) 
```

> [important]
> When a preview changes the DOM after the preview has ended, these changes will not be reverted. 


## Multiple previews

A change can show multiple previews at once:

```html
<a href="/edit"
   up-follow
   up-preview="spinner, form-placeholder">
  Edit page
</a>
```

To pass [preview options](#parameters), append the options object after each preview name:

```html
<a href="/edit"
   up-follow
   up-preview="spinner { size: 20 }, form-placeholder { animation: 'pulse' }">
  Edit page
</a>
```

From JavaScript, pass multiple previews as either a comma-separated string or as an array:

```js
up.navigate({ url: '/edit', preview: ['spinner', 'form-placeholder'] })
```


@page previews