---
date: '2026-07-11T00:00:00+03:00'
title: 'JavaScript sucks. Here’s how to build with Vite and Gleam'
author: 'Hendassa100k'
---

For years, I've felt this pain: the tooling is great, but the language is fundamentally flawed. JavaScript was never designed properly. I mean *never*. I've worried to even touch this language for this exact reason. Web developers spent a decade building increasingly elaborate band-aids to make it work. While TypeScript provides a safety net, it often feels like weak tape holding together a structure that wasn't built to be sane for developers. I wanted something better that doesn't change my values.

That's when I discovered [Gleam](https://gleam.run/). Gleam is a type-safe, functional programming language. While I didn't wrote a single program in functional programming language, I realized that's exactly what a scripting language should be. Gleam offers proper type safety and a functional approach that makes writing robust, safe, and concurrent code - the very things the web requires. Unlike TypeScript, it doesn't try to wrap shit in gold. It throws all of that out the window, but still leaves you a way to interact with it.

However, Gleam was initially built for Erlang. JavaScript support was a later addition, meaning the tools are still maturing. On the other hand, the JavaScript ecosystem for build tools is unparalleled.

But when I tried to find tools for this and then I stumbled across [Vite](https://vite.dev/). Vite is the ultimate glue. It handles live reloading, bundling, and asset management and all with a massive plugin ecosystem. Because Vite is plugin driven, it doesn't care what language you are writing in, as long as it can eventually turn it into something the browser understands.

By combining Gleam's type-safe logic with Vite's build pipeline, we can get the best of both worlds: The safety of functional programming with the speed of modern web tooling.

You propably saying "Dude, just use WASM". WASM is powerful, yes, but it isn't good for web development *at least for now*. It currently faces significant issues, including [limited DOM access](https://queue.acm.org/detail.cfm?id=3746174) and issues with startup times due how it is designed. Even if WASM were perfect, we still need a native scripting language to interact with the browser. JavaScript is like the "C" of the web: it is the standard, the most adopted, and the most compatible way to talk to the DOM. C and JavaScript are going to outlive the human race and it propably will never change. 

Speaking of C this is why Gleam's approach is so smart. Gleam treats JavaScript as a FFI. It doesn't try to replace the browser's native language; instead, it provides a way to interact with it safely. Gleam forces you to write type-safe code, protecting you from the JavaScript traps like `null` and unpredictable exceptions or even dynamic typing for god's sake, while still letting you use JS when you need to.

# Technical Deep Dive

## Understanding Gleam FFI

To build a production-ready app, you need to understand how Gleam interacts with the JavaScript runtime.

One of the main goals of Gleam is being multilingual. Gleam uses FFI to call JavaScript functions for that. You define the external function in your Gleam code and provide the path to the JS implementation:

```gleam
@external(javascript, "./assets.ffi.js", "get_asset")
pub fn load_asset(url: String) -> Promise(AssetResult)
```

And Gleam's strongest features is that it does not support JS types directly. You cannot simply "import" a dynamic JS object into Gleam and expect it to stay safe. Instead, Gleam forces you to define a type that represents the data.

For example, you can create a type:

```gleam
// This type has no constructors, so it cannot be initialized directly.
// It acts as a "handle" for the JS value.
pub type DateTime

@external(javascript, "./js.ffi.mjs", "now")
pub fn now() -> DateTime
```

By doing this, Gleam ensures that the rest of your application treats object as a type-safe citizen, while the actual messy work happens behind the FFI boundary.

Since JavaScript doesn't have a native Result type (it uses exceptions) or Gleams types in general, Gleam provides a `gleam.mjs` module. This allows to map JS try/catch blocks into Gleam's Result types for example:

```js
import { Result$Ok, Result$Error } from './gleam.mjs';

export function get_foo_asset(img) {
  try {
    let result = get_asset("foo.png");
    return Result$Ok(result);
  } catch (err) {
    return Result$Error(AssetError$AssetNotFound);
  }
}
```

## Building our first app with Lustre

With that in mind, let's build our first application. For this, I've chosen [Lustre](https://lustre.hexdocs.pm/index.html).

Lustre is a mature framework that follows the Elm Architecture, which feel familiar to React developers. Even though I hate the Virtual DOM, there is a good reason to use it: it is significantly safer than janky query selectors because every element in your UI is strictly tied to your application's state and logic.

From the official documentation:

> There are three main building blocks to the Model-View-Update architecture:
> 
> A `Model` that represents your application’s state and an `init` function to create it.
> 
> A `Message` type that represents all the different ways the outside world can communicate with your application and an `update` function that modifies your `model` in response to those messages.
> 
> A view function that renders your `model` to HTML, represented as an `Element`.

However, real apps need Side Effects (like making HTTP requests). In Lustre, you handle these by returning an `Effect` from your `init` or `update` functions. These effects allow you to step outside the pure logic to perform a concurrent action and then send a message back into the application loop. I'll not go into detail here, so check out the [official documentation](https://lustre.hexdocs.pm/lustre.html) and [effects](https://lustre.hexdocs.pm/lustre/effect.html).

The biggest pain you'll face is that there isn't a trivial way to handle JavaScript Promises in Gleam. While the `gleam_javascript` library provides FFI for various JS types some concurrent stuff requires a way to bridge Gleam's types into JS ones.

We can solve this using `lustre.effect`. When you initialize your app with `lustre.application`, the `init` function returns a tuple: your initial `Model` and an `Effect`.

```gleam
fn asset_effect(name: String, path: String) -> effect.Effect(Message) {
  effect.from(fn(dispatch) {
    assets.load_asset(path)
      |> promise.map(fn(response) { AssetLoaded(name, response) })
      |> promise.tap(dispatch)

    Nil
  })
}

fn init(_) -> #(Model, effect.Effect(Message)) {
  #(
    Model(0, dict.new()),
    effect.batch([asset_effect("logo", "/src/assets/lucy.svg")]),
  )
}
```

We need to convert the result of our promise into a `Message` that Lustre's application loop understands then we need to use `promise.map` to transform that result into an `AssetLoaded` message and call `promise.tap`, which executes the dispatch once the promise resolves.

You might wonder why we return `Nil` at the end. Gleam has no `return` operator, so it returns last expression. In our case `promise.tap` returns our current Promise. But we don't care about it, so we just ignore result value and result `Nil`.

Now we have proper assers with lazy import using Vite, when it loads it will be avaliable once `AssetLoaded` arrives and we can store in Dictionary for example. Without it we would import all assets all at once, but it's not what you propably want.

# Conclusion

We've seen how moving away from the JS toward something more decent. Gleam supported by the powerhouse that is Vite, which can result in a much more sane development experience.

I've shared the source code for [my template here](https://codeberg.org/hendassa100k/vite_gleam_template). I didn't cover every single possible edge case in this article; instead, I focused on the hardest points I faced during development. For everything else, the documentation is excellent and the patterns are self-explanatory.

I spent a lot of time reading source code to reach the conclusions I shared today. I believe that's the best way to learn, and I've provided this template to make that journey a little easier for you. Now, go build something better.
